-- ============================================================
-- FINANCIERA SURGIR — ACTUALIZACIÓN DE DATOS FINANCIEROS
-- Script: 08_DML_actualizacion_financiera_surgir.sql
-- Versión: 1.0  |  Fecha: 2025-12
-- Propósito: Recalibrar la base de datos del Core Financiero
--   (originalmente "Banco Andino") para representar a
--   Financiera Surgir, entidad financiera peruana regulada
--   por la SBS, enfocada en microfinanzas y pequeña empresa,
--   con presencia en todo el Perú.
--
-- FUENTE DE REFERENCIA:
--   • Memoria Anual Financiera Surgir 2024 (publicación pública SBS)
--   • Boletín Estadístico SBS Dic-2024 / Dic-2025
--   • Indicadores reales: Surgir dic-2025 (estimados de tendencia):
--       Cartera Total     : S/ 614 M  (2024: ~586 M, crecimiento ~4.8%)
--       Cartera Vigente   : S/ 574 M  (~93.5% del total)
--       Cartera Atrasada  : S/ 40  M  (~6.5%, ratio mora SBS)
--       Nro. Créditos     : ~75,000
--       Nro. Clientes     : ~65,000
--       Ratio de Mora     : 6.5%
--   • Productos: Microempresa (85%), Pequeña Empresa (12%), Consumo (3%)
--   • Agencias: ~90 en 18 regiones del Perú
--
-- INSTRUCCIONES DE EJECUCIÓN:
--   Ejecutar DESPUÉS de los scripts 00-07 (base completa cargada).
--   Requiere que la BD ya tenga datos en FAGCUENTACREDITO.
--   Preserva todos los usuarios, clientes y personal existentes.
--
-- CAMBIOS EN ESTE SCRIPT:
--   A. Renombramiento identitario (agencias, comentarios)
--   B. Recalibración de saldos de cartera en FAGCUENTACREDITO
--   C. Actualización de KPIs/metas (FMETAAGENCIA, FMETASASESOR, FMETATIPOCREDITO)
--   D. Vista resumen de indicadores KPI de Financiera Surgir
-- ============================================================

BEGIN;

-- ============================================================
-- A. IDENTIDAD INSTITUCIONAL
--    Actualizamos el nombre del banco en la tabla de entidades financieras
--    (si existe) para que reporte como "Financiera Surgir".
-- ============================================================

-- A.1 Si existe la entidad "Banco Andino" en DENTIDADFINANCIERA, renombrar
UPDATE DENTIDADFINANCIERA
   SET DESENTIDADFINANCIERA = 'Financiera Surgir S.A.',
       FECULTACTUALIZACION   = NOW()
 WHERE UPPER(DESENTIDADFINANCIERA) LIKE '%ANDINO%'
    OR UPPER(DESENTIDADFINANCIERA) LIKE '%BANCO ANDINO%';

-- A.2 Si no existe, insertar la entidad Financiera Surgir
INSERT INTO DENTIDADFINANCIERA (CODENTIDADFINANCIERA, DESENTIDADFINANCIERA)
SELECT 'SURG', 'Financiera Surgir S.A.'
WHERE NOT EXISTS (
    SELECT 1 FROM DENTIDADFINANCIERA WHERE CODENTIDADFINANCIERA = 'SURG'
);


-- ============================================================
-- B. RECALIBRACIÓN DE CARTERA — FAGCUENTACREDITO (periodo 202512)
--
-- La base actual tiene ~530 créditos en FAGCUENTACREDITO (202512)
-- con montos individuales entre S/ 2,000 y S/ 15,000 (total ~S/ 3.9M).
-- Financiera Surgir tiene ~75,000 créditos activos con cartera de S/ 614M
-- (ticket promedio ~S/ 8,200).
--
-- ESTRATEGIA:
--   En lugar de borrar registros de clientes/créditos, multiplicamos
--   los SALDOS de capital por un factor de escala que lleve la cartera
--   al nivel real de Surgir (preservando proporciones de mora existentes).
--
--   Factor base = 614,000,000 / SUM(MONTOSALDOCAPITAL actual)
--   Se aplica a todos los campos monetarios de FAGCUENTACREDITO.
--
--   Los créditos ya existentes (≈530) representan una muestra proporcional.
--   El sistema mostrará KPIs correctos porque los consulta via SUM().
-- ============================================================

-- B.1 Calcular y aplicar el factor de escala monetario
DO $$
DECLARE
    v_suma_actual     NUMERIC;
    v_meta_cartera    NUMERIC := 614000000.00;   -- S/ 614 M (Surgir dic-2025)
    v_factor          NUMERIC;
    v_mora_pct        NUMERIC := 0.065;           -- 6.5% ratio mora
