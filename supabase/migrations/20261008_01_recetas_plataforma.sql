BEGIN;

DO $$ 
DECLARE 
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_model_id uuid;
    v_group_id uuid;
    v_option_id uuid;
    v_mat_id text;
BEGIN

-- 1. Asegurar que existan los 10 modelos de plataforma y validar
FOR largo, ejes IN VALUES 
    (35, 2), (40, 2), (40, 3), (42, 2), (42, 3), 
    (43, 2), (43, 3), (45, 2), (48, 2), (48, 3) 
LOOP
    IF NOT EXISTS (SELECT 1 FROM modelos WHERE tipo = 'plataforma' AND num_ejes = ejes AND largo_ft = largo) THEN
        RAISE EXCEPTION 'Modelo PLATAFORMA % % FT no encontrado', ejes, largo;
    END IF;
END LOOP;

-- 2. Limpieza idempotente
DELETE FROM receta_base WHERE notas = 'import-2r1b';
DELETE FROM opcion_componentes WHERE notas = 'import-2r1b';

-- 3. Inserción de materiales faltantes
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CONSUMIBLE 65', 'CONSUMIBLE 65', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CONSUMIBLE 65');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO DE DESBASTE 9', 'DISCO DE DESBASTE 9', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO DE DESBASTE 9');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CO2', 'CO2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CO2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ROLLO DE MICRO ALAMBRE', 'ROLLO DE MICRO ALAMBRE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO DE CORTE 7', 'DISCO DE CORTE 7', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO DE CORTE 7');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PERNO REY 3/8', 'PERNO REY 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PERNO REY 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'OXIGENO', 'OXIGENO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'OXIGENO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO LAMINADO 7', 'DISCO LAMINADO 7', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO LAMINADO 7');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARGADORES 4X 102 IN', 'CARGADORES 4X 102 IN', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARGADORES 4X 102 IN');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ROLLO DE MICROALAMBRE', 'ROLLO DE MICROALAMBRE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'SISTEMA RETRACTIL GRANDE', 'SISTEMA RETRACTIL GRANDE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SISTEMA RETRACTIL GRANDE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'SISTEMA RETRACTIL CHICO', 'SISTEMA RETRACTIL CHICO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'SISTEMA RETRACTIL CHICO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PIERNAS IZQUIERDA Y DERECHA', 'PIERNAS IZQUIERDA Y DERECHA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLATOS IZQUIERDO Y DERECHO', 'PLATOS IZQUIERDO Y DERECHO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR HENDRICKSON 23743', 'AMORTIGUADOR HENDRICKSON 23743', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 23743');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR MONRROE 65512', 'AMORTIGUADOR MONRROE 65512', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR MONRROE 65512');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS CENTRICAS HENDRICKSON', 'RONDANAS CENTRICAS HENDRICKSON', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS EXCENTRICAS HENDRICKSON', 'RONDANAS EXCENTRICAS HENDRICKSON', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL CON TORNILLO', 'BUJE TRIFUNCIONAL CON TORNILLO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS HENDRICKSON', 'ABRAZADERAS HENDRICKSON', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR HENDRICKSON 20126', 'AMORTIGUADOR HENDRICKSON 20126', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 20126');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL CON TORNILLO 7/8', 'BUJE TRIFUNCIONAL CON TORNILLO 7/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION FLET MASTER 8050', 'CAMARA DE SUSPENSION FLET MASTER 8050', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FLET MASTER 8050');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'CAMARA DE SUSPENSION AMPRO 1R14-039', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION FCR 1R14-039', 'CAMARA DE SUSPENSION FCR 1R14-039', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FCR 1R14-039');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR FLET MASTER 323', 'AMORTIGUADOR FLET MASTER 323', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR FLET MASTER 323');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR FCR', 'AMORTIGUADOR FCR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR FCR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'AMORTIGUADOR GABRIEL', 'AMORTIGUADOR GABRIEL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS FLET MASTER', 'ABRAZADERAS FLET MASTER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS FLET MASTER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL HENDRICKSON 7/8', 'BUJE TRIFUNCIONAL HENDRICKSON 7/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CAMARA DE SUSPENSION AMPRO 8050', 'CAMARA DE SUSPENSION AMPRO 8050', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ABRAZADERAS AMPRO', 'ABRAZADERAS AMPRO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ABRAZADERAS AMPRO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS CENTRICAS', 'RONDANAS CENTRICAS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS CENTRICAS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS EXCENTRICAS', 'RONDANAS EXCENTRICAS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BUJE TRIFUNCIONAL', 'BUJE TRIFUNCIONAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO ALLEN 1/2X1 1/2', 'TORNILLO ALLEN 1/2X1 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO ALLEN 1/2X1 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/2 GRADO 5', 'TUERCA ESTANDAR 1/2 GRADO 5', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8X1 1/2 GRADO 5', 'TORNILLO 5/8X1 1/2 GRADO 5', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8X1 1/2 GRADO 5');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 5/8 GRADO 5', 'TUERCA ESTANDAR 5/8 GRADO 5', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 5/8 GRADO 5');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN AMPRO', 'PATIN AMPRO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN AMPRO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN HOLAND MARK V', 'PATIN HOLAND MARK V', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN HOLAND MARK V');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN HJ', 'PATIN HJ', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN HJ');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PATIN FLET MASTER', 'PATIN FLET MASTER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PATIN FLET MASTER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE FLET MASTER', 'EJE FLET MASTER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE FLET MASTER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE AMPRO', 'EJE AMPRO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE AMPRO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE FCR', 'EJE FCR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE FCR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE PRAT MAX', 'EJE PRAT MAX', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE PRAT MAX');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'EJE HJ', 'EJE HJ', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'EJE HJ');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LIJA #80', 'LIJA #80', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LIJA #80');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARDA 5/8 DE 3"', 'CARDA 5/8 DE 3"', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARDA 5/8 DE 3"');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'DISCO LAMINADO 4 1/2', 'DISCO LAMINADO 4 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'FOSFATO', 'FOSFATO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'FOSFATO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PINTURA', 'PINTURA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PINTURA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'THINER', 'THINER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'THINER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TRANSPARENTE', 'TRANSPARENTE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TRANSPARENTE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CATALIZADOR', 'CATALIZADOR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CATALIZADOR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PRAIMER', 'PRAIMER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PRAIMER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'THINER O REDUCTOR', 'THINER O REDUCTOR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'THINER O REDUCTOR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCTOR', 'REDUCTOR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCTOR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT ABS', 'KIT ABS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT ABS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCCION 3/4 * 1/2', 'REDUCCION 3/4 * 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCCION 3/4 * 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REDUCCION 3/8 * 1/4', 'REDUCCION 3/8 * 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REDUCCION 3/8 * 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'NIPLE 1/4', 'NIPLE 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'NIPLE 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 3/4', 'TAPON 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/2', 'TAPON 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/4 SUSPENSION FM + 4', 'TAPON 1/4 SUSPENSION FM + 4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TAPON 1/8', 'TAPON 1/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TAPON 1/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE UNIO 3/8', 'TE UNIO 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE UNIO 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE LATERAL 3/8*1/4', 'TE LATERAL 3/8*1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE LATERAL 3/8*1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TE CENTRO 3/8*1/4', 'TE CENTRO 3/8*1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TE CENTRO 3/8*1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RECTA 3/8*1/4', 'RECTA 3/8*1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RECTA 3/8*1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8*1/4', 'CODO 3/8*1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8*1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8*1/8', 'CODO 3/8*1/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8*1/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 3/8', 'CODO 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CODO 1/2', 'CODO 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CODO 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ADAPTADOR 3/8', 'ADAPTADOR 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ADAPTADOR 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MACHO 3/8', 'MACHO 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MACHO 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'HEMBRA 3/8', 'HEMBRA 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HEMBRA 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT DE ABS 2 EJES BENDIX', 'KIT DE ABS 2 EJES BENDIX', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ABS 2 EJES BENDIX');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA PROTECTORA', 'VALVULA PROTECTORA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA PROTECTORA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA NIVELADORA', 'VALVULA NIVELADORA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA NIVELADORA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA PALANQUETA', 'VALVULA PALANQUETA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA PALANQUETA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VARILLA NIVELADORA', 'VARILLA NIVELADORA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VARILLA NIVELADORA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'VALVULA RETRACTIL SEALCO', 'VALVULA RETRACTIL SEALCO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'VALVULA RETRACTIL SEALCO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA AZUL C/LLAVE', 'MANITA AZUL C/LLAVE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA AZUL C/LLAVE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA ROJA C/LLAVE', 'MANITA ROJA C/LLAVE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA ROJA C/LLAVE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA AZUL S/LLAVE', 'MANITA AZUL S/LLAVE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA AZUL S/LLAVE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANITA ROJA S/LLAVE', 'MANITA ROJA S/LLAVE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANITA ROJA S/LLAVE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ESPARRAGO', 'ESPARRAGO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESPARRAGO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TEFLON DE 13 METROS', 'TEFLON DE 13 METROS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TEFLON DE 13 METROS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'INCERTO 3/8', 'INCERTO 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'INCERTO 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'INCERTO 1/2', 'INCERTO 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'INCERTO 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA AZUL 3/8', 'MANGUERA AZUL 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA AZUL 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA ROJA 3/8', 'MANGUERA ROJA 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA ROJA 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'MANGUERA CHAMBER 3/8', 'MANGUERA CHAMBER 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'MANGUERA CHAMBER 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/8 X 1 GRADO 8', 'TORNILLO 3/8 X 1 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/8 X 1 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 3/8', 'RONDANA PLANA 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 3/8', 'TUERCA DE SEGURIDAD 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/16 X 5 GRADO 8', 'TORNILLO 5/16 X 5 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/16 X 5 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 5/16', 'RONDANA PLANA 5/16', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 5/16');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 5/16', 'TUERCA DE SEGURIDAD 5/16', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/16');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TANQUE DE AIRE DE PLANA', 'TANQUE DE AIRE DE PLANA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TANQUE DE AIRE DE PLANA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO HOLLAND 10 BARRENOS', 'GANCHO HOLLAND 10 BARRENOS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO HOLLAND 10 BARRENOS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO PREMIER 10 BARRENOS', 'GANCHO PREMIER 10 BARRENOS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO PREMIER 10 BARRENOS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'GANCHO PREMIER BESTIA 6 BARRENOS', 'GANCHO PREMIER BESTIA 6 BARRENOS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4X3 1/2 GRADO 8', 'TORNILLO 3/4X3 1/2 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4X 2 1/2 GRADO 8', 'TORNILLO 3/4X 2 1/2 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA GRIPCO 3/4', 'TUERCA GRIPCO 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA AUTOMOTRIZ 3/4', 'RONDANA AUTOMOTRIZ 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BOLSA RETRACTIL GRANDE', 'BOLSA RETRACTIL GRANDE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BOLSA RETRACTIL GRANDE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCAS DE SEGURIDAD 1/2', 'TUERCAS DE SEGURIDAD 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'BOLSA RETRACTIL CHICA UBL', 'BOLSA RETRACTIL CHICA UBL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/8 X 3/4 GRADO 8', 'TORNILLO 3/8 X 3/4 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANAS PLANAS 3/8', 'RONDANAS PLANAS 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ROSCA MILIMETRICA 3/4', 'TUERCA ROSCA MILIMETRICA 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'HEMBRA 7 POLOS', 'HEMBRA 7 POLOS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'HEMBRA 7 POLOS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/4X1 GALVANIZADO', 'TORNILLO 1/4X1 GALVANIZADO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/4', 'TUERCA ESTANDAR 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE AZUL CAL,12', 'CABLE AZUL CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE AZUL CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE ROJO CAL,12', 'CABLE ROJO CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE ROJO CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE AMARILLO CAL,12', 'CABLE AMARILLO CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE VERDE CAL,12', 'CABLE VERDE CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE VERDE CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE CAFE CAL,12', 'CABLE CAFE CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE CAFE CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CABLE NEGRO CAL,12', 'CABLE NEGRO CAL,12', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CABLE NEGRO CAL,12');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 1/2', 'CORRUGADO 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 3/8', 'CORRUGADO 3/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 3/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CORRUGADO 1/4', 'CORRUGADO 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CORRUGADO 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TERMINAL 3/16', 'TERMINAL 3/16', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TERMINAL 3/16');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TERMINAL 1/4', 'TERMINAL 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TERMINAL 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'REMACHE 3/16 X 5/8', 'REMACHE 3/16 X 5/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CINTA DE AISLAR', 'CINTA DE AISLAR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CINTA DE AISLAR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON ROJO 4', 'PLAFON ROJO 4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON ROJO 4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON ROJO 2', 'PLAFON ROJO 2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON ROJO 2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON AMBAR 2', 'PLAFON AMBAR 2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON AMBAR 2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON AVALADO AMBAR', 'PLAFON AVALADO AMBAR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON DE CARRITO AMBAR', 'PLAFON DE CARRITO AMBAR', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLAFON DE CARRITO ROJO', 'PLAFON DE CARRITO ROJO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/8X 1 1/4', 'TORNILLO 1/8X 1 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/8', 'TUERCA ESTANDAR 1/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LODERA BLANCA O NEGRA', 'LODERA BLANCA O NEGRA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'FLEJE', 'FLEJE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'FLEJE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'TORNILLO 1/4X1 ACERO INOXIDABLE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 1/4', 'TUERCA DE SEGURIDAD 1/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TOPE DE HULE 3 BARRENOS', 'TOPE DE HULE 3 BARRENOS', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'TORNILLO 1/2 X 2 1/2 GALVANIZADO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA ESTANDAR 1/2 GALVANIZADA', 'TUERCA ESTANDAR 1/2 GALVANIZADA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA PLANA 1/2', 'RONDANA PLANA 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA PLANA 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'WINCHES', 'WINCHES', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'WINCHES');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 1/2X 1 3/4', 'TORNILLO 1/2X 1 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 1/2', 'TUERCA DE SEGURIDAD 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'KIT DE ROTULACION', 'KIT DE ROTULACION', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'KIT DE ROTULACION');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CINTA REFLEJANTE', 'CINTA REFLEJANTE', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CINTA REFLEJANTE');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'PLACA DE NIP', 'PLACA DE NIP', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLACA DE NIP');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CHAVETAS 3/16*2', 'CHAVETAS 3/16*2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CHAVETAS 3/16*2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'ESLABONES DE CADENA 1/2', 'ESLABONES DE CADENA 1/2', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8*3 GRADO 8', 'TORNILLO 5/8*3 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 5/8*5 GRADO 8', 'TORNILLO 5/8*5 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4*6 GRADO 8', 'TORNILLO 3/4*6 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 3/4', 'TUERCA DE SEGURIDAD 3/4', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TUERCA DE SEGURIDAD 5/8', 'TUERCA DE SEGURIDAD 5/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RONDANA AUTOMOTRIZ 5/8', 'RONDANA AUTOMOTRIZ 5/8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4 X 6 GRADO 8', 'TORNILLO 3/4 X 6 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'TORNILLO 3/4 X 3 1/2 GRADO 8', 'TORNILLO 3/4 X 3 1/2 GRADO 8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CANDADO PARA PLANA', 'CANDADO PARA PLANA', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CANDADO PARA PLANA');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'CARGADO 3X102 IN', 'CARGADO 3X102 IN', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'CARGADO 3X102 IN');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO FLET MASTER', 'RIN DE ACERO FLET MASTER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO FLET MASTER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO ACURRAI', 'RIN DE ACERO ACURRAI', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO ACURRAI');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE ACERO AMPRO', 'RIN DE ACERO AMPRO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE ACERO AMPRO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO FLET MASTER', 'RIN DE AUMINIO FLET MASTER', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL', 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO AMPRO', 'RIN DE AUMINIO AMPRO', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL', 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA K PATOS LINEAL', 'LLANTA K PATOS LINEAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA K PATOS LINEAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA K PATOS TRACCION', 'LLANTA K PATOS TRACCION', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA K PATOS TRACCION');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA FIRESTON LINEAL', 'LLANTA FIRESTON LINEAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA FIRESTON LINEAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT 'LLANTA GODSHIELD LINEAL', 'LLANTA GODSHIELD LINEAL', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'LLANTA GODSHIELD LINEAL');
INSERT INTO productos (id, nombre, tipo, costo, precio_unitario, descripcion, organizacion_id)
            SELECT '8', '8', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = '8');

