-- Prueba transaccional de T2: Fases, equivalencias y despiece
-- Se ejecuta dentro de un bloque BEGIN ... ROLLBACK

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_fase_id UUID;
    v_test_prod_id TEXT;
    v_receta_id UUID;
    v_count INT;
BEGIN
    SELECT id INTO v_org_id FROM organizaciones LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró organización de prueba';
    END IF;

    -- 1. Verificar existencia de las 14 fases
    SELECT count(*) INTO v_count FROM fases_despiece WHERE organizacion_id = v_org_id;
    IF v_count < 14 THEN
        RAISE EXCEPTION 'Fases esperadas >= 14, encontradas: %', v_count;
    END IF;

    -- 2. Verificar fases_despiece_equivalencias
    SELECT count(*) INTO v_count FROM fases_despiece_equivalencias WHERE organizacion_id = v_org_id;
    IF v_count < 20 THEN
        RAISE EXCEPTION 'Equivalencias esperadas >= 20, encontradas: %', v_count;
    END IF;

    -- 3. Probar asignación de fase a un nuevo componente en receta_base
    SELECT id INTO v_fase_id FROM fases_despiece WHERE organizacion_id = v_org_id AND clave = 'paso_1';
    SELECT id INTO v_test_prod_id FROM productos WHERE organizacion_id = v_org_id LIMIT 1;

    -- Debe permitir insertar con fase_id
    INSERT INTO receta_base (modelo_id, material_id, cantidad, paso, fase_id, notas)
    SELECT id, v_test_prod_id, 1, 'Paso 1', v_fase_id, 'test-t2'
    FROM modelos WHERE tipo = 'plataforma' LIMIT 1
    RETURNING id INTO v_receta_id;

    IF v_receta_id IS NULL THEN
        RAISE EXCEPTION 'Fallo al insertar receta_base de prueba con fase_id';
    END IF;

    -- 4. Probar consulta con JOIN entre receta_base y fases_despiece
    SELECT count(*) INTO v_count
    FROM receta_base rb
    JOIN fases_despiece fd ON rb.fase_id = fd.id
    WHERE rb.id = v_receta_id;

    IF v_count != 1 THEN
        RAISE EXCEPTION 'JOIN entre receta_base y fases_despiece no retornó 1';
    END IF;

    RAISE NOTICE 'Prueba transaccional T2 completada con éxito. Ejecutando ROLLBACK.';
END $$;

ROLLBACK;