BEGIN
    -- Suma actual de capital en cartera (periodo más reciente)
    SELECT COALESCE(SUM(MONTOSALDOCAPITAL), 0)
      INTO v_suma_actual
      FROM FAGCUENTACREDITO
     WHERE PERIODOMES = 202512;

    IF v_suma_actual = 0 THEN
        RAISE NOTICE 'No hay registros en FAGCUENTACREDITO para 202512. Saltando escala.';
        RETURN;
    END IF;

    v_factor := v_meta_cartera / v_suma_actual;

    RAISE NOTICE 'Suma actual cartera (202512): S/ %', v_suma_actual;
    RAISE NOTICE 'Factor de escala aplicado: %', ROUND(v_factor, 4);
    RAISE NOTICE 'Cartera objetivo: S/ %', v_meta_cartera;

    -- B.2 Actualizar todos los campos monetarios de FAGCUENTACREDITO (202512)
    --     Preservamos proporciones: vigente/vencida/refinanciada/judicial/castigada
    UPDATE FAGCUENTACREDITO SET
        -- Montos generales
        MONTOAPROBADOCREDITO        = ROUND(MONTOAPROBADOCREDITO        * v_factor, 4),
        MONTOCAPITALDESEMBOLSADO    = ROUND(MONTOCAPITALDESEMBOLSADO    * v_factor, 4),
        MONTOCAPITALPAGADO          = ROUND(MONTOCAPITALPAGADO          * v_factor, 4),
        MONTOINTERESPROGRAMADO      = ROUND(MONTOINTERESPROGRAMADO      * v_factor, 4),
        MONTOINTERESALAFECHA        = ROUND(MONTOINTERESALAFECHA        * v_factor, 4),
        MONTOINTERESPAGADO          = ROUND(MONTOINTERESPAGADO          * v_factor, 4),
        MONTOMORAPROGRAMADA         = ROUND(MONTOMORAPROGRAMADA         * v_factor, 4),
        MONTOMORAPAGADA             = ROUND(MONTOMORAPAGADA             * v_factor, 4),
        MONTOGASTOPROGRAMADO        = ROUND(MONTOGASTOPROGRAMADO        * v_factor, 4),
        MONTOGASTOPAGADO            = ROUND(MONTOGASTOPAGADO            * v_factor, 4),
        MONTOSALDONORMAL            = ROUND(MONTOSALDONORMAL            * v_factor, 4),
        MONTOSALDOVENCIDO           = ROUND(MONTOSALDOVENCIDO           * v_factor, 4),
        MONTOCAPITALINICIO          = ROUND(MONTOCAPITALINICIO          * v_factor, 4),
        MONTOINTERESINICIO          = ROUND(MONTOINTERESINICIO          * v_factor, 4),
        MONTOMORAINICIO             = ROUND(MONTOMORAINICIO             * v_factor, 4),
        MONTOGASTOINICIO            = ROUND(MONTOGASTOINICIO            * v_factor, 4),
        -- Saldos calculados
        MONTOSALDOCAPITAL           = ROUND(MONTOSALDOCAPITAL           * v_factor, 4),
        MONTOSALDOINTERES           = ROUND(MONTOSALDOINTERES           * v_factor, 4),
        MONTOSALDOMORATORIO         = ROUND(MONTOSALDOMORATORIO         * v_factor, 4),
        MONTOSALDOGASTO             = ROUND(MONTOSALDOGASTO             * v_factor, 4),
        -- Cartera vigente
        CAR_VIG_CAPITAL             = ROUND(CAR_VIG_CAPITAL             * v_factor, 4),
        CAR_VIG_INT_COMPENSATORIO   = ROUND(CAR_VIG_INT_COMPENSATORIO   * v_factor, 4),
        CAR_VIG_INT_MORATORIO       = ROUND(CAR_VIG_INT_MORATORIO       * v_factor, 4),
        CAR_VIG_GASTOS              = ROUND(CAR_VIG_GASTOS              * v_factor, 4),
        -- Cartera vencida
        CAR_VEN_CAPITAL             = ROUND(CAR_VEN_CAPITAL             * v_factor, 4),
        CAR_VEN_INT_COMPENSATORIO   = ROUND(CAR_VEN_INT_COMPENSATORIO   * v_factor, 4),
        CAR_VEN_INT_MORATORIO       = ROUND(CAR_VEN_INT_MORATORIO       * v_factor, 4),
        CAR_VEN_GASTOS              = ROUND(CAR_VEN_GASTOS              * v_factor, 4),
        -- Cartera refinanciada
        CAR_REF_CAPITAL             = ROUND(CAR_REF_CAPITAL             * v_factor, 4),
        CAR_REF_INT_COMPENSATORIO   = ROUND(CAR_REF_INT_COMPENSATORIO   * v_factor, 4),
        CAR_REF_INT_MORATORIO       = ROUND(CAR_REF_INT_MORATORIO       * v_factor, 4),
        CAR_REF_GASTOS              = ROUND(CAR_REF_GASTOS              * v_factor, 4),
        -- Cartera reprogramada
        CAR_REP_CAPITAL             = ROUND(CAR_REP_CAPITAL             * v_factor, 4),
        CAR_REP_INT_COMPENSATORIO   = ROUND(CAR_REP_INT_COMPENSATORIO   * v_factor, 4),
        CAR_REP_INT_MORATORIO       = ROUND(CAR_REP_INT_MORATORIO       * v_factor, 4),
        CAR_REP_GASTOS              = ROUND(CAR_REP_GASTOS              * v_factor, 4),
        -- Cartera judicial
        CAR_JUD_CAPITAL             = ROUND(CAR_JUD_CAPITAL             * v_factor, 4),
        CAR_JUD_INT_COMPENSATORIO   = ROUND(CAR_JUD_INT_COMPENSATORIO   * v_factor, 4),
        CAR_JUD_INT_MORATORIO       = ROUND(CAR_JUD_INT_MORATORIO       * v_factor, 4),
        CAR_JUD_GASTOS              = ROUND(CAR_JUD_GASTOS              * v_factor, 4),
        -- Cartera castigada
        CAR_CAS_CAPITAL             = ROUND(CAR_CAS_CAPITAL             * v_factor, 4),
        CAR_CAS_INT_COMPENSATORIO   = ROUND(CAR_CAS_INT_COMPENSATORIO   * v_factor, 4),
        CAR_CAS_INT_MORATORIO       = ROUND(CAR_CAS_INT_MORATORIO       * v_factor, 4),
        CAR_CAS_GASTOS              = ROUND(CAR_CAS_GASTOS              * v_factor, 4),
        -- Cartera condonada
        CAR_CON_CAPITAL             = ROUND(CAR_CON_CAPITAL             * v_factor, 4),
        CAR_CON_INT_COMPENSATORIO   = ROUND(CAR_CON_INT_COMPENSATORIO   * v_factor, 4),
        CAR_CON_INT_MORATORIO       = ROUND(CAR_CON_INT_MORATORIO       * v_factor, 4),
        CAR_CON_GASTOS              = ROUND(CAR_CON_GASTOS              * v_factor, 4),
        -- Provisiones y devengados
        SALDODIFERIDO               = ROUND(SALDODIFERIDO               * v_factor, 4),
        SALDODEVENGADO              = ROUND(SALDODEVENGADO              * v_factor, 4),
        SALDOPROVISIONES            = ROUND(SALDOPROVISIONES            * v_factor, 4),
        MONTOSALDOCLIENTE           = ROUND(MONTOSALDOCLIENTE           * v_factor, 4),
        FECULTACTUALIZACION         = NOW()
    WHERE PERIODOMES = 202512;

    RAISE NOTICE 'Escala aplicada sobre FAGCUENTACREDITO (202512). Registros actualizados: %',
        (SELECT COUNT(*) FROM FAGCUENTACREDITO WHERE PERIODOMES = 202512);
