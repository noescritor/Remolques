BEGIN;

DO $$ 
DECLARE 
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_model_id uuid;
    v_group_id uuid;
    v_option_id uuid;
    v_mat_id uuid;
    v_count int;
    rec record;
BEGIN

-- 1. Asegurar que existan los 10 modelos de plataforma
SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'plataforma';
IF v_count != 10 THEN
    RAISE EXCEPTION 'Se esperaban 10 modelos de plataforma, pero se encontraron %', v_count;
END IF;

-- 2. Limpieza idempotente
DELETE FROM receta_base WHERE notas = 'import-2r1b';
DELETE FROM opcion_componentes WHERE notas = 'import-2r1b';

-- 3. Inserción de materiales faltantes
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CONSUMIBLE 65', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CONSUMIBLE 65' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO DE DESBASTE 9', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CO2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CO2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ROLLO DE MICRO ALAMBRE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO DE CORTE 7', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PERNO REY 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PERNO REY 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'OXIGENO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'OXIGENO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO LAMINADO 7', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO LAMINADO 7' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARGADORES 4X 102 IN', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ROLLO DE MICROALAMBRE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'SISTEMA RETRACTIL GRANDE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SISTEMA RETRACTIL GRANDE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'SISTEMA RETRACTIL CHICO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SISTEMA RETRACTIL CHICO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PIERNAS IZQUIERDA Y DERECHA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLATOS IZQUIERDO Y DERECHO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR HENDRICKSON 23743', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 23743' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR MONRROE 65512', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR MONRROE 65512' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS CENTRICAS HENDRICKSON', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS EXCENTRICAS HENDRICKSON', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL CON TORNILLO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS HENDRICKSON', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR HENDRICKSON 20126', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 20126' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL CON TORNILLO 7/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION FLET MASTER 8050', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FLET MASTER 8050' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION FCR 1R14-039', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FCR 1R14-039' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR FLET MASTER 323', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR FLET MASTER 323' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR FCR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR FCR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR GABRIEL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS FLET MASTER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS FLET MASTER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL HENDRICKSON 7/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION AMPRO 8050', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS AMPRO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS AMPRO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS CENTRICAS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS CENTRICAS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS EXCENTRICAS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO ALLEN 1/2X1 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO ALLEN 1/2X1 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/2 GRADO 5', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8X1 1/2 GRADO 5', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8X1 1/2 GRADO 5' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 5/8 GRADO 5', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 5/8 GRADO 5' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN AMPRO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN AMPRO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN HOLAND MARK V', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN HOLAND MARK V' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN HJ', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN HJ' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN FLET MASTER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN FLET MASTER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE FLET MASTER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE FLET MASTER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE AMPRO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE AMPRO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE FCR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE FCR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE PRAT MAX', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE PRAT MAX' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE HJ', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE HJ' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LIJA #80', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LIJA #80' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARDA 5/8 DE 3"', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO LAMINADO 4 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'FOSFATO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'FOSFATO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PINTURA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PINTURA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'THINER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'THINER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TRANSPARENTE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TRANSPARENTE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CATALIZADOR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CATALIZADOR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PRAIMER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PRAIMER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'THINER O REDUCTOR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'THINER O REDUCTOR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCTOR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCTOR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT ABS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT ABS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCCION 3/4 * 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCCION 3/4 * 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCCION 3/8 * 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCCION 3/8 * 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'NIPLE 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'NIPLE 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/4 SUSPENSION FM + 4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE UNIO 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE UNIO 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE LATERAL 3/8*1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE LATERAL 3/8*1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE CENTRO 3/8*1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE CENTRO 3/8*1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RECTA 3/8*1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RECTA 3/8*1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8*1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8*1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8*1/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8*1/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ADAPTADOR 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ADAPTADOR 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MACHO 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MACHO 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'HEMBRA 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HEMBRA 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT DE ABS 2 EJES BENDIX', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ABS 2 EJES BENDIX' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA PROTECTORA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA PROTECTORA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA NIVELADORA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA NIVELADORA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA PALANQUETA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA PALANQUETA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VARILLA NIVELADORA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VARILLA NIVELADORA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA RETRACTIL SEALCO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA RETRACTIL SEALCO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA AZUL C/LLAVE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA AZUL C/LLAVE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA ROJA C/LLAVE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA ROJA C/LLAVE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA AZUL S/LLAVE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA AZUL S/LLAVE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA ROJA S/LLAVE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA ROJA S/LLAVE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ESPARRAGO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESPARRAGO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TEFLON DE 13 METROS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TEFLON DE 13 METROS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'INCERTO 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'INCERTO 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'INCERTO 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'INCERTO 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA AZUL 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA AZUL 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA ROJA 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA ROJA 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA CHAMBER 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA CHAMBER 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/8 X 1 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/8 X 1 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/16 X 5 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/16 X 5 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 5/16', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 5/16' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 5/16', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/16' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TANQUE DE AIRE DE PLANA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TANQUE DE AIRE DE PLANA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO HOLLAND 10 BARRENOS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO HOLLAND 10 BARRENOS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO PREMIER 10 BARRENOS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO PREMIER 10 BARRENOS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO PREMIER BESTIA 6 BARRENOS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4X3 1/2 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4X 2 1/2 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA GRIPCO 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA AUTOMOTRIZ 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BOLSA RETRACTIL GRANDE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BOLSA RETRACTIL GRANDE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCAS DE SEGURIDAD 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BOLSA RETRACTIL CHICA UBL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/8 X 3/4 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS PLANAS 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ROSCA MILIMETRICA 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'HEMBRA 7 POLOS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HEMBRA 7 POLOS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/4X1 GALVANIZADO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE AZUL CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE AZUL CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE ROJO CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE ROJO CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE AMARILLO CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE VERDE CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE VERDE CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE CAFE CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE CAFE CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE NEGRO CAL,12', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 3/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 3/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TERMINAL 3/16', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TERMINAL 3/16' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TERMINAL 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TERMINAL 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REMACHE 3/16 X 5/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CINTA DE AISLAR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CINTA DE AISLAR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON ROJO 4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON ROJO 4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON ROJO 2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON ROJO 2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON AMBAR 2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON AMBAR 2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON AVALADO AMBAR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON DE CARRITO AMBAR', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON DE CARRITO ROJO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/8X 1 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LODERA BLANCA O NEGRA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'FLEJE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'FLEJE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 1/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TOPE DE HULE 3 BARRENOS', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/2 GALVANIZADA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'WINCHES', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'WINCHES' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/2X 1 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT DE ROTULACION', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ROTULACION' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CINTA REFLEJANTE', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CINTA REFLEJANTE' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLACA DE NIP', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLACA DE NIP' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CHAVETAS 3/16*2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CHAVETAS 3/16*2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ESLABONES DE CADENA 1/2', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8*3 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8*5 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4*6 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 3/4', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 5/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA AUTOMOTRIZ 5/8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4 X 6 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4 X 3 1/2 GRADO 8', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CANDADO PARA PLANA', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CANDADO PARA PLANA' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARGADO 3X102 IN', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARGADO 3X102 IN' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO FLET MASTER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO FLET MASTER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO ACURRAI', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO ACURRAI' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO AMPRO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO AMPRO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO FLET MASTER', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO AMPRO', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA K PATOS LINEAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA K PATOS LINEAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA K PATOS TRACCION', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA K PATOS TRACCION' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA FIRESTON LINEAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA FIRESTON LINEAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');
INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA GODSHIELD LINEAL', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA GODSHIELD LINEAL' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');

