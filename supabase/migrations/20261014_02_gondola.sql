-- Migración 20261014_02_gondola.sql
-- Generada automáticamente por scripts/generar_costos_gondola_sql.cjs
-- Sub-bloque 2R-1f: Modelos, chasis, tina por material, kits fijos y costos de opciones de la Góndola
-- Idempotente, ejecutable en una sola transacción.

BEGIN;

-- Función temporal de sesión para resolver o crear materiales deterministas para la góndola
CREATE OR REPLACE FUNCTION pg_temp.resolver_o_crear_material_gondola(
    p_org_id uuid,
    p_nombre text,
    p_costo numeric,
    p_desc text
) RETURNS text AS $$
DECLARE
    v_exist_id text;
    v_exist_costo numeric;
    v_final_nombre text := p_nombre;
    v_res_id text;
    v_res_costo numeric;
BEGIN
    SELECT id, costo INTO v_exist_id, v_exist_costo
    FROM productos
    WHERE nombre = p_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'
    LIMIT 1;

    IF v_exist_id IS NOT NULL THEN
        IF v_exist_costo = p_costo THEN
            RETURN v_exist_id;
        ELSE
            v_final_nombre := p_nombre || ' (GONDOLA)';
            SELECT id, costo INTO v_res_id, v_res_costo
            FROM productos
            WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'
            LIMIT 1;
            IF v_res_id IS NOT NULL THEN
                IF v_res_costo = p_costo THEN
                    RETURN v_res_id;
                ELSE
                    v_final_nombre := v_final_nombre || ' #2';
                    SELECT id INTO v_res_id
                    FROM productos
                    WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'
                    LIMIT 1;
                    IF v_res_id IS NOT NULL THEN
                        RETURN v_res_id;
                    END IF;
                END IF;
            END IF;
        END IF;
    END IF;

    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    VALUES (v_final_nombre, 'bien', 'materia_prima', 'PZA', p_costo, 0, p_desc, p_org_id)
    RETURNING id INTO v_res_id;

    RETURN v_res_id;
END;
$$ LANGUAGE plpgsql;

DO $$
DECLARE
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_prod_2e_id text;
    v_prod_3e_id text;
    v_model_2e_id uuid;
    v_model_3e_id uuid;
    v_mat_id text;
    v_opt_id uuid;
    v_opt_a36_id uuid;
    v_opt_hardox_id uuid;
    v_count int;
    v_sum_acero_2e numeric;
    v_sum_acero_3e numeric;
    v_sum_kits_2e numeric;
    v_sum_kits_3e numeric;
