-- Migración: 20261105_01_gondola_volumen.sql
-- Objetivo:
-- 1. Actualizar restricciones CHECK en receta_base, opcion_componentes, costos_modelo y opcion_costos
--    para admitir la nueva escala 'por_volumen'.
-- 2. Actualizar la función guardar_linea_receta para admitir 'por_volumen'.
-- 3. Crear el grupo de configuración 'volumen' (aplica_a: ['gondola'], seleccion: 'unica', orden: 165)
--    con opciones 'm3_45' (45 m³, por defecto) y 'm3_30' (30 m³).
-- 4. Renombrar productos 'GONDOLA 2 EJES 45 M3' -> 'GONDOLA 2 EJES' y 'GONDOLA 3 EJES 45 M3' -> 'GONDOLA 3 EJES'.
-- 5. Idempotente y multi-inquilino (sin UUIDs literales).

BEGIN;

-- 1. Actualización de restricciones CHECK de escala
ALTER TABLE public.receta_base DROP CONSTRAINT IF EXISTS receta_base_escala_check;
ALTER TABLE public.receta_base ADD CONSTRAINT receta_base_escala_check
    CHECK (escala IS NULL OR escala IN ('fija', 'por_eje', 'por_largo', 'por_volumen'));

ALTER TABLE public.opcion_componentes DROP CONSTRAINT IF EXISTS opcion_componentes_escala_check;
ALTER TABLE public.opcion_componentes ADD CONSTRAINT opcion_componentes_escala_check
    CHECK (escala IS NULL OR escala IN ('fija', 'por_eje', 'por_largo', 'por_volumen'));

ALTER TABLE public.costos_modelo DROP CONSTRAINT IF EXISTS costos_modelo_escala_check;
ALTER TABLE public.costos_modelo ADD CONSTRAINT costos_modelo_escala_check
    CHECK (escala IN ('fija', 'por_eje', 'por_largo', 'por_volumen'));

ALTER TABLE public.opcion_costos DROP CONSTRAINT IF EXISTS opcion_costos_escala_check;
ALTER TABLE public.opcion_costos ADD CONSTRAINT opcion_costos_escala_check
    CHECK (escala IN ('fija', 'por_eje', 'por_largo', 'por_volumen'));

-- 2. Actualización de guardar_linea_receta si la función existe
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM pg_proc p
        JOIN pg_namespace n ON p.pronamespace = n.oid
        WHERE n.nspname = 'public' AND p.proname = 'guardar_linea_receta'
    ) THEN
        CREATE OR REPLACE FUNCTION public.guardar_linea_receta(
            p_modelo_id UUID,
            p_material_id TEXT,
            p_cantidad NUMERIC,
            p_escala TEXT,
            p_fase_id UUID,
            p_organizacion_id UUID,
            p_paso TEXT DEFAULT NULL,
            p_uso TEXT DEFAULT NULL,
            p_seccion TEXT DEFAULT 'ensamble',
            p_linea_id UUID DEFAULT NULL,
            p_usuario_id UUID DEFAULT NULL,
            p_motivo TEXT DEFAULT NULL
        )
        RETURNS UUID
        LANGUAGE plpgsql
        SECURITY DEFINER
        SET search_path = public
        AS $func$
        DECLARE
            v_org_id UUID;
            v_res_linea_id UUID;
            v_ant_data JSONB := NULL;
            v_accion TEXT;
            v_cant_redondeada NUMERIC;
        BEGIN
            -- Validar modelo y organización
            SELECT organizacion_id INTO v_org_id 
            FROM public.modelos 
            WHERE id = p_modelo_id AND organizacion_id = p_organizacion_id;

            IF v_org_id IS NULL THEN
                RAISE EXCEPTION 'modelo_no_encontrado: El modelo especificado no existe o pertenece a otra organización';
            END IF;

            -- Validar que el material exista en la misma organización y sea de tipo materia_prima
            IF NOT EXISTS (
                SELECT 1 FROM public.productos 
                WHERE id = p_material_id 
                  AND organizacion_id = p_organizacion_id
                  AND tipo_item = 'materia_prima'
            ) THEN
                RAISE EXCEPTION 'material_no_encontrado: La materia prima % no existe en la organización o no es de tipo materia_prima', p_material_id;
            END IF;

            -- Validar escala (ahora incluye por_volumen)
            IF p_escala IS NULL OR p_escala NOT IN ('fija', 'por_eje', 'por_largo', 'por_volumen') THEN
                RAISE EXCEPTION 'escala_invalida: La escala debe ser fija, por_eje, por_largo o por_volumen';
            END IF;

            -- Validar cantidad
            IF p_cantidad IS NULL OR p_cantidad = 'NaN'::numeric THEN
                RAISE EXCEPTION 'cantidad_invalida: La cantidad no puede ser nula ni NaN';
            END IF;

            v_cant_redondeada := round(p_cantidad, 4);

            IF v_cant_redondeada <= 0 THEN
                RAISE EXCEPTION 'cantidad_invalida: La cantidad redondeada debe ser mayor a cero';
            END IF;

            -- Validar fase si se especifica
            IF p_fase_id IS NOT NULL AND NOT EXISTS (
                SELECT 1 FROM public.fases_despiece WHERE id = p_fase_id AND organizacion_id = p_organizacion_id
            ) THEN
                RAISE EXCEPTION 'fase_no_encontrada: La fase especificada no existe en la organización';
            END IF;

            IF p_linea_id IS NULL THEN
                -- Inserción
                v_accion := 'crear_linea';
                INSERT INTO public.receta_base (
                    modelo_id,
                    material_id,
                    cantidad,
                    escala,
                    paso,
                    uso,
                    seccion,
                    fase_id
                ) VALUES (
                    p_modelo_id,
                    p_material_id,
                    v_cant_redondeada,
                    p_escala,
                    p_paso,
                    p_uso,
                    COALESCE(p_seccion, 'ensamble'),
                    p_fase_id
                ) RETURNING id INTO v_res_linea_id;
            ELSE
                -- Modificación
                v_accion := 'modificar_linea';

                SELECT to_jsonb(rb.*) INTO v_ant_data
                FROM public.receta_base rb
                JOIN public.modelos m ON rb.modelo_id = m.id
                WHERE rb.id = p_linea_id 
                  AND rb.modelo_id = p_modelo_id 
                  AND m.organizacion_id = p_organizacion_id;

                IF v_ant_data IS NULL THEN
                    RAISE EXCEPTION 'linea_no_encontrada: La línea especificada no existe en la organización';
                END IF;

                UPDATE public.receta_base
                SET material_id = p_material_id,
                    cantidad = v_cant_redondeada,
                    escala = p_escala,
                    paso = p_paso,
                    uso = p_uso,
                    seccion = COALESCE(p_seccion, 'ensamble'),
                    fase_id = p_fase_id,
                    updated_at = NOW()
                WHERE id = p_linea_id
                RETURNING id INTO v_res_linea_id;
            END IF;

            -- Registrar historial
            INSERT INTO public.receta_base_historial (
                modelo_id,
                organizacion_id,
                linea_id,
                accion,
                material_id,
                fase_id,
                datos_anteriores,
                datos_nuevos,
                usuario_id,
                motivo
            ) VALUES (
                p_modelo_id,
                p_organizacion_id,
                v_res_linea_id,
                v_accion,
                p_material_id,
                p_fase_id,
                v_ant_data,
                jsonb_build_object(
                    'material_id', p_material_id,
                    'cantidad', v_cant_redondeada,
                    'escala', p_escala,
                    'paso', p_paso,
                    'uso', p_uso,
                    'seccion', COALESCE(p_seccion, 'ensamble'),
                    'fase_id', p_fase_id
                ),
                p_usuario_id,
                p_motivo
            );

            RETURN v_res_linea_id;
        END;
        $func$;
    END IF;