-- 4. Inserción de receta_base para TODOS los modelos de plataforma
FOR rec IN SELECT id FROM modelos WHERE tipo = 'plataforma' LOOP

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (rec.id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');
END LOOP;

-- 5. Inserción de opcion_componentes

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SISTEMA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: SISTEMA RETRACTIL GRANDE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SISTEMA RETRACTIL CHICO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: SISTEMA RETRACTIL CHICO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 23743' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR HENDRICKSON 23743'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR MONRROE 65512' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR MONRROE 65512'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL CON TORNILLO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 20126' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR HENDRICKSON 20126'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION HENDRICKSON R14-083-38'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL CON TORNILLO 7/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FLET MASTER 8050' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION FLET MASTER 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 1R14-039'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FCR 1R14-039' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION FCR 1R14-039'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR FLET MASTER 323' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR FLET MASTER 323'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR FCR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR FCR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS FLET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL HENDRICKSON 7/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO ALLEN 1/2X1 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO ALLEN 1/2X1 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1.5, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1.5, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8X1 1/2 GRADO 5' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8X1 1/2 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 22, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 5/8 GRADO 5' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 5/8 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 22, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'holland' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> holland'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN HOLAND MARK V' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN HOLAND MARK V'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hj' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> hj'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN HJ' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN HJ'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'flet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> flet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN FLET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE FLET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE FCR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE FCR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'prat_max' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> prat_max'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE PRAT MAX' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE PRAT MAX'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hj' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> hj'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE HJ' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE HJ'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 19, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 20, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TRANSPARENTE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TRANSPARENTE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER O REDUCTOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER O REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 16, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCTOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 15, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 7, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER O REDUCTOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER O REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 20, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCTOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 15, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT ABS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT ABS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCCION 3/4 * 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCCION 3/4 * 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCCION 3/8 * 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCCION 3/8 * 1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 3, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'NIPLE 1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: NIPLE 1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 3/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 3/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/4 SUSPENSION FM + 4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 3, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE UNIO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE UNIO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE LATERAL 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE LATERAL 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE CENTRO 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE CENTRO 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RECTA 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RECTA 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8*1/4' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 12, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8*1/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8*1/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ADAPTADOR 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ADAPTADOR 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MACHO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MACHO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ABS 2 EJES BENDIX' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ABS 2 EJES BENDIX'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA PROTECTORA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA PROTECTORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA NIVELADORA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA NIVELADORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA PALANQUETA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA PALANQUETA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VARILLA NIVELADORA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VARILLA NIVELADORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA RETRACTIL SEALCO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA RETRACTIL SEALCO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA AZUL C/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA AZUL C/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA ROJA C/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA ROJA C/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA AZUL S/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA AZUL S/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA ROJA S/LLAVE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA ROJA S/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESPARRAGO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESPARRAGO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TEFLON DE 13 METROS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TEFLON DE 13 METROS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'INCERTO 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: INCERTO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 38, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'INCERTO 1/2' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: INCERTO 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA AZUL 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA AZUL 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 30, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA ROJA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA ROJA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 13, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA CHAMBER 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA CHAMBER 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 1 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 1 GRADO 8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/16 X 5 GRADO 8' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/16 X 5 GRADO 8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/16' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/16'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TANQUE DE AIRE DE PLANA' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TANQUE DE AIRE DE PLANA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'holland_8_10' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> holland_8_10'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO HOLLAND 10 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO HOLLAND 10 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'premier_8' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> premier_8'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO PREMIER 10 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO PREMIER 10 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'premier_bestia_6' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> premier_bestia_6'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO PREMIER BESTIA 6 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL GRANDE' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL GRANDE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO FLET MASTER' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO ACURRAI' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO ACURRAI'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO AMPRO' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'kpatos_lineal' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> kpatos_lineal'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA K PATOS LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA K PATOS LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'kpatos_traccion' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> kpatos_traccion'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA K PATOS TRACCION' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA K PATOS TRACCION'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'firestone' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> firestone'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA FIRESTON LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA FIRESTON LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'godshield_lineal' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> godshield_lineal'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA GODSHIELD LINEAL' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA GODSHIELD LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

END $$;
COMMIT;
