-- Migración 20261017_01_seleccion_mixta.sql
-- Sub-bloque 2R-8: Rines, llantas y matracas con selección mixta y cantidad (tope de piezas)
-- 1. grupos_configuracion: 'rines', 'llantas' y 'matracas' pasan a seleccion = 'multiple_con_cantidad'
-- 2. Define regla jsonb con max_total (por_eje o fija)
-- 3. Idempotente y con guardias de coherencia (RAISE EXCEPTION si un grupo no existe exactamente 1 vez por org)

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_count_rines int;
    v_count_llantas int;
    v_count_matracas int;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- Verificar que cada grupo exista exactamente una vez en la organización
        SELECT count(*) INTO v_count_rines 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'rines';

        SELECT count(*) INTO v_count_llantas 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'llantas';

        SELECT count(*) INTO v_count_matracas 
        FROM grupos_configuracion 
        WHERE organizacion_id = r_org.id AND clave = 'matracas';

        IF v_count_rines <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "rines" encontrado % veces (se esperaba 1)', r_org.id, v_count_rines;
        END IF;
        IF v_count_llantas <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "llantas" encontrado % veces (se esperaba 1)', r_org.id, v_count_llantas;
        END IF;
        IF v_count_matracas <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "matracas" encontrado % veces (se esperaba 1)', r_org.id, v_count_matracas;
        END IF;

        -- Actualizar grupo rines: seleccion multiple_con_cantidad, max_total por eje (4)
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('por_eje', 4)),
            cantidad = '4 por eje (8 en 2 ejes, 12 en 3 ejes)',
            notas = 'import-2r8'
        WHERE organizacion_id = r_org.id AND clave = 'rines';

        -- Actualizar grupo llantas: seleccion multiple_con_cantidad, max_total por eje (4)
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('por_eje', 4)),
            cantidad = '4 por eje (8 en 2 ejes, 12 en 3 ejes)',
            notas = 'import-2r8'
        WHERE organizacion_id = r_org.id AND clave = 'llantas';

        -- Actualizar grupo matracas: seleccion multiple_con_cantidad, max_total fija (12)
        UPDATE grupos_configuracion
        SET seleccion = 'multiple_con_cantidad',
            regla = jsonb_build_object('max_total', jsonb_build_object('fija', 12)),
            cantidad = 'Hasta 12 piezas fijas',
            unidad_precio = 'pieza',
            notas = 'import-2r8'
        WHERE organizacion_id = r_org.id AND clave = 'matracas';

    END LOOP;
END $$;

COMMIT;
