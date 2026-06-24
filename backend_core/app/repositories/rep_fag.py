from sqlalchemy.orm import Session
from sqlalchemy import text

def get_kpis_periodo(db: Session, periodomes: int = 202512):
    sql = text("""
        SELECT
            COUNT(DISTINCT cc.pkcliente)            AS n_clientes,
            COUNT(f.pkcuentacredito)                AS n_creditos,
            SUM(f.montosaldocapital)                AS cartera_total,
            SUM(
                CASE
                    WHEN f.car_vig_capital + f.car_ven_capital > 0 THEN f.car_vig_capital
                    WHEN f.diasatrasocredito <= 0 THEN f.montosaldocapital
                    ELSE 0
                END
            )                                       AS cartera_vigente,
            SUM(
                CASE
                    WHEN f.car_vig_capital + f.car_ven_capital > 0 THEN f.car_ven_capital
                    WHEN f.diasatrasocredito > 0 THEN f.montosaldocapital
                    ELSE 0
                END
            )                                       AS cartera_vencida,
            ROUND(
                SUM(
                    CASE
                        WHEN f.car_vig_capital + f.car_ven_capital > 0 THEN f.car_ven_capital
                        WHEN f.diasatrasocredito > 0 THEN f.montosaldocapital
                        ELSE 0
                    END
                ) /
                NULLIF(SUM(f.montosaldocapital),0) * 100, 4
            )                                       AS ratio_mora
        FROM fagcuentacredito f
        JOIN dcuentacredito cc ON cc.pkcuentacredito = f.pkcuentacredito
        WHERE f.periodomes = :periodomes
    """)
    return db.execute(sql, {"periodomes": periodomes}).fetchone()
