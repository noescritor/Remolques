-- Migración 20261026_01_ajustes_cotizador.sql
-- Sub-bloque 2R-12: ajustes al cotizador (notas del cliente 2026-10-26)
-- 1. Desactivar opción retractil/paleta (activo = false)
-- 2. Desactivar opción piso/plastico_negro (activo = false)
-- 3. Regla de retráctiles por número de ejes: {"max_total":{"por_num_ejes":{"2":1,"3":2}},"cantidad_defecto":1}
-- 4. Desactivar grupo pintura (aplica_a = '{}'::text[])
-- 5. Agregar opción color/personalizado ("Color personalizado", precio 0, costo 0)
-- 6. Copiar costo de paleta a grande en opcion_costos para gondola (15,000) y dolly (8,200)
-- 7. Idempotente con guardias de coherencia (RAISE EXCEPTION si algún grupo/opción esperado no existe exactamente 1 vez por org)
-- 8. Notas exactas: 'import-2r12'

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_count_retractil int;
    v_count_piso int;
    v_count_pintura int;
    v_count_color int;
    v_count_paleta int;
    v_count_grande int;
    v_count_plastico_negro int;
    v_grupo_retractil_id uuid;
    v_grupo_piso_id uuid;
    v_grupo_pintura_id uuid;
    v_grupo_color_id uuid;
    v_opt_paleta_id uuid;
    v_opt_grande_id uuid;
    v_opt_plastico_negro_id uuid;
    v_opt_personalizado_id uuid;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        -- 1. Guardias de coherencia de grupos
        SELECT count(*), (array_agg(id))[1] INTO v_count_retractil, v_grupo_retractil_id
        FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'retractil';

        SELECT count(*), (array_agg(id))[1] INTO v_count_piso, v_grupo_piso_id
        FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'piso';

        SELECT count(*), (array_agg(id))[1] INTO v_count_pintura, v_grupo_pintura_id
        FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'pintura';

        SELECT count(*), (array_agg(id))[1] INTO v_count_color, v_grupo_color_id
        FROM grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'color';

        IF v_count_retractil <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "retractil" encontrado % veces (se esperaba 1)', r_org.id, v_count_retractil;
        END IF;
        IF v_count_piso <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "piso" encontrado % veces (se esperaba 1)', r_org.id, v_count_piso;
        END IF;
        IF v_count_pintura <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "pintura" encontrado % veces (se esperaba 1)', r_org.id, v_count_pintura;
        END IF;
        IF v_count_color <> 1 THEN
            RAISE EXCEPTION 'Org %: grupo "color" encontrado % veces (se esperaba 1)', r_org.id, v_count_color;
        END IF;

        -- 2. Guardias de coherencia de opciones esperadas
        SELECT count(*), (array_agg(id))[1] INTO v_count_paleta, v_opt_paleta_id
        FROM opciones_configuracion
        WHERE organizacion_id = r_org.id AND grupo_id = v_grupo_retractil_id AND clave = 'paleta';

        SELECT count(*), (array_agg(id))[1] INTO v_count_grande, v_opt_grande_id
        FROM opciones_configuracion
        WHERE organizacion_id = r_org.id AND grupo_id = v_grupo_retractil_id AND clave = 'grande';

        SELECT count(*), (array_agg(id))[1] INTO v_count_plastico_negro, v_opt_plastico_negro_id
        FROM opciones_configuracion
        WHERE organizacion_id = r_org.id AND grupo_id = v_grupo_piso_id AND clave = 'plastico_negro';

        IF v_count_paleta <> 1 THEN
            RAISE EXCEPTION 'Org %: opción "retractil/paleta" encontrada % veces (se esperaba 1)', r_org.id, v_count_paleta;
        END IF;
        IF v_count_grande <> 1 THEN
            RAISE EXCEPTION 'Org %: opción "retractil/grande" encontrada % veces (se esperaba 1)', r_org.id, v_count_grande;
        END IF;
        IF v_count_plastico_negro <> 1 THEN
            RAISE EXCEPTION 'Org %: opción "piso/plastico_negro" encontrada % veces (se esperaba 1)', r_org.id, v_count_plastico_negro;
        END IF;

        -- 3. Actualizar grupo retractil con nueva regla por_num_ejes
        UPDATE grupos_configuracion
        SET regla = jsonb_build_object(
                'max_total', jsonb_build_object('por_num_ejes', jsonb_build_object('2', 1, '3', 2)),
                'cantidad_defecto', 1
            ),
            cantidad = 'Hasta 1 en 2 ejes, hasta 2 en 3 ejes',
            notas = 'import-2r12'
        WHERE organizacion_id = r_org.id AND clave = 'retractil';

        -- 4. Desactivar grupo pintura (aplica_a = '{}')
        UPDATE grupos_configuracion
        SET aplica_a = '{}'::text[],
            notas = 'import-2r12'
        WHERE organizacion_id = r_org.id AND clave = 'pintura';

        -- 5. Desactivar opción retractil/paleta
        UPDATE opciones_configuracion
        SET activo = false,
            notas = 'import-2r12'
        WHERE organizacion_id = r_org.id AND id = v_opt_paleta_id;

        -- 6. Desactivar opción piso/plastico_negro
        UPDATE opciones_configuracion
        SET activo = false,
            notas = 'import-2r12'
        WHERE organizacion_id = r_org.id AND id = v_opt_plastico_negro_id;

        -- 7. Copiar costo de paleta a grande en opcion_costos para gondola y dolly
        INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
        SELECT
            r_org.id,
            v_opt_grande_id,
            oc_paleta.tipo_modelo,
            oc_paleta.cantidad_base,
            oc_paleta.escala,
            oc_paleta.costo_unitario,
            'Copiado de paleta (2R-12)',
            'import-2r12'
        FROM opcion_costos oc_paleta
        WHERE oc_paleta.organizacion_id = r_org.id
          AND oc_paleta.opcion_id = v_opt_paleta_id
          AND oc_paleta.tipo_modelo IN ('gondola', 'dolly')
          AND NOT EXISTS (
              SELECT 1
              FROM opcion_costos oc_grande
              WHERE oc_grande.organizacion_id = r_org.id
                AND oc_grande.opcion_id = v_opt_grande_id
                AND oc_grande.tipo_modelo = oc_paleta.tipo_modelo
          );

        -- 8. Opción color/personalizado
        SELECT id INTO v_opt_personalizado_id
        FROM opciones_configuracion
        WHERE organizacion_id = r_org.id AND grupo_id = v_grupo_color_id AND clave = 'personalizado';

        IF v_opt_personalizado_id IS NULL THEN
            INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, activo, notas)
            VALUES (v_grupo_color_id, r_org.id, 'personalizado', 'Color personalizado', 0, true, 'import-2r12')
            RETURNING id INTO v_opt_personalizado_id;
        ELSE
            UPDATE opciones_configuracion
            SET nombre = 'Color personalizado',
                precio_venta = 0,
                activo = true,
                notas = 'import-2r12'
            WHERE id = v_opt_personalizado_id;
        END IF;

        -- Costos de color/personalizado (costo 0, fuente 'definido' para no generar pendientes)
        INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
        SELECT r_org.id, v_opt_personalizado_id, 'plataforma', 1, 'fija', 0, 'definido', 'import-2r12'
        WHERE NOT EXISTS (
            SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_personalizado_id AND tipo_modelo = 'plataforma'
        );

        INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
        SELECT r_org.id, v_opt_personalizado_id, 'dolly', 1, 'fija', 0, 'definido', 'import-2r12'
        WHERE NOT EXISTS (
            SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_personalizado_id AND tipo_modelo = 'dolly'
        );

        INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
        SELECT r_org.id, v_opt_personalizado_id, 'gondola', 1, 'fija', 0, 'definido', 'import-2r12'
        WHERE NOT EXISTS (
            SELECT 1 FROM opcion_costos WHERE opcion_id = v_opt_personalizado_id AND tipo_modelo = 'gondola'
        );

    END LOOP;
END $$;

COMMIT;