BEGIN

    -- 1. Productos terminados y modelos Góndola 2 y 3 ejes
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'GONDOLA 2 EJES 45 M3', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Góndola 2 ejes 45 m3', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM productos
        WHERE nombre = 'GONDOLA 2 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'
    );

    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'GONDOLA 3 EJES 45 M3', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Góndola 3 ejes 45 m3', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM productos
        WHERE nombre = 'GONDOLA 3 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'
    );

    SELECT id INTO v_prod_2e_id FROM productos WHERE nombre = 'GONDOLA 2 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;
    IF v_prod_2e_id IS NULL THEN RAISE EXCEPTION 'Producto terminado GONDOLA 2 EJES 45 M3 no encontrado'; END IF;

    SELECT id INTO v_prod_3e_id FROM productos WHERE nombre = 'GONDOLA 3 EJES 45 M3' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;
    IF v_prod_3e_id IS NULL THEN RAISE EXCEPTION 'Producto terminado GONDOLA 3 EJES 45 M3 no encontrado'; END IF;

    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
    VALUES (v_org_id, v_prod_2e_id, 'gondola', NULL, 2)
    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET
        tipo = EXCLUDED.tipo,
        largo_ft = EXCLUDED.largo_ft,
        num_ejes = EXCLUDED.num_ejes;

    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
    VALUES (v_org_id, v_prod_3e_id, 'gondola', NULL, 3)
    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET
        tipo = EXCLUDED.tipo,
        largo_ft = EXCLUDED.largo_ft,
        num_ejes = EXCLUDED.num_ejes;

    SELECT id INTO v_model_2e_id FROM modelos WHERE producto_id = v_prod_2e_id AND organizacion_id = v_org_id LIMIT 1;
    SELECT id INTO v_model_3e_id FROM modelos WHERE producto_id = v_prod_3e_id AND organizacion_id = v_org_id LIMIT 1;
    IF v_model_2e_id IS NULL OR v_model_3e_id IS NULL THEN RAISE EXCEPTION 'Modelos de góndola no encontrados'; END IF;

    -- 2. Limpieza previa idempotente para import-2r1f
    DELETE FROM receta_base WHERE modelo_id IN (v_model_2e_id, v_model_3e_id) AND notas = 'import-2r1f';
    DELETE FROM costos_modelo WHERE modelo_id IN (v_model_2e_id, v_model_3e_id) AND notas = 'import-2r1f';
    DELETE FROM opcion_costos WHERE tipo_modelo = 'gondola' AND (notas = 'import-2r1f' OR fuente = 'Factura Leolca');

    -- Obtener IDs de las opciones tina_material para opcion_componentes
    SELECT oc.id INTO v_opt_a36_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave = 'a36' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_a36_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: tina_material -> a36'; END IF;

    SELECT oc.id INTO v_opt_hardox_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave = 'hardox_450' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_hardox_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: tina_material -> hardox_450'; END IF;

    DELETE FROM opcion_componentes WHERE opcion_id IN (v_opt_a36_id, v_opt_hardox_id) AND notas = 'import-2r1f';

    -- 3. Inserción de materiales de acero y receta_base sección acero (49 renglones para ambos modelos)

    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")', 12500, 'Placa de grado A-50 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Alma', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Alma', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SOLERAS (SOLERA DE GRADO A-529 A 1/2" X 6")', 7304, 'Solera de grado A-529 a 1/2" X 6"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Soleras', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Soleras', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUENTES DE SUSPENSIÓN (PLACA DE GRADO A-36 CAL. 1/4")', 700, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 9, 'fija', NULL, 'Puentes de suspensión', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 9, 'fija', NULL, 'Puentes de suspensión', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUENTES INTERMEDIOS (PLACA DE GRADO A-36 CAL. 1/4")', 600, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Puentes intermedios', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Puentes intermedios', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUENTES PARA PATINES (PLACA DE GRADO A-36 CAL. 3/16")', 440, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Puentes para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Puentes para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CARTABON PARA PUENTE DE PATIN (PLACA DE GRADO A-36 CAL. 1/4")', 300, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Cartabon para puente de patin', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Cartabon para puente de patin', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUENTES PARA PLANCHA (PLACA DE GRADO A-36 CAL. 1/4")', 700, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 3, 'fija', NULL, 'Puentes para plancha', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 3, 'fija', NULL, 'Puentes para plancha', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")', 480, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Borda delantera', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Borda delantera', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PLANCHA (PLACA DE GRADO A-36 CAL. 3/8")', 3235, 'Placa de grado A-36 Cal. 3/8"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Plancha', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Plancha', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ATISADOR (SOLERA DE GRADO A-36 A 3/8" X 2")', 40, 'Solera de grado A-36 a 3/8" X 2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 6, 'fija', NULL, 'Atisador', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 6, 'fija', NULL, 'Atisador', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ATISADOR (SOLERA DE GRADO A-36 A 3/8" X 2")', 75, 'Solera de grado A-36 a 3/8" X 2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 18, 'fija', NULL, 'Atisador', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 18, 'fija', NULL, 'Atisador', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'KIT DE PERNOS', 13000, 'Kit de pernos');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Kit de pernos', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Kit de pernos', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")', 77, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Base para tanques', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Base para tanques', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'JALON PLACA BASE (PLACA DE GRADO A-36 CAL. 1/2")', 2500, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'JALON REFUERZO (PLACA DE GRADO A-36 CAL. 3/8")', 600, 'Placa de grado A-36 Cal. 3/8"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'JALON CARTABONES', 400, 'Jalon');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA ESTRIBO PLACA (PLACA DE GRADO A-36 CAL. 1/4")', 130, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA ESTRIBO SOLERA FRONTAL', 170, 'Base para estribo');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA ESTRIBO SOLERA POSTERIOR', 65, 'Base para estribo');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ESTRIBO (PTR 4X4")', 1050, 'PTR 4X4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Estribo', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Estribo', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'C PARA GATO (PLACA DE GRADO A-36 CAL. 3/8")', 350, 'Placa de grado A-36 Cal. 3/8"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'C para gato', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'C para gato', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")', 101, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Base para manitas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Base para manitas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 10)', 380, 'Placa de grado A-36 Cal. 10');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Porta loderas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Porta loderas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'U PARA JALON (REDONDO DE 1")', 102, 'Redondo de 1"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'U para jalon', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'U para jalon', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")', 234, 'Solera de grado A-36 a 1/2" x 6"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 6, 'fija', NULL, 'Base para perchas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 6, 'fija', NULL, 'Base para perchas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")', 67, 'Solera de grado A-36 a 1/2" x 3"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 6, 'fija', NULL, 'Base para platos', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 6, 'fija', NULL, 'Base para platos', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'TAPA PARA PERNO REY (CANAL U 6")', 100, 'Canal u 6"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Tapa para perno rey', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Tapa para perno rey', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")', 52.6, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")', 23.4, 'Solera de grado A-36 a 3/8" x 2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")', 22.6, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Base para foco de ABS', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Base para foco de ABS', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")', 28, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Base para ABS', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Base para ABS', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)', 45, 'Placa de grado A-36 Cal. 10');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 1, 'fija', NULL, 'Porta placas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 1, 'fija', NULL, 'Porta placas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")', 196.99, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 125CM', 223.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 70CM', 124.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 67CM', 119.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 23CM', 41.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")', 23.99, 'Solera de grado A-36 a 1/2" x 3"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 27CM', 90.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES 30CM', 100.99, 'Heraje para patines');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")', 40.99, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")', 87.99, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 4, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 4, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")', 275.99, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")', 738.99, 'Solera de grado A-36 a 1/2" x 3"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PORTA LLANTAS (REDONDO DE 1")', 400, 'Redondo de 1"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'TUBOS PARA CABLEADO (TUBO DE 1 1/2" CED. 40)', 10.99, 'Tubo de 1 1/2" Ced. 40');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 20, 'fija', NULL, 'Tubos para cableado', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 20, 'fija', NULL, 'Tubos para cableado', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CHAMBER PARA PUERTAS', 487.99, 'Chamber para puertas');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Chamber para puertas', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Chamber para puertas', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'REFUERZO TRUZA (PLACA DE GRADO A-36 CAL. 1/4")', 82.99, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 12, 'fija', NULL, 'Refuerzo truza', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 12, 'fija', NULL, 'Refuerzo truza', 'acero', NULL, 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CAJON PARA CASQUILLO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")', 340, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_2e_id, v_mat_id, 2, 'fija', NULL, 'Cajon para casquillo trasero', 'acero', NULL, 'import-2r1f');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_3e_id, v_mat_id, 2, 'fija', NULL, 'Cajon para casquillo trasero', 'acero', NULL, 'import-2r1f');

    -- Validación de suma de acero (debe ser exactamente 103,936.96 en ambos modelos)
    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero_2e
    FROM receta_base rb
    JOIN productos p ON rb.material_id = p.id
    WHERE rb.modelo_id = v_model_2e_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f';
    IF v_sum_acero_2e <> 103936.96 THEN
        RAISE EXCEPTION 'El acero de la góndola 2 ejes no suma 103,936.96 (suma actual: %)', v_sum_acero_2e;
    END IF;

    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero_3e
    FROM receta_base rb
    JOIN productos p ON rb.material_id = p.id
    WHERE rb.modelo_id = v_model_3e_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1f';
    IF v_sum_acero_3e <> 103936.96 THEN
        RAISE EXCEPTION 'El acero de la góndola 3 ejes no suma 103,936.96 (suma actual: %)', v_sum_acero_3e;
    END IF;

    -- 4. Tina por material -> opcion_componentes (BOM)
    -- Tina A-36: 43 renglones
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'VUELTAS TRASERAS (PLACA HARDOX CAL. 3/16")', 4510, 'Placa hardox Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Vueltas traseras', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CUELLOS (PLACA HARDOX CAL. 3/16")', 2430, 'Placa hardox Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Cuellos', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'VUELTAS FRONTALES (PLACA HARDOX CAL. 3/16")', 3670, 'Placa hardox Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Vueltas frontales', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PLACAS LATERALES PARA TINA (PLACA DE GRADO A-36 CAL. 3/16")', 3200, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 6, 'fija', 'componente', NULL, 'Placas laterales para tina', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BISERA (PLACA DE GRADO A-36 CAL. 1/4")', 1490, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Bisera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'POSTES PARA GATO (PLACA DE GRADO A-36 CAL. 1/4")', 2620, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Postes para gato', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")', 1690, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Borda trasera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'RESVALON (PLACA DE GRADO A-36 CAL. 3/16")', 980, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Resvalon', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'POSTE TRASERO (PLACA DE GRADO A-36 CAL. 3/16")', 2090, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Poste trasero', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CHAROLA (PLACA DE GRADO A-36 CAL. 3/16")', 1500, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Charola', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ALETAS TRASERAS (PLACA DE GRADO A-36 CAL. 10)', 610, 'Placa de grado A-36 Cal. 10');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Aletas traseras', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CARTABON PARA GATO (PLACA DE GRADO A-36 CAL. 10)', 80, 'Placa de grado A-36 Cal. 10');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Cartabon para gato', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PISO (PLACA DE GRADO A-36 CAL. 1/4")', 11500, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Piso', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")', 5785, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Placa frontal', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PLACA PARA TAPA (PLACA DE GRADO A-36 CAL. 1/4")', 6500, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Placa para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'REFUERZO PARA POSTE (PLACA DE GRADO A-36 CAL. 1/4")', 155, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 20, 'fija', 'componente', NULL, 'Refuerzo para poste', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'GANCHOS PARA LONAS (REDONDO DE 1/2")', 6.3, 'Redondo de 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 26, 'fija', 'componente', NULL, 'Ganchos para lonas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ESCALERA (TUBO MEC. 3/4 CED. 40)', 33, 'Tubo Mec. 3/4 Ced. 40');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 10, 'fija', 'componente', NULL, 'Escalera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ESCALERA (SOLERA 3/8 X 2")', 390, 'Solera 3/8 X 2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Escalera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER (PLACA DE GRADO A-36 CAL. 1/4")', 150, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER', 100, 'Base para chamber');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER', 460, 'Base para chamber');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BOTAS PARA TAPA (PLACA DE GRADO A-36 CAL. 1/2")', 230, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Botas para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASES PARA TAPA (PLACA DE GRADO A-36 CAL. 1/4")', 50, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Bases para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'TORNILLERIA PARA TAPA', 103, 'Tornilleria para tapa');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Tornilleria para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SEGURO PARA PUERTA (PLACA DE GRADO A-36 CAL. 1/2")', 95, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Seguro para puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 3X3" A 1.8M)', 562.99, 'PTR 3X3" a 1.8m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 3, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 1 1/2 X 3" A 1.1M)', 153.5, 'PTR 1 1/2 X 3" a 1.1m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 3X3" A 2.5M)', 782, 'PTR 3X3" a 2.5m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (REDONDO 1" A 30CM)', 200, 'Redondo 1" a 30cm');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS INFERIOR (HSS 4 X 6" EN 3/16)', 11000, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'HSS inferior', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BRASOS FRONTALES (HSS 4 X 6" EN 1/4 A 1.8M)', 1680, 'Hss 4 X 6" en 1/4 a 1.8m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Brasos frontales', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BRASOS TRASEROS (HSS 4 X 6" EN 3/16 A 2.1M)', 2000, 'Hss 4 X 6" en 3/16 a 2.1m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 6, 'fija', 'componente', NULL, 'Brasos traseros', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS SUPERIOR (HSS 4 X 6" EN 3/16)', 11000, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Hss superior', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'REFUERZO INTERNO DE TINA (HSS 4 X 6" EN 3/16 A 96CM)', 882, 'Hss 4 X 6" en 3/16 a 96cm');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 5, 'fija', 'componente', NULL, 'Refuerzo interno de tina', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS FRONTAL (HSS 4 X 6" EN 3/16)', 2388.99, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Hss frontal', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA (PLACA DE GRADO A-36 CAL. 1/2")', 55, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA (REDONDO 1/2")', 50, 'Redondo 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA', 19, 'Paloma para la puerta');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA', 120, 'Paloma para la puerta');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 3500, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 0, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 110, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 0, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 150, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_a36_id, v_mat_id, 0, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');

    -- Tina Hardox 450: 39 componentes (2 paquetes reemplazan 6 renglones, más 37 renglones individuales)
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PAQUETE TINA HARDOX 450 (VUELTAS TRASERAS, CUELLOS, VUELTAS FRONTALES)', 80137.66, 'PAQUETE TINA HARDOX (Vueltas traseras 4 pzas, Cuellos 2 pzas, Vueltas frontales 2 pzas)');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Paquete vueltas/cuellos', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PLACAS LATERALES PARA TINA (PLACA HARDOX 450 CAL. 3/16")', 3200, 'Placa Hardox 450 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 6, 'fija', 'componente', NULL, 'Placas laterales para tina', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BISERA (PLACA DE GRADO A-36 CAL. 1/4")', 1490, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Bisera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'POSTES PARA GATO (PLACA DE GRADO A-36 CAL. 1/4")', 2620, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Postes para gato', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")', 1690, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Borda trasera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'RESVALON (PLACA DE GRADO A-36 CAL. 3/16")', 980, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Resvalon', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'POSTE TRASERO (PLACA DE GRADO A-36 CAL. 3/16")', 2090, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Poste trasero', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CHAROLA (PLACA DE GRADO A-36 CAL. 3/16")', 1500, 'Placa de grado A-36 Cal. 3/16"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Charola', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ALETAS TRASERAS (PLACA DE GRADO A-36 CAL. 10)', 610, 'Placa de grado A-36 Cal. 10');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Aletas traseras', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'CARTABON PARA GATO (PLACA DE GRADO A-36 CAL. 10)', 80, 'Placa de grado A-36 Cal. 10');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Cartabon para gato', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PAQUETE TINA HARDOX 450 (PISO, PLACA FRONTAL, PLACA PARA TAPA)', 76600, 'PAQUETE TINA HARDOX (Piso 1 pza, Placa frontal 1 pza, Placa para tapa 1 pza)');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Paquete piso/tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'REFUERZO PARA POSTE (PLACA DE GRADO A-36 CAL. 1/4")', 155, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 20, 'fija', 'componente', NULL, 'Refuerzo para poste', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'GANCHOS PARA LONAS (REDONDO DE 1/2")', 6.3, 'Redondo de 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 26, 'fija', 'componente', NULL, 'Ganchos para lonas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ESCALERA (TUBO MEC. 3/4 CED. 40)', 33, 'Tubo Mec. 3/4 Ced. 40');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 10, 'fija', 'componente', NULL, 'Escalera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'ESCALERA (SOLERA 3/8 X 2")', 390, 'Solera 3/8 X 2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Escalera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER (PLACA DE GRADO A-36 CAL. 1/4")', 150, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER', 100, 'Base para chamber');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASE PARA CHAMBER', 460, 'Base para chamber');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Base para chamber', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BOTAS PARA TAPA (PLACA DE GRADO A-36 CAL. 1/2")', 230, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Botas para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BASES PARA TAPA (PLACA DE GRADO A-36 CAL. 1/4")', 50, 'Placa de grado A-36 Cal. 1/4"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Bases para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'TORNILLERIA PARA TAPA', 103, 'Tornilleria para tapa');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Tornilleria para tapa', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SEGURO PARA PUERTA (PLACA DE GRADO A-36 CAL. 1/2")', 95, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Seguro para puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 3X3" A 1.8M)', 562.99, 'PTR 3X3" a 1.8m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 3, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 1 1/2 X 3" A 1.1M)', 153.5, 'PTR 1 1/2 X 3" a 1.1m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (PTR 3X3" A 2.5M)', 782, 'PTR 3X3" a 2.5m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PUERA (REDONDO 1" A 30CM)', 200, 'Redondo 1" a 30cm');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Puera', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS INFERIOR (HSS 4 X 6" EN 3/16)', 11000, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'HSS inferior', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BRASOS FRONTALES (HSS 4 X 6" EN 1/4 A 1.8M)', 1680, 'Hss 4 X 6" en 1/4 a 1.8m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Brasos frontales', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'BRASOS TRASEROS (HSS 4 X 6" EN 3/16 A 2.1M)', 2000, 'Hss 4 X 6" en 3/16 a 2.1m');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 6, 'fija', 'componente', NULL, 'Brasos traseros', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS SUPERIOR (HSS 4 X 6" EN 3/16)', 11000, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Hss superior', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'REFUERZO INTERNO DE TINA (HSS 4 X 6" EN 3/16 A 96CM)', 882, 'Hss 4 X 6" en 3/16 a 96cm');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 5, 'fija', 'componente', NULL, 'Refuerzo interno de tina', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'HSS FRONTAL (HSS 4 X 6" EN 3/16)', 2388.99, 'Hss 4 X 6" en 3/16');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Hss frontal', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA (PLACA DE GRADO A-36 CAL. 1/2")', 55, 'Placa de grado A-36 Cal. 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA (REDONDO 1/2")', 50, 'Redondo 1/2"');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA', 19, 'Paloma para la puerta');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'PALOMA PARA LA PUERTA', 120, 'Paloma para la puerta');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Paloma para la puerta', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 3500, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 2, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 110, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 4, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');
    v_mat_id := pg_temp.resolver_o_crear_material_gondola(v_org_id, 'SALPICADERAS', 150, 'Salpicaderas');
    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, uso, seccion, notas)
    VALUES (v_opt_hardox_id, v_mat_id, 1, 'fija', 'componente', NULL, 'Salpicaderas', 'acero', 'import-2r1f');

    -- 5. Costos de opciones tina_material en opcion_costos
    -- A-36: 167,505.76
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_a36_id, 'gondola', 1, 'fija', 167505.76, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

    -- Hardox 450: 286,748.42
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_hardox_id, 'gondola', 1, 'fija', 286748.42, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

    -- 6. Costos fijos en costos_modelo
    -- Kits comunes a ambas hojas (14 conceptos, suma = 88,996.98)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'luz', 'Kit de luz', 1, 8500, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'pintura', 'Praimer', 1, 10000, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'tornilleria', 'Kit de tornillería para patines', 44, 15, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'tornilleria', 'Tornillería para loderas', 8, 5, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'consumibles', 'Rollo de micro tubular', 3, 995, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'consumibles', 'Rollo de sólido', 2, 995, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'consumibles', 'Tanque de CO2', 3, 925, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'consumibles', 'Consumibles', 2, 550, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'consumibles', 'Kit de limpieza', 1, 750, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'otros', 'Perno rey Holland', 1, 1200, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'otros', 'Tanque para aire', 2, 1050, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'otros', 'Pistón', 1, 55825, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'otros', 'Lodera blanca', 2, 303.99, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'otros', 'Flejes', 2, 232, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_2e_id, 'tornilleria', 'Kit de tornillería para gancho', 1, 49, 'fija', 'Factura Leolca (hoja A-36 con gancho Holland)', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'luz', 'Kit de luz', 1, 8500, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'pintura', 'Praimer', 1, 10000, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'tornilleria', 'Kit de tornillería para patines', 44, 15, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'tornilleria', 'Tornillería para loderas', 8, 5, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'consumibles', 'Rollo de micro tubular', 3, 995, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'consumibles', 'Rollo de sólido', 2, 995, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'consumibles', 'Tanque de CO2', 3, 925, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'consumibles', 'Consumibles', 2, 550, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'consumibles', 'Kit de limpieza', 1, 750, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'otros', 'Perno rey Holland', 1, 1200, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'otros', 'Tanque para aire', 2, 1050, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'otros', 'Pistón', 1, 55825, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'otros', 'Lodera blanca', 2, 303.99, 'fija', 'Factura Leolca', 'import-2r1f');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_3e_id, 'otros', 'Flejes', 2, 232, 'fija', 'Factura Leolca', 'import-2r1f');

    -- Validación de costos_modelo (2 ejes: 89,045.98; 3 ejes: 88,996.98)
    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits_2e
    FROM costos_modelo
    WHERE modelo_id = v_model_2e_id AND notas = 'import-2r1f';
    IF v_sum_kits_2e <> 89045.98 THEN
        RAISE EXCEPTION 'Los costos_modelo de góndola 2 ejes no suman 89,045.98 (suma actual: %)', v_sum_kits_2e;
    END IF;

    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits_3e
    FROM costos_modelo
    WHERE modelo_id = v_model_3e_id AND notas = 'import-2r1f';
    IF v_sum_kits_3e <> 88996.98 THEN
        RAISE EXCEPTION 'Los costos_modelo de góndola 3 ejes no suman 88,996.98 (suma actual: %)', v_sum_kits_3e;
    END IF;

    -- 7. Inserción de opcion_costos para Góndola
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'fleet_master' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'fleet_master'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 23118, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 23118, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'hendrickson' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'hendrickson'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 35844, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'alta_hendrickson' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'alta_hendrickson'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 46783.62, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'phm' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'phm'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 30000, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'eje' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'eje', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 21692, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'eje' AND oc.clave = 'fleet_master' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'eje', 'fleet_master'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'por_eje', 19905.6, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 2, 'fija', 5916, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'hj' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'hj'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 2, 'fija', 5646.88, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'holland' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'holland'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 2, 'fija', 17980, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'holland_8_10' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'holland_8_10'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 6844, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'premier_8' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'premier_8'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 11890, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'premier_bestia_6' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'premier_bestia_6'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 28040.98, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_sin_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_sin_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 22000, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_1_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_1_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 26700, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '3e_1_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '3e_1_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 27200, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '3e_2_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '3e_2_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 30500, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'paleta' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'retractil', 'paleta'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 1, 'fija', 15000, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'acero' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'acero'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 1550, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'aluminio' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'aluminio'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 5500, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'chinas' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'chinas'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 3000, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'firestone' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'firestone'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 8700, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'amulet' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'amulet'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'gondola', 4, 'por_eje', 4225, 'Factura Leolca', 'import-2r1f')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

END $$;

DROP FUNCTION IF EXISTS pg_temp.resolver_o_crear_material_gondola(uuid, text, numeric, text);

COMMIT;
