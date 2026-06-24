"""
Repositorio de evaluacion y desembolso de solicitudes - MPR-003-CRE.

- registrar_ingreso: fuente de ingreso del cliente.
- registrar_evaluacion: cabecera + detalle de evaluacion.
- desembolsar: crea la cuenta de credito, registra el movimiento y abona la
  cuenta de ahorro del cliente cuando existe.
"""
from datetime import datetime

from sqlalchemy import text
from sqlalchemy.orm import Session

PERIODO = 202512


def _cuenta_ahorro_desembolso(db: Session, pkcliente: int):
    """Cuenta de ahorro principal del cliente para depositar el desembolso."""
    return db.execute(text("""
        SELECT a.pkcuentaahorro, a.codcuentaahorro, f.periododia,
               f.pkproductoahorro, f.pkmoneda, f.pkagencia, f.flag_ac
        FROM dcuentaahorro a
        JOIN fcuentaahorro f
          ON f.pkcuentaahorro = a.pkcuentaahorro
         AND f.periododia = (
               SELECT MAX(f2.periododia)
               FROM fcuentaahorro f2
               WHERE f2.pkcuentaahorro = a.pkcuentaahorro
         )
        LEFT JOIN destadocuenta ec ON ec.pkestadocuenta = f.pkestadocuenta
        LEFT JOIN dtipocuentaahorro tca ON tca.pktipocuentaahorro = f.pktipocuentaahorro
        WHERE a.pkcliente = :pkcli
        ORDER BY
          CASE WHEN COALESCE(TRIM(ec.desestadocuenta), '') ILIKE 'Act%' THEN 0 ELSE 1 END,
          CASE WHEN TRIM(tca.codtipocuentaahorro) = 'AC' OR f.flag_ac = 'S' THEN 0 ELSE 1 END,
          f.montosaldocapitaltotal DESC
        LIMIT 1
    """), {"pkcli": pkcliente}).fetchone()


def registrar_ingreso(db: Session, pkcliente: int, *, tipo: str, monto: float,
                      nombre_empresa: str = None) -> dict:
    db.execute(text("""
        INSERT INTO fclientefuenteingreso
            (pkcliente, periodomes, tipofuenteingreso, montofuenteingreso,
             codrelacion, nombreempresa, fecultactualizacion)
        VALUES (:pk, :per, :tipo, :monto, 'T', :emp, NOW())
        ON CONFLICT (pkcliente, periodomes) DO UPDATE
            SET tipofuenteingreso = EXCLUDED.tipofuenteingreso,
                montofuenteingreso = EXCLUDED.montofuenteingreso,
                nombreempresa = EXCLUDED.nombreempresa,
                fecultactualizacion = NOW()
    """), {"pk": pkcliente, "per": PERIODO, "tipo": tipo[:2],
           "monto": monto, "emp": nombre_empresa})
    db.commit()
    return {"pkcliente": pkcliente, "tipo": tipo, "monto": monto}


def registrar_evaluacion(db: Session, codsolicitud: str, *, es_microempresa: bool,
                         ingreso: float, gasto_familiar: float,
                         monto_solicitud: float = 0.0,
                         fortaleza: str = "", debilidad: str = "") -> dict:
    """Crea la evaluacion de la solicitud si aun no existe."""
    ya = db.execute(
        text("SELECT pkevaluacion FROM devaluacion WHERE codsolicitud=:c"),
        {"c": codsolicitud},
    ).scalar()
    if ya:
        return {"codsolicitud": codsolicitud, "pkevaluacion": ya, "creada": False}

    excedente = round(ingreso - gasto_familiar, 2)
    row = db.execute(text("""
        INSERT INTO devaluacion
            (nroevaluacion, valorexcedentecredito, tipoevaluacion, codsolicitud, fecultactualizacion)
        VALUES ('EV-' || :c, :exc, :tipo, :c, NOW())
        RETURNING pkevaluacion
    """), {"c": codsolicitud, "exc": excedente,
           "tipo": "ME" if es_microempresa else "CO"}).fetchone()
    pkeval = row.pkevaluacion

    if es_microempresa:
        db.execute(text("""
            INSERT INTO fevalmicroactivo
                (pkevaluacion, nroreg, montoactivodisponible, montoactivoinventario,
                 montoactivofijo, montogastofamiliar, fecultactualizacion)
            VALUES (:pk, 1, :disp, :inv, :fijo, :gf, NOW())
        """), {"pk": pkeval, "disp": round(monto_solicitud * 0.20, 2),
               "inv": round(monto_solicitud * 0.50, 2),
               "fijo": round(monto_solicitud * 0.80, 2),
               "gf": gasto_familiar})
    else:
        db.execute(text("""
            INSERT INTO fevalconsumo
                (pkevaluacion, monto, montogastofamiliar, codtipoingreso,
                 fortalezaevaluacion, debilidadevaluacion, fecultactualizacion)
            VALUES (:pk, :monto, :gf, 'D', :fz, :db, NOW())
        """), {"pk": pkeval, "monto": ingreso, "gf": gasto_familiar,
               "fz": fortaleza or "Ingreso estable",
               "db": debilidad or "Sin garantia real"})
    db.commit()
    return {"codsolicitud": codsolicitud, "pkevaluacion": pkeval,
            "excedente": excedente, "creada": True}