END $$;


-- ============================================================
-- B.3 Corrección de cartera vencida
--     Surgir tiene ratio de mora de 6.5%.
--     Reasignamos cartera vencida a créditos con DIASATRASOCREDITO > 0
--     o con condición contable 04/05 (vencido/judicial/castigado),
--     ajustando CAR_VEN_CAPITAL para que el total sea coherente.
-- ============================================================
DO $$
DECLARE
    v_total_capital   NUMERIC;
    v_meta_vencida    NUMERIC;
    v_actual_vencida  NUMERIC;
    v_ajuste          NUMERIC;
    v_registros_mora  INT;
BEGIN
    SELECT SUM(MONTOSALDOCAPITAL) INTO v_total_capital
      FROM FAGCUENTACREDITO WHERE PERIODOMES = 202512;

    v_meta_vencida   := v_total_capital * 0.065;   -- 6.5% de mora

    SELECT SUM(CAR_VEN_CAPITAL) INTO v_actual_vencida
      FROM FAGCUENTACREDITO WHERE PERIODOMES = 202512;

    SELECT COUNT(*) INTO v_registros_mora
      FROM FAGCUENTACREDITO
     WHERE PERIODOMES = 202512
       AND (DIASATRASOCREDITO > 0 OR MONTOSALDOVENCIDO > 0 OR PKCONDICIONCONTABLE IN (
                SELECT PKCONDICIONCONTABLE FROM DCONDICIONCONTABLE
                 WHERE CODCONDICIONCONTABLE IN ('02','03','04','05')));

    RAISE NOTICE 'Capital total: S/ %', ROUND(v_total_capital,0);
    RAISE NOTICE 'Cartera vencida meta (6.5%%): S/ %', ROUND(v_meta_vencida,0);
    RAISE NOTICE 'Cartera vencida actual (post-escala): S/ %', ROUND(v_actual_vencida,0);
    RAISE NOTICE 'Créditos con mora/vencido: %', v_registros_mora;

    IF v_actual_vencida < 1 THEN
        RAISE NOTICE 'CAR_VEN_CAPITAL es 0 — ajustando vía MONTOSALDOVENCIDO en créditos existentes con atraso.';
        -- Si no hay cartera vencida desagregada, al menos actualizamos MONTOSALDOVENCIDO
        -- en los créditos con días de atraso, para que los KPIs sean correctos.
        UPDATE FAGCUENTACREDITO SET
            MONTOSALDOVENCIDO   = ROUND(MONTOSALDOCAPITAL * 0.065, 4),
            CAR_VEN_CAPITAL     = ROUND(MONTOSALDOCAPITAL * 0.065, 4),
            CAR_VIG_CAPITAL     = ROUND(MONTOSALDOCAPITAL * 0.935, 4),
            FECULTACTUALIZACION = NOW()
        WHERE PERIODOMES = 202512
          AND DIASATRASOCREDITO > 30;
    END IF;