-- 4. Inserción de receta_base

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 35 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 40 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 3 AND largo_ft = 40 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 42 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 3 AND largo_ft = 42 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 43 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 3 AND largo_ft = 43 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 45 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 2 AND largo_ft = 48 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = 3 AND largo_ft = 48 LIMIT 1;

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_largo', 'PASO 1', 'CORTE DE PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 1', 'ESMERILAR PLACAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 2', 'UNION DE SOLERAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PERNO REY 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PERNO REY 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 3', 'PLANCHA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CONSUMIBLE 65' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CONSUMIBLE 65'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_largo', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 3', 'PUENTES Y BORDAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADORES 4X 102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADORES 4X 102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 38, 'fija', 'PASO 4', 'CARGADOR, BORDAD LATERALES, BUCHACAS, GANCHO, TUBO, ALETAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'OXIGENO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: OXIGENO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'fija', 'PASO 4', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICROALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICROALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'fija', 'PASO 5', 'RESOLDE, RETRACTIL Y SUSPENSION', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE CORTE 7' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE CORTE 7'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO DE DESBASTE 9' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO DE DESBASTE 9'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CO2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CO2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ROLLO DE MICRO ALAMBRE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ROLLO DE MICRO ALAMBRE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.25, 'por_eje', 'PASO 6', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LIJA #80' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LIJA #80'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARDA 5/8 DE 3"' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARDA 5/8 DE 3"'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'DISCO LAMINADO 4 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: DISCO LAMINADO 4 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FOSFATO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FOSFATO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 0.5, 'por_eje', 'LIMPIEZA', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4X 2 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4X 2 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA GRIPCO 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA GRIPCO 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'KIT DE GANCHO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCAS DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCAS DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL GRANDE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL CHICA UBL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL CHICA UBL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 3/4 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 3/4 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS PLANAS 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS PLANAS 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ROSCA MILIMETRICA 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ROSCA MILIMETRICA 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'AIRE', 'PARA SISTEMA RETRACTIL CHICO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 7 POLOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 7 POLOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', 'HEMBRAS Y PLAFON ABS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AZUL CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AZUL CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE ROJO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE ROJO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 17.3, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE AMARILLO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE AMARILLO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE VERDE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE VERDE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE CAFE CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE CAFE CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 28.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 15.9, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CABLE NEGRO CAL,12' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CABLE NEGRO CAL,12'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 25.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 14.5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 21.8, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 3/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 3, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CORRUGADO 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CORRUGADO 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 22.8, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 18, 'fija', 'LUZ', 'PLAFONES PRINCIPALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', 'HEMBRAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TERMINAL 3/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TERMINAL 3/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 36, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REMACHE 3/16 X 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REMACHE 3/16 X 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 51, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA DE AISLAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA DE AISLAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON ROJO 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON ROJO 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 5, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AMBAR 2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AMBAR 2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON AVALADO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON AVALADO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'LUZ', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO AMBAR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO AMBAR'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'LUZ', 'LATERALES', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLAFON DE CARRITO ROJO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLAFON DE CARRITO ROJO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 16, 'fija', 'LUZ', 'ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/8X 1 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/8X 1 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 72, 'fija', 'LUZ', 'SI LLEVA LATERALES Y ESTRIBO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LODERA BLANCA O NEGRA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LODERA BLANCA O NEGRA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'FLEJE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: FLEJE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'TERMINADO', 'TORNILLERIA DE LODERA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TOPE DE HULE 3 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TOPE DE HULE 3 BARRENOS'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2 X 2 1/2 GALVANIZADO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2 X 2 1/2 GALVANIZADO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GALVANIZADA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GALVANIZADA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 6, 'fija', 'TERMINADO', 'TORNILLERIA DE TOPE', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'WINCHES' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: WINCHES'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/2X 1 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/2X 1 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'TERMINADO', 'TORNILLERIA DE RIEL', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ROTULACION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ROTULACION'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CINTA REFLEJANTE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLACA DE NIP' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLACA DE NIP'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 1/4X1 ACERO INOXIDABLE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 1/4X1 ACERO INOXIDABLE'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', 'TORNILLERIA DE PORTA PLACA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'TERMINADO', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO CABEZA DE COCHE 1/4 X 1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO CABEZA DE COCHE 1/4 X 1 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 444, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CHAVETAS 3/16*2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CHAVETAS 3/16*2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 48, 'fija', 'EXTRAS', 'JUEGO DE REDILAS', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESLABONES DE CADENA 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESLABONES DE CADENA 1/2'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 20, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*3 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*3 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8*5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8*5 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4*6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4*6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 1, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 5/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 5/8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'RETRACTIL GRANDE HECHIZO', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 6 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 6 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/4 X 3 1/2 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/4 X 3 1/2 GRADO 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 2, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA AUTOMOTRIZ 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA AUTOMOTRIZ 3/4'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'fija', 'EXTRAS', 'AMORTIGUADOR DE ALTA', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CANDADO PARA PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CANDADO PARA PLANA'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 12, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CARGADO 3X102 IN' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CARGADO 3X102 IN'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 8, 'fija', 'EXTRAS', 'SI ES MULTIMODAL O PORTA CONTENEDOR', 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO FLET MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO FLET MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE AUMINIO AMPRO MASTER TRAPEZOIDAL'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

    SELECT id INTO v_mat_id FROM productos WHERE nombre = '8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: 8'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, 4, 'por_eje', 'EXTRAS', NULL, 'import-2r1b');

