-- Script de prueba funcional para Sub-bloque 2R-14: Actualización masiva y reversión
-- Ejecuta un ciclo completo de:
-- 1. Selección de un registro real de cada una de las 4 fuentes (productos, opcion_costos, costos_modelo, acero_precios)
-- 2. Llamada a aplicar_lote_precios con las 4 fuentes simultáneas
-- 3. Verificación de que los precios se actualizaron en BD y se registraron lote e historiales
-- 4. Llamada a revertir_lote_precios
-- 5. Verificación de que los precios originales fueron restaurados al 100%
-- 6. ROLLBACK al final: el script no deja ningún cambio en la base de datos

BEGIN;

DO $$
DECLARE
    v_org_id UUID;
    v_user_id UUID;

    -- Registros originales
    v_prod_id TEXT;
    v_prod_costo_orig NUMERIC;
    v_prod_costo_act NUMERIC;
    v_prod_costo_nuevo NUMERIC;

    v_oc_id UUID;
    v_oc_costo_orig NUMERIC;
    v_oc_costo_act NUMERIC;
    v_oc_costo_nuevo NUMERIC;

    v_cm_id UUID;
    v_cm_costo_orig NUMERIC;
    v_cm_costo_act NUMERIC;
    v_cm_costo_nuevo NUMERIC;

    v_ap_id UUID;
    v_ap_costo_orig NUMERIC;
    v_ap_costo_act NUMERIC;
    v_ap_costo_nuevo NUMERIC;

    -- Payloads y resultados
    v_cambios JSONB;
    v_res_aplicar JSONB;
    v_lote_id UUID;
    v_res_revertir JSONB;
    v_nuevo_lote_id UUID;

    v_items_count INT;