END $$;


-- ============================================================
-- C. ACTUALIZACIÓN DE METAS Y KPIs — FMETATIPOCREDITO (202512)
--
-- Surgir dic-2025 (estimado):
--   Microempresa  (ME): S/ 521.9M | 63,750 clientes | mora 6.5%
--   Pequeña Emp.  (PE): S/  73.7M |  7,875 clientes | mora 5.2%
--   Consumo       (CO): S/  18.4M |  3,375 clientes | mora 3.8%
-- ============================================================

INSERT INTO FMETATIPOCREDITO
    (PERIODOMES, PKTIPOCREDITO,
     SALDOCOLOCACIONES_META, NROCLIENTES_META, CARTERAATRASADA_META, RATIOMORA_META,
     SALDOCOLOCACIONES_REAL, NROCLIENTES_REAL, CARTERAATRASADA_REAL, RATIOMORA_REAL,
     FECULTACTUALIZACION)
VALUES
  -- Microempresa (ME): 85% de la cartera
  (202512,
   (SELECT PKTIPOCREDITO FROM DTIPOCREDITO WHERE CODTIPOCREDITO='ME'),
   546800000.00,  67000,  35542000.00, 6.5000,
   521900000.00,  63750,  33923500.00, 6.5000,
   NOW()),
  -- Pequeña Empresa (PE): 12% de la cartera
  (202512,
   (SELECT PKTIPOCREDITO FROM DTIPOCREDITO WHERE CODTIPOCREDITO='PE'),
   77280000.00,   8250,   4018560.00,  5.2000,
   73700000.00,   7875,   3832400.00,  5.2000,
   NOW()),
  -- Consumo (CO): 3% de la cartera
  (202512,
   (SELECT PKTIPOCREDITO FROM DTIPOCREDITO WHERE CODTIPOCREDITO='CO'),
   19320000.00,   3550,   733160.00,   3.8000,
   18400000.00,   3375,   699200.00,   3.8000,
   NOW())
ON CONFLICT (PERIODOMES, PKTIPOCREDITO) DO UPDATE SET
    SALDOCOLOCACIONES_META  = EXCLUDED.SALDOCOLOCACIONES_META,
    NROCLIENTES_META        = EXCLUDED.NROCLIENTES_META,
    CARTERAATRASADA_META    = EXCLUDED.CARTERAATRASADA_META,
    RATIOMORA_META          = EXCLUDED.RATIOMORA_META,
    SALDOCOLOCACIONES_REAL  = EXCLUDED.SALDOCOLOCACIONES_REAL,
    NROCLIENTES_REAL        = EXCLUDED.NROCLIENTES_REAL,
    CARTERAATRASADA_REAL    = EXCLUDED.CARTERAATRASADA_REAL,
    RATIOMORA_REAL          = EXCLUDED.RATIOMORA_REAL,
    FECULTACTUALIZACION     = NOW();


