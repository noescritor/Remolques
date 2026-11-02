-- Carga inicial de CADECO S.A. de C.V. — estado de cuenta del proveedor al 29/10/2026
-- Cuentas por pagar (2R-16). Idempotente: se puede correr más de una vez.
--
-- Qué carga:
--   * Ficha de crédito del proveedor CADECO (límite US$ 10,000, 30 días, moneda USD).
--   * 13 facturas en dólares y 3 en pesos (sucursal 114), con el SALDO del estado de cuenta.
--     Donde el estado de cuenta ya trae un abono (21644 y 21778) se carga el saldo vigente
--     y el importe original queda en el concepto; no se inventan fechas ni tipo de cambio de pagos.
--   * Tipo de cambio de referencia 19.07 al 29/10/2026 (editable en la pantalla; pendiente de confirmar con el cliente).
-- Totales esperados: US$ 9,406.71 / $25,222.99 / $204,608.95 equivalente a 19.07.

DO $$
DECLARE
    v_org UUID;
    v_prov UUID;
    v_n_orgs INT;
    r RECORD;
BEGIN
    -- 1. Organización: la del proveedor CADECO si ya existe; si no, la única organización
    SELECT organizacion_id, id INTO v_org, v_prov
    FROM proveedores
    WHERE nombre ILIKE '%cadeco%'
    ORDER BY created_at
    LIMIT 1;

    IF v_org IS NULL THEN
        SELECT count(*) INTO v_n_orgs FROM organizaciones;
        IF v_n_orgs <> 1 THEN
            RAISE EXCEPTION 'No hay proveedor CADECO y existen % organizaciones: no se sabe en cuál cargar', v_n_orgs;
        END IF;
        SELECT id INTO v_org FROM organizaciones LIMIT 1;
    END IF;

    -- 2. Proveedor y ficha de crédito
    IF v_prov IS NULL THEN
        INSERT INTO proveedores (organizacion_id, nombre) VALUES (v_org, 'CADECO')
        RETURNING id INTO v_prov;
    END IF;

    UPDATE proveedores SET
        razon_social          = COALESCE(razon_social, 'CADECO S.A. DE C.V.'),
        rfc                   = COALESCE(rfc, 'CAD850514L17'),
        moneda_default        = 'USD',
        dias_credito          = COALESCE(dias_credito, 30),
        limite_credito        = COALESCE(limite_credito, 10000),
        limite_credito_moneda = COALESCE(limite_credito_moneda, 'USD')
    WHERE id = v_prov;

    -- 3. Facturas (folio, emisión, vencimiento, moneda, saldo vigente, concepto)
    FOR r IN
        SELECT * FROM (VALUES
            ('21644', DATE '2026-06-03', DATE '2026-07-03', 'USD',  288.19, 'Importe original US$ 2,354.80; saldo al 29/10/2026 según estado de cuenta'),
            ('21667', DATE '2026-06-05', DATE '2026-07-05', 'USD',  526.71, NULL),
            ('21754', DATE '2026-06-17', DATE '2026-07-17', 'USD', 2354.80, NULL),
            ('21788', DATE '2026-06-19', DATE '2026-07-19', 'USD',  265.08, NULL),
            ('21815', DATE '2026-06-23', DATE '2026-07-23', 'USD',  711.90, NULL),
            ('21839', DATE '2026-06-26', DATE '2026-07-26', 'USD',  364.56, NULL),
            ('21882', DATE '2026-06-30', DATE '2026-07-30', 'USD',  141.84, NULL),
            ('21899', DATE '2026-07-01', DATE '2026-07-31', 'USD', 2354.80, NULL),
            ('21910', DATE '2026-07-02', DATE '2026-08-01', 'USD',  134.61, NULL),
            ('21918', DATE '2026-07-03', DATE '2026-08-02', 'USD',  638.32, NULL),
            ('21959', DATE '2026-07-07', DATE '2026-08-06', 'USD',  384.86, NULL),
            ('22034', DATE '2026-07-14', DATE '2026-08-13', 'USD',  139.04, NULL),
            ('22048', DATE '2026-07-16', DATE '2026-08-15', 'USD', 1102.00, NULL),
            ('21778', DATE '2026-06-19', DATE '2026-07-19', 'MXN', 17847.85, 'Importe original $18,008.07; saldo al 29/10/2026 según estado de cuenta'),
            ('21912', DATE '2026-07-02', DATE '2026-08-01', 'MXN', 1439.93, NULL),
            ('21919', DATE '2026-07-03', DATE '2026-08-02', 'MXN', 5935.21, NULL)
        ) AS t(folio, emision, vence, moneda, saldo, concepto)
    LOOP
        INSERT INTO facturas_proveedor
            (organizacion_id, proveedor_id, sucursal, folio, fecha_emision, dias_credito,
             fecha_vencimiento, moneda, importe, concepto)
        SELECT v_org, v_prov, '114', r.folio, r.emision, 30, r.vence, r.moneda, r.saldo,
               COALESCE(r.concepto, 'Carga inicial del estado de cuenta CADECO al 29/10/2026')
        WHERE NOT EXISTS (
            SELECT 1 FROM facturas_proveedor f
            WHERE f.organizacion_id = v_org AND f.proveedor_id = v_prov
              AND COALESCE(f.sucursal, '') = '114' AND f.folio = r.folio
        );
    END LOOP;

    -- 4. Tipo de cambio de referencia
    INSERT INTO tipos_cambio (organizacion_id, fecha, moneda, valor, fuente, notas)
    VALUES (v_org, DATE '2026-10-29', 'USD', 19.07, 'manual',
            'Referencia usada en la carga de CADECO; confirmar fuente con el cliente')
    ON CONFLICT (organizacion_id, fecha, moneda) DO NOTHING;
END $$;

-- Verificación: debe dar 13 / 9406.71 / 3 / 25222.99 / 179385.96 / 204608.95
SELECT
    count(*) FILTER (WHERE f.moneda = 'USD')                                         AS facturas_usd,
    COALESCE(sum(f.saldo) FILTER (WHERE f.moneda = 'USD'), 0)                        AS saldo_usd,
    count(*) FILTER (WHERE f.moneda = 'MXN')                                         AS facturas_mxn,
    COALESCE(sum(f.saldo) FILTER (WHERE f.moneda = 'MXN'), 0)                        AS saldo_mxn,
    round(COALESCE(sum(f.saldo) FILTER (WHERE f.moneda = 'USD'), 0) * 19.07, 2)      AS usd_en_pesos,
    round(COALESCE(sum(f.saldo) FILTER (WHERE f.moneda = 'USD'), 0) * 19.07, 2)
      + COALESCE(sum(f.saldo) FILTER (WHERE f.moneda = 'MXN'), 0)                    AS total_en_pesos
FROM v_facturas_proveedor_saldo f
JOIN proveedores p ON p.id = f.proveedor_id
WHERE p.nombre ILIKE '%cadeco%' AND f.estado <> 'cancelada';
