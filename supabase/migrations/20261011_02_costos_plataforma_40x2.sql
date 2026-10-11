-- Migración 20261011_02_costos_plataforma_40x2.sql
-- Generada automáticamente por scripts/generar_costos_sql.cjs
-- Sub-bloque 2R-1c: Costos de la plataforma 40 ft / 2 ejes

BEGIN;

DO $$
DECLARE
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_model_id uuid;
    v_mat_id text;
    v_opt_id uuid;
    v_count int;
BEGIN

    -- 1. Resolver y validar modelo plataforma 40 ft / 2 ejes
    SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;
    IF v_count <> 1 THEN
        RAISE EXCEPTION 'Se esperaba exactamente 1 modelo plataforma 40 ft / 2 ejes, pero se encontraron %', v_count;
    END IF;
    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND largo_ft = 40 AND num_ejes = 2;

    -- 2. Limpieza idempotente previa para import-2r1c
    DELETE FROM receta_base WHERE notas = 'import-2r1c';
    DELETE FROM costos_modelo WHERE notas LIKE '%import-2r1c%' OR fuente = 'Factura Leolca';
    DELETE FROM opcion_costos WHERE notas = 'import-2r1c' OR fuente = 'Factura Leolca';
    DELETE FROM procesos_manufactura WHERE notas = 'import-2r1c';

    -- 3. Inserción de materiales de acero (61 piezas)
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 12500, 0, 'Placa de grado A-50 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")', 'bien', 'materia_prima', 'PZA', 7304, 0, 'Solera de grado A-529 a 1/2" X 6"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 2068, 0, 'Placa de grado A-36 Cal. 3/16"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 2500, 0, 'Placa de grado A-36 Cal. 3/16"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")', 'bien', 'materia_prima', 'PZA', 0, 0, 'SIN PRECIO', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")', 'bien', 'materia_prima', 'PZA', 5700, 0, 'Placa de grado A-36 Cal. 3/8"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 440, 0, 'Placa de grado A-36 Cal. 3/16"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PUENTES DE LA PLANCHA (CANAL U 5")', 'bien', 'materia_prima', 'PZA', 450, 0, 'Canal U 5"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PUENTES DE LA PLANCHA (CANAL U 5")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 40, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 35, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")', 'bien', 'materia_prima', 'PZA', 50, 0, 'Solera de grado A-36 a 3/8" x 2"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ATIZADORES EXTERNOS 29CM', 'bien', 'materia_prima', 'PZA', 60, 0, 'Atizadores externos', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ATIZADORES EXTERNOS 29CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'JALON (PLACA DE GRADO A-36 CAL. 1/2")', 'bien', 'materia_prima', 'PZA', 2500, 0, 'Placa de grado A-36 Cal. 1/2"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'JALON (PLACA DE GRADO A-36 CAL. 1/2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")', 'bien', 'materia_prima', 'PZA', 600, 0, 'Placa de grado A-36 Cal. 3/8"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PERNO REY (PERNO REY HOLLAND 3/8")', 'bien', 'materia_prima', 'PZA', 1200, 0, 'Perno rey Holland 3/8"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PERNO REY (PERNO REY HOLLAND 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TAPA PARA PERNO REY (CANAL U 6")', 'bien', 'materia_prima', 'PZA', 100, 0, 'Canal u 6"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPA PARA PERNO REY (CANAL U 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)', 'bien', 'materia_prima', 'PZA', 108.99, 0, 'Placa de grado A-36 Cal. 10', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 27 X 60 CM', 'bien', 'materia_prima', 'PZA', 130.99, 0, 'Kit de aletas', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 27 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 40 X 50 CM', 'bien', 'materia_prima', 'PZA', 161.99, 0, 'Kit de aletas', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 40 X 50 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 40 X 60 CM', 'bien', 'materia_prima', 'PZA', 193.99, 0, 'Kit de aletas', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 40 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 45 X 50 CM', 'bien', 'materia_prima', 'PZA', 181.99, 0, 'Kit de aletas', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 45 X 50 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'KIT DE ALETAS 45 X 60 CM', 'bien', 'materia_prima', 'PZA', 217.99, 0, 'Kit de aletas', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ALETAS 45 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 70, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 110, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 45.5, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)', 'bien', 'materia_prima', 'PZA', 12, 0, 'Tubo de 1 1/4" Ced. 40', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 65, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 170, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 130, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'CARGADOR (IPR DE 4")', 'bien', 'materia_prima', 'PZA', 576.82, 0, 'IPR DE 4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARGADOR (IPR DE 4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BORDAS LATERALES (CANAL U 6")', 'bien', 'materia_prima', 'PZA', 5870.35, 0, 'Canal U 6"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BORDAS LATERALES (CANAL U 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 77, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 52.6, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")', 'bien', 'materia_prima', 'PZA', 23.4, 0, 'Solera de grado A-36 a 3/8" x 2"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 101, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")', 'bien', 'materia_prima', 'PZA', 234, 0, 'Solera de grado A-36 a 1/2" x 6"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")', 'bien', 'materia_prima', 'PZA', 67, 0, 'Solera de grado A-36 a 1/2" x 3"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 64, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'GANCHOS (REDONDO DE 1/2")', 'bien', 'materia_prima', 'PZA', 6.3, 0, 'Redondo de 1/2"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHOS (REDONDO DE 1/2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 45, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")', 'bien', 'materia_prima', 'PZA', 300, 0, 'Placa de grado A-36 Cal. 3/8"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 60.6, 0, 'Placa de grado A-36 Cal. 3/16"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'U PARA JALON (REDONDO DE 1")', 'bien', 'materia_prima', 'PZA', 102, 0, 'Redondo de 1"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'U PARA JALON (REDONDO DE 1")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 25, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 30, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)', 'bien', 'materia_prima', 'PZA', 42.99, 0, 'Placa de grado A-36 Cal. 10', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")', 'bien', 'materia_prima', 'PZA', 1110, 0, 'Solera de grado A-36 a 3/8" x 2"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")', 'bien', 'materia_prima', 'PZA', 196.99, 0, 'Placa de grado A-36 Cal. 3/16"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 125CM', 'bien', 'materia_prima', 'PZA', 223.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 125CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 70CM', 'bien', 'materia_prima', 'PZA', 124.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 70CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 67CM', 'bien', 'materia_prima', 'PZA', 119.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 67CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 23CM', 'bien', 'materia_prima', 'PZA', 41.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 23CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")', 'bien', 'materia_prima', 'PZA', 23.99, 0, 'Solera de grado A-36 a 1/2" x 3"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 27CM', 'bien', 'materia_prima', 'PZA', 90.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 27CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES 30CM', 'bien', 'materia_prima', 'PZA', 100.99, 0, 'Heraje para patines', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES 30CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 40.99, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")', 'bien', 'materia_prima', 'PZA', 87.99, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2', 'bien', 'materia_prima', 'PZA', 275.99, 0, 'Placa de grado A-36 Cal. 1/4"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")', 'bien', 'materia_prima', 'PZA', 738.99, 0, 'Solera de grado A-36 a 1/2" x 3"', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'ESTRIBO (PTR DE 4X4" A 6.10M)', 'bien', 'materia_prima', 'PZA', 1050, 0, 'PTR de 4X4" a 6.10m', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESTRIBO (PTR DE 4X4" A 6.10M)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
    INSERT INTO productos (nombre, tipo, tipo_item, unidad, costo, precio_unitario, descripcion, organizacion_id)
    SELECT 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)', 'bien', 'materia_prima', 'PZA', 440, 0, 'Placa de grado A-36 Cal. 12', v_org_id
    WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');

    -- 4. Inserción de receta_base sección acero para plataforma 40/2
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ALMA (PLACA DE GRADO A-50 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Alma', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'SOLERA DE ALMA (SOLERA DE GRADO A-529 A 1/2" X 6")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Solera de alma', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BORDA DELANTERA (PLACA DE GRADO A-36 CAL. 3/16")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Borda delantera', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BORDA TRASERA (PLACA DE GRADO A-36 CAL. 3/16")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Borda trasera', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PUENTES DE SUSPENSIÓN (PTR A 2 X 6")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', NULL, 'Puentes de suspensión', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PLANCHA PARA LA QUINTA (PLACA DE GRADO A-36 CAL. 3/8")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Plancha para la quinta', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PUENTES TIPO J (PLACA DE GRADO A-36 CAL. 3/16")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 7, 'fija', NULL, 'Puentes tipo J', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PUENTES DE LA PLANCHA (CANAL U 5")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PUENTES DE LA PLANCHA (CANAL U 5")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Puentes de la plancha', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BOTONES (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', NULL, 'Botones', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ATIZADORES INTERNOS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', NULL, 'Atizadores internos', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ATIZADORES EXTERNOS 27 CM (SOLERA DE GRADO A-36 A 3/8" X 2")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', NULL, 'Atizadores externos', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ATIZADORES EXTERNOS 29CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ATIZADORES EXTERNOS 29CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Atizadores externos', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'JALON (PLACA DE GRADO A-36 CAL. 1/2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'JALON (PLACA DE GRADO A-36 CAL. 1/2")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Jalon', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'REFUERZO DE JALON (PLACA DE GRADO A-36 CAL. 3/8")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Refuerzo de jalon', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY (PERNO REY HOLLAND 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PERNO REY (PERNO REY HOLLAND 3/8")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Perno rey', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPA PARA PERNO REY (CANAL U 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'TAPA PARA PERNO REY (CANAL U 6")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Tapa para perno rey', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 27 X 50 CM (PLACA DE GRADO A-36 CAL. 10)'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 27 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 27 X 60 CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 40 X 50 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 40 X 50 CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 40 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 40 X 60 CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 45 X 50 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 45 X 50 CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ALETAS 45 X 60 CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'KIT DE ALETAS 45 X 60 CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Kit de aletas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ESQUINERO DELANTERO (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Esquinero delantero', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ESQUINERO TRASERO (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Esquinero trasero', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BUCHACAS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', NULL, 'Buchacas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'TUBOS LATERALES (TUBO DE 1 1/4" CED. 40)'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 42, 'fija', NULL, 'Tubos laterales', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA ESTRIBO PLACA TRASERA (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA ESTRIBO PLACA FRONTAL (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA ESTRIBO PLACA INTERMEDIA (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Base para estribo', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADOR (IPR DE 4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'CARGADOR (IPR DE 4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', NULL, 'Cargador', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BORDAS LATERALES (CANAL U 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BORDAS LATERALES (CANAL U 6")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Bordas laterales', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA TANQUES (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Base para tanques', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA PATINES PLACAS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA PATINES SOLERA (SOLERA DE GRADO A-36 A 3/8" X 2")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', NULL, 'Base para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA MANITAS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para manitas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA PERCHAS (SOLERA DE GRADO A-36 A 1/2" X 6")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Base para perchas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA PLATOS (SOLERA DE GRADO A-36 A 1/2" X 3")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Base para platos', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PESTAÑAS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Pestañas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHOS (REDONDO DE 1/2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'GANCHOS (REDONDO DE 1/2")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 32, 'fija', NULL, 'Ganchos', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PLAFONES OVALADOS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Plafones ovalados', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'CARTABONES PARA JALON (PLACA DE GRADO A-36 CAL. 3/8")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Cartabones para jalon', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'SOLERA PARA ESQUINEROS (PLACA DE GRADO A-36 CAL. 3/16")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Solera para esquineros', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'U PARA JALON (REDONDO DE 1")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'U PARA JALON (REDONDO DE 1")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'U para jalon', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA FOCO DE ABS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para foco de ABS', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'BASE PARA ABS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Base para ABS', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PORTA PLACAS (PLACA DE GRADO A-36 CAL. 10)'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Porta placas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'CINCHO (SOLERA DE GRADO A-36 A 3/8" X 2")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Cincho', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 110CM (PLACA DE GRADO A-36 CAL. 3/16")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 125CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 125CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 70CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 70CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 67CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 67CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 23CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 23CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 7CM (SOLERA DE GRADO A-36 A 1/2" X 3")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 27CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 27CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES 30CM' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES 30CM'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'HERAJE PARA PATINES BUCHACA (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Heraje para patines', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PORTA LLANTAS (PLACA DE GRADO A-36 CAL. 1/4") #2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PORTA LLANTAS (SOLERA DE GRADO A-36 A 1/2" X 3")'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Porta Llantas', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESTRIBO (PTR DE 4X4" A 6.10M)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'ESTRIBO (PTR DE 4X4" A 6.10M)'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', NULL, 'Estribo', 'acero', NULL, 'import-2r1c');
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: %', 'PORTA LODERAS (PLACA DE GRADO A-36 CAL. 12)'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, seccion, condicion, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', NULL, 'Porta loderas', 'acero', NULL, 'import-2r1c');

    -- 5. Inserción de costos_modelo (kits y consumibles fijos)
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Tope de goma', 2, 82, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Lodera blanca', 2, 303.99, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Flejes', 2, 232, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'tornilleria', 'Tornillería para loderas', 8, 5, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'otros', 'Banderolas', 2, 400, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'luz', 'Kit de luz', 1, 15000, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Rollo de micro tubular', 3, 995, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Tanque de CO2', 3, 925, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Consumibles', 1, 550, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'consumibles', 'Kit de limpieza', 1, 300, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'pintura', 'Praimer', 1, 10000, 'fija', 'Factura Leolca', 'import-2r1c');
    INSERT INTO costos_modelo (organizacion_id, modelo_id, seccion, concepto, cantidad, costo_unitario, escala, fuente, notas)
    VALUES (v_org_id, v_model_id, 'pintura', 'Pintura color estándar', 1, 12000, 'fija', 'Factura Leolca', ' 1 1/2 Cubeta; import-2r1c');

    -- 6. Inserción de opcion_costos (22 opciones mapeadas)
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'fleet_master' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'fleet_master'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 23118, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 23118, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'hendrickson' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'hendrickson'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 35844, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'suspension' AND oc.clave = 'alta_hendrickson' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'suspension', 'alta_hendrickson'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 46783.62, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'eje' AND oc.clave = 'fleet_master' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'eje', 'fleet_master'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 19905.6, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'eje' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'eje', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'por_eje', 21692, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'hj' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'hj'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 2, 'fija', 5646.88, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'ampro' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'ampro'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 2, 'fija', 5916, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'patin' AND oc.clave = 'holland' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'patin', 'holland'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 2, 'fija', 17980, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'holland_8_10' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'holland_8_10'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 6844, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'premier_8' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'premier_8'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 11890, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'gancho' AND oc.clave = 'premier_bestia_6' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'gancho', 'premier_bestia_6'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 28040.98, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_sin_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_sin_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 20000, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '2e_1_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '2e_1_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 24700, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'abs' AND oc.clave = '3e_2_retractil' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'abs', '3e_2_retractil'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 28500, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'acero' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'acero'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 1550, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'rines' AND oc.clave = 'aluminio' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'rines', 'aluminio'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 5500, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'chinas' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'chinas'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 3000, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'firestone' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'firestone'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 8700, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'llantas' AND oc.clave = 'amulet' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'llantas', 'amulet'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 4, 'por_eje', 4225, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'laminado_madera' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'laminado_madera'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 39060, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;
    SELECT oc.id INTO v_opt_id FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso' AND oc.clave = 'laminado_plastico' AND oc.organizacion_id = v_org_id LIMIT 1;
    IF v_opt_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: % / %', 'piso', 'laminado_plastico'; END IF;
    INSERT INTO opcion_costos (organizacion_id, opcion_id, tipo_modelo, cantidad_base, escala, costo_unitario, fuente, notas)
    VALUES (v_org_id, v_opt_id, 'plataforma', 1, 'fija', 52060, 'Factura Leolca', 'import-2r1c')
    ON CONFLICT (opcion_id, tipo_modelo) DO UPDATE SET
        cantidad_base = EXCLUDED.cantidad_base, escala = EXCLUDED.escala, costo_unitario = EXCLUDED.costo_unitario, fuente = EXCLUDED.fuente, notas = EXCLUDED.notas;

    -- 7. Inserción de procesos_manufactura (80 renglones mano de obra)
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 5, 'Proceso 1', NULL, 720, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 6, 'Proceso 2', NULL, 480, 100, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 7, 'Proceso 3', NULL, 720, 100, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 8, 'Proceso 4', NULL, 480, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 9, 'Proceso 4', NULL, 480, 82.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 10, 'Proceso 5', NULL, 960, 45, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 11, 'Proceso 5', NULL, 960, 57.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 12, 'Proceso 6', NULL, 960, 50, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 13, 'Proceso 6', NULL, 960, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 14, 'Encargado de procedimiento', NULL, 720, 125, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 15, 'Escoreado y lavado', NULL, 600, 55, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 16, 'Escoreado y lavado', NULL, 600, 55, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 17, 'Escoreado y lavado', NULL, 600, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 18, 'Praimer', NULL, 300, 55, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 19, 'Pintura', NULL, 600, 87.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 20, 'Aire', NULL, 600, 125, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 21, 'Luz', NULL, 360, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 22, 'Piso', NULL, 480, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 23, 'Piso', NULL, 480, 52.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 24, 'Enllantado', NULL, 160, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 25, 'Enllantado', NULL, 160, 52.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 26, 'Rotulado', NULL, 90, 112.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 27, 'Marcado', NULL, 90, 87.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 28, 'Encargado de procedimiento', NULL, 720, 112.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 29, 'Borda delantera', NULL, 30, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 30, 'Borda delantera', NULL, 30, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 31, 'Borda trasera', NULL, 30, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 32, 'Borda trasera', NULL, 30, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 33, 'Puentes de suspensión', NULL, 20, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 34, 'Plancha para la quinta', NULL, 30, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 35, 'Plancha para la quinta', NULL, 30, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 36, 'Puentes intermedios', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 37, 'Puentes de la plancha', NULL, 20, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 38, 'Botones', NULL, 80, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 39, 'Atizadores', NULL, 50, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 40, 'Atizadores', NULL, 60, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 41, 'Jalon', NULL, 60, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 42, 'Jalon', NULL, 60, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 43, 'Refuerzo de Jalon', NULL, 30, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 44, 'Refuerzo de Jalon', NULL, 30, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 45, 'Kit de Aletas', NULL, 120, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 46, 'Kit de Aletas', NULL, 60, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 47, 'Esquinero delantero', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 48, 'Esquinero trasero', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 49, 'Buchacas', NULL, 240, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 50, 'Buchacas', NULL, 240, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 51, 'Tubos laterales', NULL, 210, 42.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 52, 'Base para estribo', NULL, 25, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 53, 'Base para estribo', NULL, 10, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 54, 'Cargadores', NULL, 570, 42.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 55, 'Base para tanque', NULL, 15, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 56, 'Base para tanque', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 57, 'Base para patines', NULL, 120, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 58, 'Base para patines', NULL, 80, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 59, 'Base para patines', NULL, 80, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 60, 'Base para manitas', NULL, 20, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 61, 'Base para perchas', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 62, 'Base para platos', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 63, 'Pestañas', NULL, 15, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 64, 'Pestañas', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 65, 'Ganchos', NULL, 300, 42.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 66, 'Plafones ovalados', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 67, 'Cartabones para jalon', NULL, 20, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 68, 'Cartabones para jalon', NULL, 15, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 69, 'U para Jalon', NULL, 30, 42.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 70, 'Base para Foco de ABS', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 71, 'Base para ABS', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 72, 'Porta placas', NULL, 15, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 73, 'Porta placas', NULL, 10, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 74, 'Herraje para patines', NULL, 90, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 75, 'Herraje para patines', NULL, 70, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 76, 'Porta Llantas', NULL, 75, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 77, 'Porta Llantas', NULL, 10, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 78, 'Porta Llantas', NULL, 5, 42.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 79, 'Estribo', NULL, 60, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 80, 'Porta Loderas', NULL, 80, 62.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 81, 'Porta Loderas', NULL, 15, 75, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 82, 'Gerencia', NULL, 720, 250, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 83, 'Revicion Final', NULL, 90, 87.5, 'import-2r1c');
    INSERT INTO procesos_manufactura (organizacion_id, modelo_id, orden, proceso, subproceso, minutos, tarifa_hora, notas)
    VALUES (v_org_id, v_model_id, 84, 'Revicion Final', NULL, 60, 50, 'import-2r1c');

    -- 8. Parámetros de costeo (ganancia_factura)
    INSERT INTO parametros_costeo (organizacion_id, clave, valor)
    VALUES (v_org_id, 'ganancia_factura', '{"plataforma":110000,"dolly":65000,"gondola_servicios_sueldos":100000}'::jsonb)
    ON CONFLICT (organizacion_id, clave) DO UPDATE SET valor = EXCLUDED.valor;

END $$;

COMMIT;
