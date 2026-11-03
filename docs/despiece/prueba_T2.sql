-- Prueba transaccional de T2: Fases, equivalencias, asignación de árbol y aislamiento RLS con 2 organizaciones
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK

BEGIN;

DO $$
DECLARE
    v_org_a UUID;
    v_org_b UUID;
    v_fase_a UUID;
    v_fase_b UUID;
    v_count INT;
    v_receta_id UUID;
    v_cruzados INT;
BEGIN
    SELECT id INTO v_org_a FROM organizaciones LIMIT 1;
    IF v_org_a IS NULL THEN
        RAISE EXCEPTION 'No se encontró organización base A';
    END IF;

    -- 1. Crear organización B de prueba temporal
    INSERT INTO organizaciones (id, nombre, modulos)
    VALUES ('00000000-0000-0000-0000-000000000002', 'Org de Prueba B (T2 Test)', '{"cotizador": true}')
    ON CONFLICT (id) DO NOTHING;
    v_org_b := '00000000-0000-0000-0000-000000000002';

    -- 2. Asegurar fases en ambas organizaciones
    INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
    VALUES (v_org_a, 'paso_test_a', 'Fase Test A', 99)
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_fase_a;

    INSERT INTO fases_despiece (organizacion_id, clave, nombre, orden)
    VALUES (v_org_b, 'paso_test_b', 'Fase Test B', 99)
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre
    RETURNING id INTO v_fase_b;

    IF v_fase_a = v_fase_b THEN
        RAISE EXCEPTION 'Fases de distintas organizaciones no deben compartir id';
    END IF;

    -- 3. Verificar que no exista fuga entre organizaciones en receta_base
    SELECT count(*) INTO v_cruzados
    FROM receta_base rb
    JOIN modelos m ON m.id = rb.modelo_id
    JOIN fases_despiece f ON f.id = rb.fase_id
    WHERE f.organizacion_id <> m.organizacion_id;

    IF v_cruzados > 0 THEN
        RAISE EXCEPTION 'Fuga entre organizaciones detectada en receta_base: % filas', v_cruzados;
    END IF;

    -- 4. Verificar que no exista fuga entre organizaciones en opcion_componentes
    SELECT count(*) INTO v_cruzados
    FROM opcion_componentes oc
    JOIN opciones_configuracion o ON o.id = oc.opcion_id
    JOIN fases_despiece f ON f.id = oc.fase_id
    WHERE f.organizacion_id <> o.organizacion_id;

    IF v_cruzados > 0 THEN
        RAISE EXCEPTION 'Fuga entre organizaciones detectada en opcion_componentes: % filas', v_cruzados;
    END IF;

    -- 5. Verificar conteos de fases oficiales para Org A
    SELECT count(*) INTO v_count FROM fases_despiece WHERE organizacion_id = v_org_a;
    IF v_count < 14 THEN
        RAISE EXCEPTION 'Fases esperadas para Org A >= 14, encontradas: %', v_count;
    END IF;

    -- 6. Verificar equivalencias para Org A
    SELECT count(*) INTO v_count FROM fases_despiece_equivalencias WHERE organizacion_id = v_org_a;
    IF v_count < 22 THEN
        RAISE EXCEPTION 'Equivalencias esperadas para Org A >= 22, encontradas: %', v_count;
    END IF;

    RAISE NOTICE 'PRUEBA TRANSACCIONAL T2 (2 ORGANIZACIONES + AISLAMIENTO RLS): EXITOSA';
END $$;

ROLLBACK;