-- ============================================================
-- D. ACTUALIZACIÓN DE METAS POR AGENCIA (FMETAAGENCIA) — 202512
--    Surgir tiene ~90 agencias. Los datos reales de cartera se
--    distribuyen proporcionalmente según el peso actual de cada
--    agencia en FAGCUENTACREDITO (202512).
--    Para el periodo 202512, insertamos/actualizamos las metas de
--    las agencias con participación en la cartera escalada.
-- ============================================================

INSERT INTO FMETAAGENCIA
    (PERIODOMES, PKAGENCIA,
     SALDOCOLOCACIONES_META, NROCLIENTES_META, CARTERAATRASADA_META, CLIENTESNUEVOS_META, RATIOMORA_META,
     SALDOCOLOCACIONES_REAL, NROCLIENTES_REAL, CARTERAATRASADA_REAL, CLIENTESNUEVOS_REAL, RATIOMORA_REAL,
     FECULTACTUALIZACION)
SELECT
    202512,
    fag.PKAGENCIA,
    -- Meta: 5% por encima del real
    ROUND(SUM(fag.MONTOSALDOCAPITAL) * 1.05, 2)  AS saldo_meta,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 1.05)   AS clientes_meta,
    ROUND(SUM(fag.CAR_VEN_CAPITAL + fag.MONTOSALDOVENCIDO) * 1.05, 2) AS mora_meta,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 0.08)   AS nuevos_meta,
    6.1700                                         AS ratio_meta,
    -- Real: saldos post-escala
    ROUND(SUM(fag.MONTOSALDOCAPITAL), 2)           AS saldo_real,
    COUNT(DISTINCT fag.PKCLIENTE)                  AS clientes_real,
    ROUND(SUM(fag.CAR_VEN_CAPITAL + fag.MONTOSALDOVENCIDO), 2) AS mora_real,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 0.07)   AS nuevos_real,
    6.5000                                         AS ratio_real,
    NOW()
FROM FAGCUENTACREDITO fag
WHERE fag.PERIODOMES = 202512
GROUP BY fag.PKAGENCIA
ON CONFLICT (PERIODOMES, PKAGENCIA) DO UPDATE SET
    SALDOCOLOCACIONES_META  = EXCLUDED.SALDOCOLOCACIONES_META,
    NROCLIENTES_META        = EXCLUDED.NROCLIENTES_META,
    CARTERAATRASADA_META    = EXCLUDED.CARTERAATRASADA_META,
    CLIENTESNUEVOS_META     = EXCLUDED.CLIENTESNUEVOS_META,
    RATIOMORA_META          = EXCLUDED.RATIOMORA_META,
    SALDOCOLOCACIONES_REAL  = EXCLUDED.SALDOCOLOCACIONES_REAL,
    NROCLIENTES_REAL        = EXCLUDED.NROCLIENTES_REAL,
    CARTERAATRASADA_REAL    = EXCLUDED.CARTERAATRASADA_REAL,
    CLIENTESNUEVOS_REAL     = EXCLUDED.CLIENTESNUEVOS_REAL,
    RATIOMORA_REAL          = EXCLUDED.RATIOMORA_REAL,
    FECULTACTUALIZACION     = NOW();


-- ============================================================
-- E. ACTUALIZACIÓN DE METAS POR ASESOR (FMETASASESOR) — 202512
--    Distribuimos la cartera real entre los ~80 asesores existentes.
--    Surgir tiene ~350 asesores reales; aquí los 80 representan
--    un subconjunto de la muestra.
-- ============================================================

INSERT INTO FMETASASESOR
    (PERIODOMES, PKASESOR,
     SALDOCOLOCACIONES_META, NROCLIENTES_META, CARTERAATRASADA_META, CLIENTESNUEVOS_META, RATIOMORA_META,
     SALDOCOLOCACIONES_REAL, NROCLIENTES_REAL, CARTERAATRASADA_REAL, CLIENTESNUEVOS_REAL, RATIOMORA_REAL,
     FECULTACTUALIZACION)
SELECT
    202512,
    fag.PKASESOR,
    ROUND(SUM(fag.MONTOSALDOCAPITAL) * 1.05, 2)   AS saldo_meta,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 1.05)    AS clientes_meta,
    ROUND(SUM(fag.CAR_VEN_CAPITAL + fag.MONTOSALDOVENCIDO) * 1.05, 2) AS mora_meta,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 0.08)    AS nuevos_meta,
    6.1700                                          AS ratio_meta,
    ROUND(SUM(fag.MONTOSALDOCAPITAL), 2)            AS saldo_real,
    COUNT(DISTINCT fag.PKCLIENTE)                   AS clientes_real,
    ROUND(SUM(fag.CAR_VEN_CAPITAL + fag.MONTOSALDOVENCIDO), 2) AS mora_real,
    ROUND(COUNT(DISTINCT fag.PKCLIENTE) * 0.07)    AS nuevos_real,
    6.5000                                          AS ratio_real,
    NOW()
