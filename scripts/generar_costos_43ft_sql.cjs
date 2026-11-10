/**
 * Generador de migración SQL para los costos de PLATAFORMA 3 43 FT.
 * Deriva los costos del modelo base 40 ft / 2 ejes (mismo método que Sub-bloque 2R-1d).
 * Genera supabase/migrations/20261109_01_costos_plataforma_43ft.sql
 *
 * Criterio de cargadores de 4" (IPR DE 4"):
 * Interpolación lineal de la serie técnica del Excel (BASE DAT PLANAS):
 * - 35 ft -> 34 cargadores
 * - 40 ft -> 38 cargadores (base 40/2)
 * - 42 ft -> 40 cargadores (42 - 2)
 * - 43 ft -> 41 cargadores (43 - 2, interpolación exacta)
 * - 45 ft -> 43 cargadores (45 - 2)
 * - 48 ft -> 46 cargadores (48 - 2)
 */

const fs = require('fs');
const path = require('path');

const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261109_01_costos_plataforma_43ft.sql');

const lines = [];

lines.push('-- Migración 20261109_01_costos_plataforma_43ft.sql');
lines.push('-- Generada automáticamente por scripts/generar_costos_43ft_sql.cjs');
lines.push('-- Cargar costos derivados para PLATAFORMA 3 43 FT a partir de PLATAFORMA 2 40 FT.');
lines.push('--');
lines.push('-- Criterio técnico cargadores: 41 piezas.');
lines.push('-- Interpolación lineal de la serie real de Leolca (40->38, 42->40, 45->43, 48->46; largo - 2).');
lines.push('-- Costo acero esperado: $128,211.69 + 3 x $576.82 = $129,942.15 (= acero 42/3 $129,365.33 + $576.82).');
lines.push('-- Multi-tenant, sin UUIDs hardcodeados e idempotente.');
lines.push('');
lines.push('BEGIN;');
lines.push('');
lines.push('DO $$');
lines.push('DECLARE');
lines.push('    r_org RECORD;');
lines.push('    v_origen_id uuid;');
lines.push('    v_destino_id uuid;');
lines.push('    v_cargador_mat_id text;');
lines.push('    v_acero_count int;');
lines.push('    v_kits_count int;');
lines.push('    v_proc_count int;');
lines.push('BEGIN');
lines.push('    FOR r_org IN SELECT id FROM public.organizaciones LOOP');
lines.push('        -- 1. Validar y obtener modelo origen (plataforma 40 ft / 2 ejes)');
lines.push('        SELECT id INTO v_origen_id');
lines.push('        FROM public.modelos');
lines.push("        WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2 AND organizacion_id = r_org.id;");
lines.push('');
lines.push('        -- 2. Validar y obtener modelo destino (plataforma 43 ft / 3 ejes)');
lines.push('        SELECT id INTO v_destino_id');
lines.push('        FROM public.modelos');
lines.push("        WHERE tipo = 'plataforma' AND largo_ft = 43 AND num_ejes = 3 AND organizacion_id = r_org.id;");
lines.push('');
lines.push('        IF v_origen_id IS NOT NULL AND v_destino_id IS NOT NULL THEN');
lines.push('            -- Validar que el origen tenga exactamente 61 renglones de acero');
lines.push('            SELECT count(*) INTO v_acero_count');
lines.push('            FROM public.receta_base');
lines.push("            WHERE modelo_id = v_origen_id AND seccion = 'acero';");
lines.push('');
lines.push('            IF v_acero_count <> 61 THEN');
lines.push("                RAISE EXCEPTION 'El modelo origen 40/2 no tiene exactamente 61 renglones de acero en receta_base (encontrados: %)', v_acero_count;");
lines.push('            END IF;');
lines.push('');
lines.push('            -- Validar material determinista del cargador de 4"');
lines.push('            SELECT id INTO v_cargador_mat_id');
lines.push('            FROM public.productos');
lines.push("            WHERE nombre = 'CARGADOR (IPR DE 4\")' AND organizacion_id = r_org.id AND tipo_item = 'materia_prima'");
lines.push('            LIMIT 1;');
lines.push('');
lines.push('            IF v_cargador_mat_id IS NULL THEN');
lines.push("                RAISE EXCEPTION 'Material determinista de cargador no encontrado: CARGADOR (IPR DE 4\")';");
lines.push('            END IF;');
lines.push('');
lines.push('            -- Validar que el origen tenga 12 costos_modelo y 80 procesos_manufactura');
lines.push('            SELECT count(*) INTO v_kits_count FROM public.costos_modelo WHERE modelo_id = v_origen_id;');
lines.push('            IF v_kits_count <> 12 THEN');
lines.push("                RAISE EXCEPTION 'El modelo origen 40/2 debe tener 12 costos_modelo, encontrados %', v_kits_count;");
lines.push('            END IF;');
lines.push('');
lines.push('            SELECT count(*) INTO v_proc_count FROM public.procesos_manufactura WHERE modelo_id = v_origen_id;');
lines.push('            IF v_proc_count <> 80 THEN');
lines.push("                RAISE EXCEPTION 'El modelo origen 40/2 debe tener 80 procesos_manufactura, encontrados %', v_proc_count;");
lines.push('            END IF;');
lines.push('');
lines.push('            -- Limpieza previa para idempotencia en el modelo destino');
lines.push("            DELETE FROM public.receta_base WHERE modelo_id = v_destino_id AND seccion = 'acero';");
lines.push("            DELETE FROM public.costos_modelo WHERE modelo_id = v_destino_id AND notas = 'import-43ft';");
lines.push("            DELETE FROM public.procesos_manufactura WHERE modelo_id = v_destino_id AND notas = 'import-43ft';");
lines.push('');
lines.push('            -- 3. Copiar 61 renglones de receta_base acero con cargador a 41 piezas');
lines.push('            INSERT INTO public.receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)');
lines.push('            SELECT');
lines.push('                v_destino_id,');
lines.push('                material_id,');
lines.push('                CASE WHEN material_id = v_cargador_mat_id THEN 41 ELSE cantidad END,');
lines.push('                escala,');
lines.push('                paso,');
lines.push('                uso,');
lines.push('                seccion,');
lines.push('                condicion,');
lines.push("                'import-43ft'");
lines.push('            FROM public.receta_base');
lines.push("            WHERE modelo_id = v_origen_id AND seccion = 'acero';");
lines.push('');
lines.push('            -- 4. Copiar 12 renglones de costos_modelo (kits y consumibles, $45,685.98)');
lines.push('            INSERT INTO public.costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)');
lines.push('            SELECT');
lines.push('                r_org.id,');
lines.push('                v_destino_id,');
lines.push('                seccion,');
lines.push('                concepto,');
lines.push('                cantidad,');
lines.push('                costo_unitario,');
lines.push('                escala,');
lines.push('                fuente,');
lines.push("                'import-43ft'");
lines.push('            FROM public.costos_modelo');
lines.push('            WHERE modelo_id = v_origen_id;');
lines.push('');
lines.push('            -- 5. Copiar 80 renglones de procesos_manufactura (mano de obra, $22,930.00)');
lines.push('            INSERT INTO public.procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)');
lines.push('            SELECT');
lines.push('                r_org.id,');
lines.push('                v_destino_id,');
lines.push('                orden,');
lines.push('                proceso,');
lines.push('                subproceso,');
lines.push('                minutos,');
lines.push('                tarifa_hora,');
lines.push("                'import-43ft'");
lines.push('            FROM public.procesos_manufactura');
lines.push('            WHERE modelo_id = v_origen_id;');
lines.push('');
lines.push('            -- 6. Marcar modelo con costos_derivados_de hacia la 40/2');
lines.push('            UPDATE public.modelos');
lines.push('            SET costos_derivados_de = v_origen_id');
lines.push('            WHERE id = v_destino_id;');
lines.push('        END IF;');
lines.push('    END LOOP;');
lines.push('END $$;');
lines.push('');
lines.push('COMMIT;');
lines.push('');

const outputContent = lines.join('\n');
fs.writeFileSync(outSqlPath, outputContent, 'utf8');

console.log(`Migración generada exitosamente en ${outSqlPath}`);
console.log(`- Modelo origen: Plataforma 40 ft / 2 ejes`);
console.log(`- Modelo destino: Plataforma 43 ft / 3 ejes`);
console.log(`- Cargadores asignados: 41 (interpolación serie Leolca: largo - 2)`);
console.log(`- Renglones insertados por org: 61 acero + 12 kits + 80 procesos = 153`);
