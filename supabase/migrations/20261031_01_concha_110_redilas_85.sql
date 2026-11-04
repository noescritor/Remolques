-- Migración 20261031_01_concha_110_redilas_85.sql
-- Dos opciones nuevas pedidas por el cliente para las plataformas (2026-10-30):
-- 1. Frente / Concha laminada: agrega la medida 1.10 m (precio provisional 5,891, el que el tarifario
--    ya traía para "concha" de 1.10 m)
-- 2. Redilas: agrega "Redilas de 85 cm" (precio provisional 36,500, mismo escalón de 500 que 75 -> 80 cm)
-- Ambos precios son PROVISIONALES: confirmar con el cliente.
-- Idempotente: si la medida/opción ya existe no la pisa (respeta lo que se haya editado a mano).
-- Guardias de coherencia: cada grupo/opción base debe existir exactamente 1 vez por organización.
-- La receta ya aplica: la regla de tornillos, chavetas y pintura es "redilas != sin_redilas".
-- Notas exactas: 'import-concha110-redilas85'

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_n int;
    v_grupo_frente uuid;
    v_grupo_redilas uuid;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- Guardias
        SELECT count(*) INTO v_n FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'frente';
        IF v_n <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "frente" encontrado % veces (se esperaba 1)', r_org.id, v_n;
        END IF;

        SELECT count(*) INTO v_n FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'redilas';
        IF v_n <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "redilas" encontrado % veces (se esperaba 1)', r_org.id, v_n;
        END IF;

        SELECT id INTO v_grupo_frente FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'frente';
        SELECT id INTO v_grupo_redilas FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'redilas';

        SELECT count(*) INTO v_n FROM opciones_configuracion
        WHERE grupo_id = v_grupo_frente AND clave = 'concha_laminada';
        IF v_n <> 1 THEN
            RAISE EXCEPTION 'Org %: opción frente/concha_laminada encontrada % veces (se esperaba 1)', r_org.id, v_n;
        END IF;

        -- 1. Concha laminada 1.10 m (si la medida ya existe, no se toca)
        UPDATE opciones_configuracion
        SET medidas = jsonb_build_object('1.10', 5891) || COALESCE(medidas, '{}'::jsonb),
            notas = CASE
                WHEN medidas ? '1.10' THEN notas
                ELSE trim(both ' ' from COALESCE(notas, '') || ' Medida 1.10 con precio provisional 5,891, confirmar con el cliente. import-concha110-redilas85')
            END
        WHERE grupo_id = v_grupo_frente AND clave = 'concha_laminada';

        -- 2. Redilas de 85 cm (si ya existe, no se toca)
        INSERT INTO opciones_configuracion
            (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas,
             precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
        VALUES
            (v_grupo_redilas, r_org.id, '85', 'Redilas de 85 cm', 36500, NULL, NULL,
             'Precio provisional 36,500 (mismo escalón de 500 que 75 -> 80 cm), confirmar con el cliente. import-concha110-redilas85',
             'PROVISIONAL', NULL, NULL, NULL, NULL, '{}'::jsonb)
        ON CONFLICT (grupo_id, clave) DO NOTHING;
    END LOOP;
END $$;

COMMIT;