END $$;

-- 3. Crear grupo 'volumen' y opciones 'm3_45' y 'm3_30' para cada organización existente
DO $$
DECLARE
    r_org RECORD;
    v_grupo_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM public.organizaciones LOOP
        -- Asegurar que el grupo volumen exista
        INSERT INTO public.grupos_configuracion (
            organizacion_id,
            clave,
            nombre,
            seleccion,
            aplica_a,
            depende_de,
            orden
        ) VALUES (
            r_org.id,
            'volumen',
            'Volumen',
            'unica',
            ARRAY['gondola'],
            NULL,
            165
        )
        ON CONFLICT (organizacion_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            seleccion = EXCLUDED.seleccion,
            aplica_a = EXCLUDED.aplica_a,
            orden = EXCLUDED.orden
        RETURNING id INTO v_grupo_id;

        IF v_grupo_id IS NULL THEN
            SELECT id INTO v_grupo_id 
            FROM public.grupos_configuracion 
            WHERE organizacion_id = r_org.id AND clave = 'volumen';
        END IF;

        -- Opción 45 m³ (default histórica)
        INSERT INTO public.opciones_configuracion (
            organizacion_id,
            grupo_id,
            clave,
            nombre,
            datos,
            activo
        ) VALUES (
            r_org.id,
            v_grupo_id,
            'm3_45',
            '45 m³',
            '{"m3": 45}'::jsonb,
            true
        )
        ON CONFLICT (grupo_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            datos = EXCLUDED.datos,
            activo = EXCLUDED.activo;

        -- Opción 30 m³ (nueva opción solicitada)
        INSERT INTO public.opciones_configuracion (
            organizacion_id,
            grupo_id,
            clave,
            nombre,
            datos,
            activo
        ) VALUES (
            r_org.id,
            v_grupo_id,
            'm3_30',
            '30 m³',
            '{"m3": 30}'::jsonb,
            true
        )
        ON CONFLICT (grupo_id, clave) DO UPDATE SET
            nombre = EXCLUDED.nombre,
            datos = EXCLUDED.datos,
            activo = EXCLUDED.activo;

        -- 4. Renombrar productos terminados de Góndola para eliminar volumen fijo del nombre
        UPDATE public.productos
        SET nombre = 'GONDOLA 2 EJES',
            descripcion = 'Góndola 2 ejes'
        WHERE organizacion_id = r_org.id
          AND nombre = 'GONDOLA 2 EJES 45 M3'
          AND tipo_item = 'producto_terminado';

        UPDATE public.productos
        SET nombre = 'GONDOLA 3 EJES',
            descripcion = 'Góndola 3 ejes'
        WHERE organizacion_id = r_org.id
          AND nombre = 'GONDOLA 3 EJES 45 M3'
          AND tipo_item = 'producto_terminado';

    END LOOP;
END $$;

COMMIT;