BEGIN
    -- 1. Obtener organización
    SELECT id INTO v_org_id FROM organizaciones ORDER BY id LIMIT 1;
    IF v_org_id IS NULL THEN
        RAISE EXCEPTION 'No se encontró ninguna organización en la base de datos';
    END IF;

    -- Obtener un usuario de la organización (o NULL si no hay)
    SELECT usuario_id INTO v_user_id FROM perfiles_organizacion WHERE organizacion_id = v_org_id LIMIT 1;

    -- 2. Seleccionar 1 registro real de cada una de las 4 fuentes
    -- 2.1 productos
    SELECT id, costo INTO v_prod_id, v_prod_costo_orig
    FROM productos
    WHERE organizacion_id = v_org_id AND costo IS NOT NULL AND costo > 0
    ORDER BY id LIMIT 1;
    IF v_prod_id IS NULL THEN
        RAISE EXCEPTION 'Org %: No se encontró ningún producto con costo > 0', v_org_id;
    END IF;

    -- 2.2 opcion_costos
    SELECT oc.id, oc.costo_unitario INTO v_oc_id, v_oc_costo_orig
    FROM opcion_costos oc
    WHERE oc.organizacion_id = v_org_id AND oc.costo_unitario IS NOT NULL AND oc.costo_unitario > 0
    ORDER BY oc.id LIMIT 1;
    IF v_oc_id IS NULL THEN
        RAISE EXCEPTION 'Org %: No se encontró ningún opcion_costos con costo > 0', v_org_id;
    END IF;

    -- 2.3 costos_modelo (con join a modelos y productos para validar integridad)
    SELECT cm.id, cm.costo_unitario INTO v_cm_id, v_cm_costo_orig
    FROM costos_modelo cm
    JOIN modelos m ON m.id = cm.modelo_id
    JOIN productos pm ON pm.id = m.producto_id
    WHERE cm.organizacion_id = v_org_id AND cm.costo_unitario IS NOT NULL AND cm.costo_unitario > 0
    ORDER BY cm.id LIMIT 1;
    IF v_cm_id IS NULL THEN
        RAISE EXCEPTION 'Org %: No se encontró ningún costos_modelo con costo > 0 ligado a modelos/productos', v_org_id;
    END IF;

    -- 2.4 acero_precios
    SELECT ap.id, ap.precio INTO v_ap_id, v_ap_costo_orig
    FROM acero_precios ap
    JOIN acero_materiales am ON am.id = ap.material_id
    WHERE ap.organizacion_id = v_org_id AND ap.precio IS NOT NULL AND ap.precio > 0
    ORDER BY ap.id LIMIT 1;
    IF v_ap_id IS NULL THEN
        RAISE EXCEPTION 'Org %: No se encontró ningún acero_precios con precio > 0', v_org_id;
    END IF;

    RAISE NOTICE 'Registros base seleccionados:';
    RAISE NOTICE '  - producto: % (costo original: %)', v_prod_id, v_prod_costo_orig;
    RAISE NOTICE '  - opcion_costos: % (costo original: %)', v_oc_id, v_oc_costo_orig;
    RAISE NOTICE '  - costos_modelo: % (costo original: %)', v_cm_id, v_cm_costo_orig;
    RAISE NOTICE '  - acero_precios: % (precio original: %)', v_ap_id, v_ap_costo_orig;

    -- 3. Definir nuevos precios de prueba
    v_prod_costo_nuevo := v_prod_costo_orig + 100;
    v_oc_costo_nuevo := v_oc_costo_orig + 250;
    v_cm_costo_nuevo := v_cm_costo_orig + 500;
    v_ap_costo_nuevo := v_ap_costo_orig + 750;

    v_cambios := jsonb_build_array(
        jsonb_build_object(
            'fuente', 'productos',
            'id', v_prod_id,
            'precio_nuevo', v_prod_costo_nuevo,
            'precio_anterior_visto', v_prod_costo_orig
        ),
        jsonb_build_object(
            'fuente', 'opcion_costos',
            'id', v_oc_id::text,
            'precio_nuevo', v_oc_costo_nuevo,
            'precio_anterior_visto', v_oc_costo_orig
        ),
        jsonb_build_object(
            'fuente', 'costos_modelo',
            'id', v_cm_id::text,
            'precio_nuevo', v_cm_costo_nuevo,
            'precio_anterior_visto', v_cm_costo_orig
        ),
        jsonb_build_object(
            'fuente', 'acero_precios',
            'id', v_ap_id::text,
            'precio_nuevo', v_ap_costo_nuevo,
            'precio_anterior_visto', v_ap_costo_orig
        )
    );

    -- 4. Llamar aplicar_lote_precios
    v_res_aplicar := aplicar_lote_precios(
        v_org_id,
        v_user_id,
        'manual',
        'Prueba 2R-14: Actualización simultánea 4 fuentes',
        v_cambios
    );

    RAISE NOTICE 'Resultado aplicar_lote_precios: %', v_res_aplicar;

    IF (v_res_aplicar->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'aplicar_lote_precios no tuvo éxito: %', v_res_aplicar;
    END IF;

    IF (v_res_aplicar->>'aplicados')::int <> 4 THEN
        RAISE EXCEPTION 'Se esperaban 4 cambios aplicados, pero se aplicaron: %', v_res_aplicar->>'aplicados';
    END IF;

    v_lote_id := (v_res_aplicar->>'lote_id')::uuid;

    -- 5. Verificar que los precios cambiaron en las tablas reales
    SELECT costo INTO v_prod_costo_act FROM productos WHERE id = v_prod_id;
    IF abs(v_prod_costo_act - v_prod_costo_nuevo) > 0.0001 THEN
        RAISE EXCEPTION 'productos.costo no coincide: esperado %, actual %', v_prod_costo_nuevo, v_prod_costo_act;
    END IF;

    SELECT costo_unitario INTO v_oc_costo_act FROM opcion_costos WHERE id = v_oc_id;
    IF abs(v_oc_costo_act - v_oc_costo_nuevo) > 0.0001 THEN
        RAISE EXCEPTION 'opcion_costos.costo_unitario no coincide: esperado %, actual %', v_oc_costo_nuevo, v_oc_costo_act;
    END IF;

    SELECT costo_unitario INTO v_cm_costo_act FROM costos_modelo WHERE id = v_cm_id;
    IF abs(v_cm_costo_act - v_cm_costo_nuevo) > 0.0001 THEN
        RAISE EXCEPTION 'costos_modelo.costo_unitario no coincide: esperado %, actual %', v_cm_costo_nuevo, v_cm_costo_act;
    END IF;

    SELECT precio INTO v_ap_costo_act FROM acero_precios WHERE id = v_ap_id;
    IF abs(v_ap_costo_act - v_ap_costo_nuevo) > 0.0001 THEN
        RAISE EXCEPTION 'acero_precios.precio no coincide: esperado %, actual %', v_ap_costo_nuevo, v_ap_costo_act;
    END IF;

    -- Verificar precios_lotes_items
    SELECT count(*) INTO v_items_count FROM precios_lotes_items WHERE lote_id = v_lote_id;
    IF v_items_count <> 4 THEN
        RAISE EXCEPTION 'precios_lotes_items no contiene los 4 items (conteo: %)', v_items_count;
    END IF;

    RAISE NOTICE 'Fase de aplicación verificada con éxito en las 4 tablas.';

    -- 6. Llamar revertir_lote_precios
    v_res_revertir := revertir_lote_precios(
        v_org_id,
        v_user_id,
        v_lote_id
    );

    RAISE NOTICE 'Resultado revertir_lote_precios: %', v_res_revertir;

    IF (v_res_revertir->>'exito')::boolean <> true THEN
        RAISE EXCEPTION 'revertir_lote_precios no tuvo éxito: %', v_res_revertir;
    END IF;

    IF (v_res_revertir->>'revertidos')::int <> 4 THEN
        RAISE EXCEPTION 'Se esperaban 4 cambios revertidos, pero se revirtieron: %', v_res_revertir->>'revertidos';
    END IF;

    v_nuevo_lote_id := (v_res_revertir->>'lote_id')::uuid;

    -- 7. Confirmar restauración de precios originales al 100%
    SELECT costo INTO v_prod_costo_act FROM productos WHERE id = v_prod_id;
    IF abs(v_prod_costo_act - v_prod_costo_orig) > 0.0001 THEN
        RAISE EXCEPTION 'productos.costo NO se restauró: esperado %, actual %', v_prod_costo_orig, v_prod_costo_act;
    END IF;

    SELECT costo_unitario INTO v_oc_costo_act FROM opcion_costos WHERE id = v_oc_id;
    IF abs(v_oc_costo_act - v_oc_costo_orig) > 0.0001 THEN
        RAISE EXCEPTION 'opcion_costos.costo_unitario NO se restauró: esperado %, actual %', v_oc_costo_orig, v_oc_costo_act;
    END IF;

    SELECT costo_unitario INTO v_cm_costo_act FROM costos_modelo WHERE id = v_cm_id;
    IF abs(v_cm_costo_act - v_cm_costo_orig) > 0.0001 THEN
        RAISE EXCEPTION 'costos_modelo.costo_unitario NO se restauró: esperado %, actual %', v_cm_costo_orig, v_cm_costo_act;
    END IF;

    SELECT precio INTO v_ap_costo_act FROM acero_precios WHERE id = v_ap_id;
    IF abs(v_ap_costo_act - v_ap_costo_orig) > 0.0001 THEN
        RAISE EXCEPTION 'acero_precios.precio NO se restauró: esperado %, actual %', v_ap_costo_orig, v_ap_costo_act;
    END IF;

    -- Verificar que el lote original quedó marcado como revertido
    IF NOT EXISTS (SELECT 1 FROM precios_lotes WHERE id = v_lote_id AND revertido_el IS NOT NULL) THEN
        RAISE EXCEPTION 'El lote original % no tiene revertido_el registrado', v_lote_id;
    END IF;

    RAISE NOTICE '=======================================================';
    RAISE NOTICE 'PRUEBA 2R-14 EXITOSA: Aplicación y reversión completa.';
    RAISE NOTICE '4/4 fuentes actualizadas y restauradas a su valor original.';
    RAISE NOTICE '=======================================================';
END $$;

ROLLBACK;