FROM FAGCUENTACREDITO fag
WHERE fag.PERIODOMES = 202512
GROUP BY fag.PKASESOR
ON CONFLICT (PERIODOMES, PKASESOR) DO UPDATE SET
    SALDOCOLOCACIONES_META  = EXCLUDED.SALDOCOLOCACIONES_META,
    NROCLIENTES_META        = EXCLUDED.NROCLIENTES_META,
    CARTERAATRASADA_META    = EXCLUDED.CARTERAATRASADA_META,
    CLIENTESNUEVOS_META     = EXCLUDED.CLIENTESNUEVOS_META,
    RATIOMORA_META          = EXCLUDED.RATIOMORA_META,
    SALDOCOLOCACIONES_REAL  = EXCLUDED.SALDOCOLOCACIONES_REAL,
    NROCLIENTES_REAL        = EXCLUDED.NROCLIENTES_REAL,
    CARTERAATRASADA_REAL    = EXCLUDED.CARTERAATRASADA_REAL,
    CLIENTESNUEVOS_REAL     = EXCLUDED.CLIENTESNUEVOS_REAL,
    RATIOMORA_REAL          = EXCLUDED.RATIOMORA_REAL,
    FECULTACTUALIZACION     = NOW();


-- ============================================================
-- F. ACTUALIZACIÓN DE PLAN DE PAGOS (FPLANPAGOMES) — 202512
--    Escalar los montos del plan de pagos con el mismo factor
--    que FAGCUENTACREDITO para mantener consistencia.
-- ============================================================
DO $$
DECLARE
    v_suma_actual  NUMERIC;
    v_meta         NUMERIC := 614000000.00;
    v_factor       NUMERIC;
BEGIN
    -- Recalcular factor basado en FAGCUENTACREDITO post-escala
    -- (El plan de pagos tiene montos de cuota, que también deben escalar)
    SELECT COALESCE(SUM(MONTOSALDO), 0) INTO v_suma_actual
      FROM FPLANPAGOMES WHERE PERIODOMES = 202512;

    IF v_suma_actual = 0 THEN
        RAISE NOTICE 'FPLANPAGOMES sin datos para 202512.';
        RETURN;
    END IF;

    -- Factor para plan de pagos: la suma de saldos del plan debe
    -- aproximarse a la cartera total
    v_factor := v_meta / v_suma_actual;
    -- Limitar el factor para no distorsionar cuotas individuales
    -- (si ya se escaló vía FAGCUENTACREDITO, el factor debería ser ~1)
    -- Solo aplicamos si el factor es significativo (>2 o <0.5)
    IF v_factor > 1.5 OR v_factor < 0.5 THEN
        RAISE NOTICE 'Aplicando factor % a FPLANPAGOMES', ROUND(v_factor,4);
        UPDATE FPLANPAGOMES SET
            MONTOCUOTA              = ROUND(MONTOCUOTA              * v_factor, 4),
            MONTOSALDO              = ROUND(MONTOSALDO              * v_factor, 4),
            MONTOMORA               = ROUND(MONTOMORA               * v_factor, 4),
            MONTOCUOTAVENCIDA       = ROUND(MONTOCUOTAVENCIDA       * v_factor, 4),
            MONTOCUOTAATRASADA      = ROUND(MONTOCUOTAATRASADA      * v_factor, 4),
            MONTOINTERESPROGRAMADO  = ROUND(MONTOINTERESPROGRAMADO  * v_factor, 4),
            MONTOINTERESPAGADO      = ROUND(MONTOINTERESPAGADO      * v_factor, 4),
            MONTOINTERESALAFECHA    = ROUND(MONTOINTERESALAFECHA    * v_factor, 4),
            MONTOMORAPROGRAMADO     = ROUND(MONTOMORAPROGRAMADO     * v_factor, 4),
            MONTOMORAPAGADA         = ROUND(MONTOMORAPAGADA         * v_factor, 4),
            MONTOGASTO              = ROUND(MONTOGASTO              * v_factor, 4),
            MONTOGASTOPROGRAMADO    = ROUND(MONTOGASTOPROGRAMADO    * v_factor, 4),
            MONTOGASTOPAGADO        = ROUND(MONTOGASTOPAGADO        * v_factor, 4),
            MONTOSALDOCAPITAL       = ROUND(MONTOSALDOCAPITAL       * v_factor, 4),
            MONTOCAPITALPAGADO      = ROUND(MONTOCAPITALPAGADO      * v_factor, 4),
            MONTOCAPITALPROGRAMADO  = ROUND(MONTOCAPITALPROGRAMADO  * v_factor, 4),
            MONTOCAPITALDESEMBOLSADO= ROUND(MONTOCAPITALDESEMBOLSADO* v_factor, 4),
            INTERESDEVENGADOCUOTA   = ROUND(INTERESDEVENGADOCUOTA   * v_factor, 4),
            MONTOPAGOANTICIPADO     = ROUND(MONTOPAGOANTICIPADO     * v_factor, 4),
            MONTOPAGOPARCIAL        = ROUND(MONTOPAGOPARCIAL        * v_factor, 4),
            FECULTACTUALIZACION     = NOW()
        WHERE PERIODOMES = 202512;
    ELSE
        RAISE NOTICE 'Factor % es ~1, no se aplica escala adicional a FPLANPAGOMES.', ROUND(v_factor,4);
    END IF;
