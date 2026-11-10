-- Migración 20261109_01_costos_plataforma_43ft.sql
-- Generada automáticamente por scripts/generar_costos_43ft_sql.cjs
-- Cargar costos derivados para PLATAFORMA 3 43 FT a partir de PLATAFORMA 2 40 FT.
--
-- Criterio técnico cargadores: 41 piezas.
-- Interpolación lineal de la serie real de Leolca (40->38, 42->40, 45->43, 48->46; largo - 2).
-- Costo acero esperado: $128,211.69 + 3 x $576.82 = $129,942.15 (= acero 42/3 $129,365.33 + $576.82).
-- Multi-tenant, sin UUIDs hardcodeados e idempotente.

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_origen_id uuid;
    v_destino_id uuid;
    v_cargador_mat_id text;
    v_acero_count int;
    v_kits_count int;
    v_proc_count int;
BEGIN
    FOR r_org IN SELECT id FROM public.organizaciones LOOP
        -- 1. Validar y obtener modelo origen (plataforma 40 ft / 2 ejes)
        SELECT id INTO v_origen_id
        FROM public.modelos
        WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = r_org.id;

        -- 2. Validar y obtener modelo destino (plataforma 43 ft / 3 ejes)
        SELECT id INTO v_destino_id
        FROM public.modelos
        WHERE tipo = 'plataforma' AND largo_ft = 43 AND num_ejes = 3 AND organizacion_id = r_org.id;

        IF v_origen_id IS NOT NULL AND v_destino_id IS NOT NULL THEN
            -- Validar que el origen tenga exactamente 61 renglones de acero
            SELECT count(*) INTO v_acero_count
            FROM public.receta_base
            WHERE modelo_id = v_origen_id AND seccion = 'acero';

            IF v_acero_count <> 61 THEN
                RAISE EXCEPTION 'El modelo origen 40/2 no tiene exactamente 61 renglones de acero en receta_base (encontrados: %)', v_acero_count;
            END IF;

            -- Validar material determinista del cargador de 4"
            SELECT id INTO v_cargador_mat_id
            FROM public.productos
            WHERE nombre = 'CARGADOR (IPR DE 4")' AND organizacion_id = r_org.id AND tipo_item = 'materia_prima'
            LIMIT 1;

            IF v_cargador_mat_id IS NULL THEN
                RAISE EXCEPTION 'Material determinista de cargador no encontrado: CARGADOR (IPR DE 4")';
            END IF;

            -- Validar que el origen tenga 12 costos_modelo y 80 procesos_manufactura
            SELECT count(*) INTO v_kits_count FROM public.costos_modelo WHERE modelo_id = v_origen_id;
            IF v_kits_count <> 12 THEN
                RAISE EXCEPTION 'El modelo origen 40/2 debe tener 12 costos_modelo, encontrados %', v_kits_count;
            END IF;

            SELECT count(*) INTO v_proc_count FROM public.procesos_manufactura WHERE modelo_id = v_origen_id;
            IF v_proc_count <> 80 THEN
                RAISE EXCEPTION 'El modelo origen 40/2 debe tener 80 procesos_manufactura, encontrados %', v_proc_count;
            END IF;

            -- Limpieza previa para idempotencia en el modelo destino
            DELETE FROM public.receta_base WHERE modelo_id = v_destino_id AND seccion = 'acero';
            DELETE FROM public.costos_modelo WHERE modelo_id = v_destino_id AND notas = 'import-43ft';
            DELETE FROM public.procesos_manufactura WHERE modelo_id = v_destino_id AND notas = 'import-43ft';

            -- 3. Copiar 61 renglones de receta_base acero con cargador a 41 piezas
            INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
            SELECT
                v_destino_id,
                material_id,
                CASE WHEN material_id = v_cargador_mat_id THEN 41 ELSE cantidad END,
                escala,
                paso,
                uso,
                seccion,
                condicion,
                'import-43ft'
            FROM public.receta_base
            WHERE modelo_id = v_origen_id AND seccion = 'acero';

            -- 4. Copiar 12 renglones de costos_modelo (kits y consumibles, $45,685.98)
            INSERT INTO public.costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
            SELECT
                r_org.id,
                v_destino_id,
                seccion,
                concepto,
                cantidad,
                costo_unitario,
                escala,
                fuente,
                'import-43ft'
            FROM public.costos_modelo
            WHERE modelo_id = v_origen_id;

            -- 5. Copiar 80 renglones de procesos_manufactura (mano de obra, $22,930.00)
            INSERT INTO public.procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
            SELECT
                r_org.id,
                v_destino_id,
                orden,
                proceso,
                subproceso,
                minutos,
                tarifa_hora,
                'import-43ft'
            FROM public.procesos_manufactura
            WHERE modelo_id = v_origen_id;

            -- 6. Marcar modelo con costos_derivados_de hacia la 40/2
            UPDATE public.modelos
            SET costos_derivados_de = v_origen_id
            WHERE id = v_destino_id;
        END IF;
    END LOOP;
END $$;

COMMIT;