-- 5. Inserción de opcion_componentes

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SISTEMA RETRACTIL GRANDE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: SISTEMA RETRACTIL GRANDE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'SISTEMA RETRACTIL CHICO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: SISTEMA RETRACTIL CHICO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 23743' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR HENDRICKSON 23743'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR MONRROE 65512' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR MONRROE 65512'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION HENDRICKSON C-25319 O R14-152'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL CON TORNILLO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR HENDRICKSON 20126' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR HENDRICKSON 20126'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION HENDRICKSON R14-083-38' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION HENDRICKSON R14-083-38'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL CON TORNILLO 7/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL CON TORNILLO 7/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hendrickson' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> hendrickson'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FLET MASTER 8050' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION FLET MASTER 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 1R14-039' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 1R14-039'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION FCR 1R14-039' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION FCR 1R14-039'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR FLET MASTER 323' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR FLET MASTER 323'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR FCR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR FCR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'sustituto', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS HENDRICKSON' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS HENDRICKSON'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL HENDRICKSON 7/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL HENDRICKSON 7/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'independiente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PIERNAS IZQUIERDA Y DERECHA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PIERNAS IZQUIERDA Y DERECHA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PLATOS IZQUIERDO Y DERECHO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PLATOS IZQUIERDO Y DERECHO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CAMARA DE SUSPENSION AMPRO 8050' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CAMARA DE SUSPENSION AMPRO 8050'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'AMORTIGUADOR GABRIEL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: AMORTIGUADOR GABRIEL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ABRAZADERAS AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ABRAZADERAS AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS CENTRICAS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS CENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANAS EXCENTRICAS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANAS EXCENTRICAS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BUJE TRIFUNCIONAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BUJE TRIFUNCIONAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'por_eje', 'componente', 'PASO 5', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO ALLEN 1/2X1 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO ALLEN 1/2X1 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1.5, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 1/2 GRADO 5' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 1/2 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1.5, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/8X1 1/2 GRADO 5' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/8X1 1/2 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 22, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'suspension' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: suspension'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: suspension -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA ESTANDAR 5/8 GRADO 5' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA ESTANDAR 5/8 GRADO 5'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 22, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'holland' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> holland'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN HOLAND MARK V' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN HOLAND MARK V'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hj' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> hj'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN HJ' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN HJ'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'patin' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: patin'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'flet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: patin -> flet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PATIN FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PATIN FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fleet_master' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> fleet_master'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ampro' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> ampro'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'fcr' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> fcr'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE FCR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE FCR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'prat_max' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> prat_max'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE PRAT MAX' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE PRAT MAX'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'eje' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: eje'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'hj' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: eje -> hj'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'EJE HJ' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: EJE HJ'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'por_eje', 'componente', 'PASO 6', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 19, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 20, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TRANSPARENTE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TRANSPARENTE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'sherwin_williams' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> sherwin_williams'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER O REDUCTOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER O REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 16, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCTOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 15, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 7, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'ppg' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> ppg'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'THINER O REDUCTOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: THINER O REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PINTURA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PINTURA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 20, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCTOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCTOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 15, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CATALIZADOR' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CATALIZADOR'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2.5, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'PRAIMER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: PRAIMER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'PINTURA', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT ABS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT ABS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCCION 3/4 * 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCCION 3/4 * 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'REDUCCION 3/8 * 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: REDUCCION 3/8 * 1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 3, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'NIPLE 1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: NIPLE 1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 3/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 3/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/4 SUSPENSION FM + 4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/4 SUSPENSION FM + 4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 3, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TAPON 1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TAPON 1/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE UNIO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE UNIO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE LATERAL 3/8*1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE LATERAL 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TE CENTRO 3/8*1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TE CENTRO 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RECTA 3/8*1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RECTA 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 6, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8*1/4' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8*1/4'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 12, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8*1/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8*1/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'CODO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: CODO 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ADAPTADOR 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ADAPTADOR 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MACHO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MACHO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'HEMBRA 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: HEMBRA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'KIT DE ABS 2 EJES BENDIX' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: KIT DE ABS 2 EJES BENDIX'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA PROTECTORA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA PROTECTORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA NIVELADORA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA NIVELADORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA PALANQUETA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA PALANQUETA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VARILLA NIVELADORA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VARILLA NIVELADORA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'VALVULA RETRACTIL SEALCO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: VALVULA RETRACTIL SEALCO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA AZUL C/LLAVE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA AZUL C/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA ROJA C/LLAVE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA ROJA C/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA AZUL S/LLAVE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA AZUL S/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANITA ROJA S/LLAVE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANITA ROJA S/LLAVE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'ESPARRAGO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ESPARRAGO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TEFLON DE 13 METROS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TEFLON DE 13 METROS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'INCERTO 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: INCERTO 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 38, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'INCERTO 1/2' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: INCERTO 1/2'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA AZUL 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA AZUL 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 30, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA ROJA 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA ROJA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 13, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'MANGUERA CHAMBER 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: MANGUERA CHAMBER 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 3/8 X 1 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 3/8 X 1 GRADO 8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 3/8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 3/8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 8, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TORNILLO 5/16 X 5 GRADO 8' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TORNILLO 5/16 X 5 GRADO 8'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RONDANA PLANA 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RONDANA PLANA 5/16'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TUERCA DE SEGURIDAD 5/16' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TUERCA DE SEGURIDAD 5/16'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'pintura' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: pintura'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'axalta' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: pintura -> axalta'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'TANQUE DE AIRE DE PLANA' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: TANQUE DE AIRE DE PLANA'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 2, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'holland_8_10' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> holland_8_10'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO HOLLAND 10 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO HOLLAND 10 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'premier_8' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> premier_8'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO PREMIER 10 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO PREMIER 10 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'gancho' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: gancho'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'premier_bestia_6' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: gancho -> premier_bestia_6'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'GANCHO PREMIER BESTIA 6 BARRENOS' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: GANCHO PREMIER BESTIA 6 BARRENOS'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'retractil' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: retractil'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'grande' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: retractil -> grande'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'BOLSA RETRACTIL GRANDE' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: BOLSA RETRACTIL GRANDE'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 1, 'fija', 'componente', 'AIRE', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO FLET MASTER' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO FLET MASTER'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO ACURRAI' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO ACURRAI'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'rines' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: rines'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'acero' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: rines -> acero'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'RIN DE ACERO AMPRO' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: RIN DE ACERO AMPRO'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'kpatos_lineal' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> kpatos_lineal'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA K PATOS LINEAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA K PATOS LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'kpatos_traccion' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> kpatos_traccion'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA K PATOS TRACCION' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA K PATOS TRACCION'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'firestone' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> firestone'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA FIRESTON LINEAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA FIRESTON LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = 'llantas' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: llantas'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = 'godshield_lineal' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: llantas -> godshield_lineal'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = 'LLANTA GODSHIELD LINEAL' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: LLANTA GODSHIELD LINEAL'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, 4, 'por_eje', 'componente', 'EXTRAS', 'import-2r1b');

END $$;
COMMIT;
