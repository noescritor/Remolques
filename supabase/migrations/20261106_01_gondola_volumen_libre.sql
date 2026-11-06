-- Migración: Góndola volumen editable / libre en m³
-- Fecha: 2026-11-06
-- Agrega la opción 'personalizado' con límites min/max al grupo 'volumen'
-- y desactiva las opciones de tarjeta fija ('m3_45' y 'm3_30') sin borrarlas.

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_grupo_id UUID;
BEGIN
    FOR r_org IN SELECT id FROM public.organizaciones LOOP
        -- Obtener ID del grupo volumen en la organización
        SELECT id INTO v_grupo_id
        FROM public.grupos_configuracion
        WHERE organizacion_id = r_org.id AND clave = 'volumen';

        IF v_grupo_id IS NOT NULL THEN
            -- 1. Insertar o actualizar la opción 'personalizado' con datos min/max
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
                'personalizado',
                'Personalizado',
                '{"min": 20, "max": 60}'::jsonb,
                true
            )
            ON CONFLICT (grupo_id, clave) DO UPDATE SET
                nombre = EXCLUDED.nombre,
                datos = EXCLUDED.datos,
                activo = EXCLUDED.activo;

            -- 2. Desactivar opciones fijas (m3_30 y m3_45) para que no se ofrezcan como tarjetas
            UPDATE public.opciones_configuracion
            SET activo = false
            WHERE grupo_id = v_grupo_id
              AND clave IN ('m3_45', 'm3_30');
        END IF;
    END LOOP;
END $$;

COMMIT;