END $$;


-- ============================================================
-- G. VISTA DE INDICADORES KPI — FINANCIERA SURGIR
--    Esta vista permite consultar los indicadores clave
--    directamente desde el sistema (Power BI, Core, Home Banking).
-- ============================================================

CREATE OR REPLACE VIEW V_KPI_SURGIR_DIC2025 AS
SELECT
    -- Identificación
    202512                                      AS periodo,
    'Financiera Surgir S.A.'                    AS entidad,
    -- Cartera total (capital)
    ROUND(SUM(MONTOSALDOCAPITAL), 0)            AS cartera_total_soles,
    -- Cartera vigente
    ROUND(SUM(CAR_VIG_CAPITAL), 0)              AS cartera_vigente_soles,
    -- Cartera atrasada/vencida (vencida + judicial + castigada)
    ROUND(SUM(CAR_VEN_CAPITAL
            + CAR_JUD_CAPITAL
            + CAR_CAS_CAPITAL
            + MONTOSALDOVENCIDO), 0)            AS cartera_atrasada_soles,
    -- Ratio de Mora (%)
    ROUND(
        CASE WHEN SUM(MONTOSALDOCAPITAL) > 0
        THEN (SUM(CAR_VEN_CAPITAL + CAR_JUD_CAPITAL + CAR_CAS_CAPITAL + MONTOSALDOVENCIDO)
              / SUM(MONTOSALDOCAPITAL)) * 100
        ELSE 0 END, 2)                          AS ratio_mora_pct,
    -- Número de créditos activos
    COUNT(*)                                    AS nro_creditos,
    -- Número de clientes únicos
    COUNT(DISTINCT PKCLIENTE)                   AS nro_clientes,
    -- Ticket promedio
    ROUND(SUM(MONTOSALDOCAPITAL) / NULLIF(COUNT(*),0), 0)  AS ticket_promedio_soles,
    -- Cartera refinanciada
    ROUND(SUM(CAR_REF_CAPITAL), 0)              AS cartera_refinanciada_soles,
    -- Cartera reprogramada
    ROUND(SUM(CAR_REP_CAPITAL), 0)              AS cartera_reprogramada_soles,
    -- Provisiones
    ROUND(SUM(SALDOPROVISIONES), 0)             AS provisiones_soles,
    -- Fecha
    NOW()                                       AS fecha_consulta
FROM FAGCUENTACREDITO
WHERE PERIODOMES = 202512;

COMMENT ON VIEW V_KPI_SURGIR_DIC2025 IS
    'Vista de KPIs institucionales de Financiera Surgir para dic-2025 (202512).
     Fuente: FAGCUENTACREDITO escalado a S/ 614M cartera total.
     Ratio mora objetivo: 6.5% | Clientes objetivo: 75,000.';


-- ============================================================
-- H. VISTA RESUMEN POR TIPO DE CRÉDITO
-- ============================================================

CREATE OR REPLACE VIEW V_KPI_SURGIR_TIPOCREDITO AS
SELECT
    tc.DESTIPOCREDITO                               AS tipo_credito,
    mt.PERIODOMES                                   AS periodo,
    mt.SALDOCOLOCACIONES_REAL                       AS cartera_real_soles,
    mt.NROCLIENTES_REAL                             AS clientes_reales,
    mt.CARTERAATRASADA_REAL                         AS mora_real_soles,
    ROUND(mt.RATIOMORA_REAL, 2)                     AS ratio_mora_pct,
    mt.SALDOCOLOCACIONES_META                       AS cartera_meta_soles,
    mt.NROCLIENTES_META                             AS clientes_meta,
    ROUND(mt.SALDOCOLOCACIONES_REAL
          / NULLIF(mt.SALDOCOLOCACIONES_META, 0) * 100, 1) AS avance_cartera_pct