def desembolsar(db: Session, sol) -> dict:
    """
    Crea la cuenta de credito, registra el desembolso y abona el monto a una
    cuenta de ahorro del cliente cuando existe.
    """
    monto = float(sol.montoaprobadocredito or sol.montosolicitudcredito or 0)

    cc = db.execute(text("""
        INSERT INTO dcuentacredito (pkcuentacredito, codcuentacredito, pkcliente, nrocronograma, fecultactualizacion)
        VALUES (nextval('dcuentacredito_pkcuentacredito_seq'),
                'CRD' || LPAD(currval('dcuentacredito_pkcuentacredito_seq')::text, 7, '0'),
                :pkcli, 1, NOW())
        RETURNING pkcuentacredito, codcuentacredito
    """), {"pkcli": sol.pkcliente}).fetchone()

    cuenta_ahorro = _cuenta_ahorro_desembolso(db, sol.pkcliente)

    cat = db.execute(text("""
        SELECT (SELECT pkconceptooperacion FROM dconceptooperacion WHERE codconceptooperacion='DCAP') con,
               (SELECT pktipooperacion FROM dtipooperacion WHERE codtipooperacion='CRE') tipo,
               (SELECT pkmediopago FROM dmediopago WHERE codmediopago='WEB') medio,
               (SELECT pkcanaltransaccional FROM dcanaltransaccional WHERE codcanaltransaccional='WEB') canal,
               (SELECT pkcondicioncontable FROM dcondicioncontable WHERE codcondicioncontable='01') cond,
               (SELECT pkmoneda FROM dmoneda ORDER BY pkmoneda LIMIT 1) mon,
               (SELECT MIN(pkproducto) FROM dproducto) prod,
               (SELECT MIN(pkagencia) FROM dagencia) ag
    """)).fetchone()

    hoy = datetime.utcnow()
    pd_hoy = int(hoy.strftime("%Y%m%d"))
    pd = db.execute(text("""
        SELECT COALESCE(
            (SELECT MAX(periododia) FROM dtiempo WHERE periododia <= :pd_hoy),
            (SELECT MAX(periododia) FROM dtiempo)
        )
    """), {"pd_hoy": pd_hoy}).scalar() or pd_hoy
    db.execute(text("""
        INSERT INTO foperaciones
            (codtipkar, codkardex, pkcuentacredito, pkcuentaahorro,
             pkconceptooperacion, pktipooperacion,
             pkmediopago, pkcanaltransaccional, pkmoneda, pkcondicioncontable, pkproducto,
             pkproductoahorro,
             pkagenciaorigen, montooperacion, montopagoconcepto, codtipoegresoingreso,
             fechahoraoperacion, periododia, codusuope, fecultactualizacion)
        VALUES ('CR', 'DESEMB-' || :pkcc, :pkcc, :pkca,
                :con, :tipo, :medio, :canal, :mon, :cond, :prod,
                :prod_ahorro,
                :ag, :monto, :monto, 'I', :fh, :pd, 'CORE', NOW())
    """), {"pkcc": cc.pkcuentacredito, "con": cat.con, "tipo": cat.tipo,
           "medio": cat.medio, "canal": cat.canal, "mon": cat.mon,
           "cond": cat.cond, "prod": cat.prod,
           "prod_ahorro": cuenta_ahorro.pkproductoahorro if cuenta_ahorro else None,
           "pkca": cuenta_ahorro.pkcuentaahorro if cuenta_ahorro else None,
           "ag": cuenta_ahorro.pkagencia if cuenta_ahorro else cat.ag,
           "monto": monto, "fh": hoy, "pd": pd})

    if cuenta_ahorro:
        db.execute(text("""
            UPDATE fcuentaahorro
            SET montosaldocapitaltotal = COALESCE(montosaldocapitaltotal, 0) + :monto,
                montosaldodisponible_ac = CASE
                    WHEN flag_ac = 'S' THEN COALESCE(montosaldodisponible_ac, 0) + :monto
                    ELSE montosaldodisponible_ac
                END,
                montosaldocontable_ac = CASE
                    WHEN flag_ac = 'S' THEN COALESCE(montosaldocontable_ac, 0) + :monto
                    ELSE montosaldocontable_ac
                END,
                fecultactualizacion = NOW()
            WHERE pkcuentaahorro = :pkca AND periododia = :periododia
        """), {"pkca": cuenta_ahorro.pkcuentaahorro,
               "periododia": cuenta_ahorro.periododia,
               "monto": monto})

    db.commit()
    return {"codcuentacredito": cc.codcuentacredito,
            "monto_desembolsado": monto,
            "codcuentaahorro": cuenta_ahorro.codcuentaahorro if cuenta_ahorro else None,
            "fecha": hoy.date().isoformat()}
