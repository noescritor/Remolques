-- Migración 20261014_01_dolly.sql
-- Generada automáticamente por scripts/generar_costos_dolly_sql.cjs
-- Sub-bloque 2R-1e: Modelo, acero, kits, mano de obra y costos de opciones del Dolly
-- Idempotente, ejecutable en una sola transacción.

BEGIN;

-- Función temporal de sesión para resolver o crear materiales deterministas
CREATE OR REPLACE FUNCTION pg_temp.resolver_o_crear_material_dolly(
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
BEGIN
    SELECT id, costo INTO v_exist_id, v_exist_costo
    FROM productos
    WHERE nombre = p_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'
    LIMIT 1;

    IF v_exist_id IS NOT NULL THEN
        IF v_exist_costo = p_costo THEN
            RETURN v_exist_id;
        ELSE
            v_final_nombre := p_nombre || ' (DOLLY)';
            SELECT id INTO v_res_id
            FROM productos
            WHERE nombre = v_final_nombre AND organizacion_id = p_org_id AND tipo_item = 'materia_prima'
            LIMIT 1;
            IF v_res_id IS NOT NULL THEN
                RETURN v_res_id;
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
    v_prod_id text;
    v_model_id uuid;
    v_mat_id text;
    v_opt_id uuid;
    v_count int;
    v_sum_acero numeric;
    v_sum_kits numeric;
    v_sum_mo numeric;
BEGIN

    -- 1. Producto terminado y modelo Dolly 2 ejes
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'DOLLY 2 EJES', 'bien', 'producto_terminado', 'PZA', 0, 0, 'Dolly 2 ejes', v_org_id
    WHERE NOT EXISTS (
        SELECT 1 FROM productos
        WHERE nombre = 'DOLLY 2 EJES' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado'
    );

    SELECT id INTO v_prod_id FROM productos WHERE nombre = 'DOLLY 2 EJES' AND organizacion_id = v_org_id AND tipo_item = 'producto_terminado' LIMIT 1;
    IF v_prod_id IS NULL THEN RAISE EXCEPTION 'Producto terminado DOLLY 2 EJES no encontrado'; END IF;

    INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
    VALUES (v_org_id, v_prod_id, 'dolly', NULL, 2)
    ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET
        tipo = EXCLUDED.tipo,
        largo_ft = EXCLUDED.largo_ft,
        num_ejes = EXCLUDED.num_ejes;

    SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'dolly' AND organizacion_id = v_org_id;
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo dolly, pero se encontraron %', v_count;
    END IF;
    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'dolly' AND organizacion_id = v_org_id;

    -- 2. Limpieza previa idempotente para import-2r1e
    DELETE FROM receta_base WHERE modelo_id = v_model_id AND notas = 'import-2r1e';
    DELETE FROM costos_modelo WHERE modelo_id = v_model_id AND notas = 'import-2r1e';
    DELETE FROM opcion_costos WHERE tipo_modelo = 'dolly' AND (notas = 'import-2r1e' OR fuente = 'Factura Leolca');
    DELETE FROM procesos_manufactura WHERE modelo_id = v_model_id AND notas = 'import-2r1e';

    -- 3. Inserción de materiales de acero y receta_base sección acero
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'PAQUETE CUERPO CHASIS DOLLY (PUENTES J, C, Z, ALMA, SOLERAS SUPERIOR E INFERIOR)', 14800, 'PAQUETE');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Paquete cuerpo chasis dolly', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'ATIZADOR (SOLERA DE GRADO A-36 DE 3/8" X 2" A 14,2CM)', 22.5, 'Solera de grado A-36 de 3/8" X 2" a 14,2cm');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', NULL, 'Atizador', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'ATIZADOR (SOLERA DE GRADO A-36 DE 1/2" X 3" A 14,2CM)', 43.6, 'Solera de grado A-36 de 1/2" X 3" a 14,2cm');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Atizador', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA PORTA LODERAS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 41.5, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Base para porta loderas', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA VALVULA DE ABS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 38, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para Valvula de ABS', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 20, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para Foco de ABS', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'TAPA PARA PUENTE C (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 130, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Tapa para puente C', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 891, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para la Quinta', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'PALOMA PARA CHASIS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 73, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Paloma para chasis', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'MEDIA LUNA PARA CADENA (PLACA DE GRADO A-36 CAL. 1/2" (12,7MM))', 40, 'Placa de grado A-36 Cal. 1/2" (12,7mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Media luna para cadena', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA VALVULAS PONCHADORAS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 34, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para Valvulas ponchadoras', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA PERCHA (SOLERA DE GRADO A-36 DE 1/2" X 6" A 30CM)', 182.6, 'Solera de grado A-36 de 1/2" X 6" a 30cm');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Base para percha', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA PLATO (SOLERA DE GRADO A-36 DE 1/2" X 4" A 20CM)', 150, 'Solera de grado A-36 de 1/2" X 4" a 20cm');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Base para plato', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BASE PARA PLATO CORRIDA (SOLERA DE GRADO A-36 DE 1/2" X 4" A 95,5CM)', 280, 'Solera de grado A-36 de 1/2" X 4" a 95,5cm');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para plato corrida', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'HERRAJE TRANSVERSAL (PLACA DE GRADO A-36 CAL. 3/16" (4,76MM))', 66.85, 'Placa de grado A-36 Cal. 3/16" (4,76mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Herraje transversal', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'HERRAJE A 1,10M (PLACA DE GRADO A-36 CAL. 3/16" (4,76MM))', 175, 'Placa de grado A-36 Cal. 3/16" (4,76mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Herraje a 1,10m', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'PTR PARA BISAGRA (PTR DE 4" X 2" EN CAL. ROJO)', 108, 'PTR de 4" X 2" en Cal. Rojo');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'PTR para bisagra', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'LANZA POSTERIOR 1,25M (PTR DE 3" X 3" EN CAL. VERDE)', 355, 'PTR de 3" X 3" en Cal. Verde');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Lanza posterior 1,25m', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'LANZA LATERAL 1,10 M (PTR DE 3" X 3" EN CAL. VERDE)', 312, 'PTR de 3" X 3" en Cal. Verde');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Lanza lateral 1,10 m', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'TRAVESAÑO 1, 45CM (PTR DE 3" X 3" EN CAL. VERDE)', 128, 'PTR de 3" X 3" en Cal. Verde');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Travesaño 1, 45cm', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'TRAVESAÑO 2, 41,5CM (PTR DE 3" X 3" EN CAL. VERDE)', 120, 'PTR de 3" X 3" en Cal. Verde');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Travesaño 2, 41,5cm', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'PLACA LATERAL DE DONA (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 24, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Placa lateral de dona', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'DORITOS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 42, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Doritos', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'TAPAS PARA LANZA (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 1750, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Tapas para lanza', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'BUCHACA (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 45.5, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Buchaca', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'U PARA CADENA', 300, 'U para cadena');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'U para cadena', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'CADENA', 500, 'Cadena');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Cadena', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'KIT DE TORNILLERIA', 226, 'Kit de tornilleria');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Kit de tornilleria', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'PLACA PARA PORTA LODERAS (PLACA DE GRADO A-36 CAL. 1/4" (6,35MM))', 200, 'Placa de grado A-36 Cal. 1/4" (6,35mm)');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Placa para porta loderas', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'ANGULO LARGUERO 1,77M (ANGULO 1 1/2" X 1/8")', 2160, 'Angulo 1 1/2" X 1/8"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Angulo larguero 1,77m', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'ANGULOS LATERALES 45CM (ANGULO 1 1/2" X 1/8")', 46, 'Angulo 1 1/2" X 1/8"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Angulos laterales 45cm', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'SOLERAS LATERALES 1,40M (SOLERA 3/16" X 1 1/2")', 100, 'Solera 3/16" X 1 1/2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Soleras laterales 1,40m', 'acero', NULL, 'import-2r1e');
    v_mat_id := pg_temp.resolver_o_crear_material_dolly(v_org_id, 'SOLERA CENTRAL 42CM (SOLERA 3/16" X 1 1/2")', 28, 'Solera 3/16" X 1 1/2"');
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Solera central 42cm', 'acero', NULL, 'import-2r1e');

    -- Validación de suma de acero (debe ser exactamente 27,018.80)
    SELECT round(coalesce(sum(rb.cantidad * p.costo), 0), 2) INTO v_sum_acero
    FROM receta_base rb
    JOIN productos p ON rb.material_id = p.id
    WHERE rb.modelo_id = v_model_id AND rb.seccion = 'acero' AND rb.notas = 'import-2r1e';
    IF v_sum_acero <> 27018.80 THEN
        RAISE EXCEPTION 'El acero del dolly no suma 27,018.80 (suma actual: %)', v_sum_acero;
    END IF;

    -- 4. Inserción de costos_modelo (kits y consumibles fijos: 18 conceptos)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Gata de izaje', 1, 433, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Bisagra', 2, 1041, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Oreja', 2, 843, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Perno de Dona', 2, 421.08, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Buje cónico', 4, 160, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Lodera blanca', 2, 303.99, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Flejes', 2, 232, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'tornilleria', 'Tornillería para loderas', 8, 5, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'luz', 'Kit de luz', 1, 4500, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Rollo de micro tubular', 2, 995, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Tanque de CO2', 1, 925, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Consumibles', 0.5, 550, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Kit de limpieza', 1, 400, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'pintura', 'Praimer', 4, 285, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'pintura', 'Pintura color estándar', 4, 640, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Tanque para aire', 1, 904, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Kit de rotulación', 1, 400, 'fija', 'Factura Leolca', 'import-2r1e');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Cinta reflejante', 1, 200, 'fija', 'Factura Leolca', 'import-2r1e');

    -- Validación de suma de costos_modelo (debe ser exactamente 20,089.14)
    SELECT round(coalesce(sum(cantidad * costo_unitario), 0), 2) INTO v_sum_kits
    FROM costos_modelo
    WHERE modelo_id = v_model_id AND notas = 'import-2r1e';
    IF v_sum_kits <> 20089.14 THEN
        RAISE EXCEPTION 'Los costos_modelo del dolly no suman 20,089.14 (suma actual: %)', v_sum_kits;
    END IF;

    -- 5. Inserción de procesos_manufactura (43 renglones de mano de obra)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 4, 'Atizador', NULL, 100, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 5, 'Base para porta loderas', NULL, 10, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 6, 'Base para Valvula de ABS', NULL, 5, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 7, 'Base para Foco de ABS', NULL, 5, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 8, 'Tapa para puente C', NULL, 5, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 9, 'Tapa para puente C', NULL, 5, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 10, 'Base para la Quinta', NULL, 20, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 11, 'Paloma para chasis', NULL, 16, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 12, 'Media luna para cadena', NULL, 16, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 13, 'Base para Valvulas ponchadoras', NULL, 8, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 14, 'Base para Valvulas ponchadoras', NULL, 5, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 15, 'Base para percha', NULL, 48, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 16, 'Base para plato', NULL, 10, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 17, 'Base para plato corrida', NULL, 12, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 18, 'Herraje transversal', NULL, 12, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 19, 'Herraje transversal', NULL, 16, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 20, 'Herraje a 1,10m', NULL, 8, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 21, 'Herraje a 1,10m', NULL, 11.52, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 22, 'PTR para bisagra', NULL, 36, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 23, 'Placa lateral de dona', NULL, 10, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 24, 'Doritos', NULL, 20, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 25, 'Tapas para lanza', NULL, 50, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 26, 'Buchaca', NULL, 5, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 27, 'Buchaca', NULL, 5, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 28, 'Placa para porta loderas', NULL, 25, 75, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 29, 'Angulo larguero 1,77m', NULL, 6, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 30, 'Angulos laterales 45cm', NULL, 10, 88.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 31, 'Soleras laterales 1,40m', NULL, 12, 89.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 32, 'Solera central 42cm', NULL, 5, 90.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 33, 'Ensamble', NULL, 2400, 125, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 34, 'Ensamble', NULL, 2400, 60, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 35, 'Escoreado y Lavado', NULL, 240, 55, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 36, 'Escoreado y Lavado', NULL, 240, 55, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 37, 'Escoreado y Lavado', NULL, 240, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 38, 'Praimer', NULL, 180, 55, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 39, 'Pintura', NULL, 300, 87.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 40, 'Aire', NULL, 480, 125, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 41, 'Luz', NULL, 240, 62.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 42, 'Enllantado', NULL, 90, 52.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 43, 'Enllantado', NULL, 90, 52.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 44, 'Colocacion de Quinta rueda', NULL, 90, 112.5, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 45, 'Colocacion de Quinta rueda', NULL, 90, 125, 'import-2r1e');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 46, 'MARCADO', NULL, 90, 87.5, 'import-2r1e');

    -- Validación de suma de procesos_manufactura (debe ser exactamente 11,249.90)
    SELECT round(coalesce(sum(minutos * tarifa_hora / 60.0), 0), 2) INTO v_sum_mo
    FROM procesos_manufactura
    WHERE modelo_id = v_model_id AND notas = 'import-2r1e';
    IF v_sum_mo <> 11249.90 THEN
        RAISE EXCEPTION 'La mano de obra del dolly no suma 11,249.90 (suma actual: %)', v_sum_mo;
    END IF;

    -- 6. Inserción de opcion_costos para Dolly (9 opciones catalogadas)
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'quinta' AND oc.clave = 'holland' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'quinta', 'holland'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 1, 'fija', 27375, 'Factura Leolca', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_sin_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_sin_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 1, 'fija', 20000, 'Factura Leolca', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_1_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_1_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 1, 'fija', 24700, 'Factura Leolca', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'retractil' AND oc.clave = 'paleta' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'retractil', 'paleta'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 1, 'fija', 8200, 'Factura Leolca', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'acero' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'acero'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 1550, 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'aluminio' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'aluminio'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 5500, 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'chinas' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'chinas'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 3000, 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'firestone' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'firestone'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 8700, 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'amulet' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'amulet'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'dolly', 4, 'por_eje', 4225, 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)', 'import-2r1e')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

END $$;

DROP FUNCTION IF EXISTS pg_temp.resolver_o_crear_material_dolly(uuid, text, numeric, text);

COMMIT;