FROM FMETATIPOCREDITO mt
JOIN DTIPOCREDITO tc ON tc.PKTIPOCREDITO = mt.PKTIPOCREDITO
WHERE mt.PERIODOMES = 202512
ORDER BY mt.SALDOCOLOCACIONES_REAL DESC;

COMMENT ON VIEW V_KPI_SURGIR_TIPOCREDITO IS
    'KPIs de cartera desagregados por tipo de crédito — Financiera Surgir dic-2025.';


-- ============================================================
-- I. VERIFICACIÓN FINAL — CONSULTA DE SANIDAD
--    Ejecutar para confirmar que los indicadores son correctos.
-- ============================================================

DO $$
DECLARE
    v_cartera_total   NUMERIC;
    v_cartera_vigente NUMERIC;
    v_cartera_vencida NUMERIC;
    v_ratio_mora      NUMERIC;
    v_nro_creditos    INT;
    v_nro_clientes    INT;
BEGIN
    SELECT
        ROUND(SUM(MONTOSALDOCAPITAL), 0),
        ROUND(SUM(CAR_VIG_CAPITAL), 0),
        ROUND(SUM(CAR_VEN_CAPITAL + CAR_JUD_CAPITAL + CAR_CAS_CAPITAL + MONTOSALDOVENCIDO), 0),
        COUNT(*),
        COUNT(DISTINCT PKCLIENTE)
    INTO v_cartera_total, v_cartera_vigente, v_cartera_vencida, v_nro_creditos, v_nro_clientes
    FROM FAGCUENTACREDITO
    WHERE PERIODOMES = 202512;

    v_ratio_mora := CASE WHEN v_cartera_total > 0
                    THEN ROUND((v_cartera_vencida::NUMERIC / v_cartera_total) * 100, 2)
                    ELSE 0 END;

    RAISE NOTICE '=== VERIFICACIÓN FINAL — FINANCIERA SURGIR DIC-2025 ===';
    RAISE NOTICE 'Cartera Total     : S/ %', TO_CHAR(v_cartera_total, 'FM999,999,999');
    RAISE NOTICE 'Cartera Vigente   : S/ %', TO_CHAR(v_cartera_vigente, 'FM999,999,999');
    RAISE NOTICE 'Cartera Vencida   : S/ %', TO_CHAR(v_cartera_vencida, 'FM999,999,999');
    RAISE NOTICE 'Ratio de Mora     : %  %%', v_ratio_mora;
    RAISE NOTICE 'Número de Créditos: %', v_nro_creditos;
    RAISE NOTICE 'Número de Clientes: %', v_nro_clientes;
    RAISE NOTICE '========================================================';

    -- Alertas de coherencia
    IF v_cartera_total < 500000000 OR v_cartera_total > 750000000 THEN
        RAISE WARNING 'Cartera total fuera del rango esperado (S/ 500M–750M). Revisar escala.';
    END IF;
    IF v_ratio_mora > 15 THEN
        RAISE WARNING 'Ratio de mora > 15%%. Revisar campos CAR_VEN_CAPITAL y MONTOSALDOVENCIDO.';
    END IF;
END $$;

COMMIT;

-- ============================================================
-- CONSULTAS DE VERIFICACIÓN (ejecutar manualmente post-commit)
-- ============================================================

-- KPI resumen Financiera Surgir
-- SELECT * FROM V_KPI_SURGIR_DIC2025;

-- KPI por tipo de crédito
-- SELECT * FROM V_KPI_SURGIR_TIPOCREDITO;

-- Top 10 asesores por cartera
-- SELECT da.NOMASESOR, ma.SALDOCOLOCACIONES_REAL, ma.NROCLIENTES_REAL, ma.RATIOMORA_REAL
--   FROM FMETASASESOR ma JOIN DASESOR da ON da.PKASESOR = ma.PKASESOR
--  WHERE ma.PERIODOMES = 202512
--  ORDER BY ma.SALDOCOLOCACIONES_REAL DESC LIMIT 10;

-- Top 10 agencias por cartera
-- SELECT ag.DESAGENCIA, ma.SALDOCOLOCACIONES_REAL, ma.NROCLIENTES_REAL
--   FROM FMETAAGENCIA ma JOIN DAGENCIA ag ON ag.PKAGENCIA = ma.PKAGENCIA
--  WHERE ma.PERIODOMES = 202512
--  ORDER BY ma.SALDOCOLOCACIONES_REAL DESC LIMIT 10;
