-- Script de Migración de BOM (Recetas de Producción)
-- (Compatible con Supabase SQL Editor)

-- 1. CREAR LOS PRODUCTOS TERMINADOS
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 2 35 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 2 40 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 3 40 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 2 42 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 3 42 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 2 45 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 2 48 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 3 48 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 3 43 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT');
INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT (SELECT id FROM organizaciones LIMIT 1), 'bien', 'producto_terminado', 'PZA', 'PLATAFORMA 3 45 FT', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT');

-- 2. ENLAZAR MATERIALES CON PRODUCTOS TERMINADOS (BOM)
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA DELANTERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BORDA TRASERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTA PLACA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PTR 4"4 PARA ESTRIBO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERA DEL CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PORTALODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SEPARADOR CENTRO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JUEGO ALETAS (ALERONES)' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1),
  4.44
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA PLANCHA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA P/QUINTA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR/PESTANAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR FLEJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CAJA DE HERRAMIENTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT BASE P/TANQUE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PAR BASES PARA PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PUENTES PARA SUSPENSION' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  40
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1),
  52
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BASE L P/PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL PARA PERCHA 1.10 m' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PERCHA 30 X 15' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA REF PARA PLATO 7.6 X 20' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BUCHACAS PARA PATIN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'JALON P/ GANCHO DE ARRASTRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PLACA 1/4' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA DE 1/2"* 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  3.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANAL U DE 6" *12M' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  1.75
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'GANCHO PARA LAZO 1/2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  1.3125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1),
  8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERAS DE 3/8" *2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PORTALLANTAS 1/2*3' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO PORTALLANTAS Y JALON 1"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REDONDO DE 5/8 X 6MTS P/REDILAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 1/8 *1  1/2 PORTALLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ANGULO 2 X 2 X 3/16' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA 1 1/2"*3/16 P/ESQUINEROS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1),
  2.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SOLERA PLACA 1/8 X 2 X 6MTS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO DE 2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO MEC 3/4 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TUBO 1  1/2 CED 40' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  34
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  38
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  38
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  40
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  40
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  43
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  46
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  46
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  46
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1),
  43
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARGADORES DE 4"' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PERNO REY HOLLAND' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1),
  0.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CINTA REFLEJANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'ROTULACIÓN' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TANQUE DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SUSPENSIÓN ALTA HENDRICKSON' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'EJES FLEET MASTER' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PATÍN HJ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATRACAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'KIT DE ABS Y CONEXIONES 2 EJES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.480625
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.3625
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.835
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.835
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.835
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1),
  2.3625
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CO2' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  3.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1),
  4.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MICROTUBULAR' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CONSUMIBLE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TOPES HULE 3 BARRENOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  3.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.8
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1),
  4.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE CORTADORA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  1.75
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS LAMINADOS #7' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  1.75
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'DISCOS DE DESBASTE #9' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  1.75
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1),
  2.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CARDA DE COPA TRENZADA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  8.75
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  10
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  10.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  10.5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  11.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  12
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  12
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  12
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1),
  11.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'HOJAS DE LIJA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  11.25
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CABLEADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LODERAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'BANDEROLAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'LUCES' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'TORNILLOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MATERIAL COMPLEMENTARIO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'NIV' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE PINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE MADERA DE ENCINO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE MADERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO LAMINADO CON BASE DE PLÁSTICO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SIN PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PISO ANTIDERRAPANTE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  0.875
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.05
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.125
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1),
  1.2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PIJAS/BROCAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1),
  3000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1),
  5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'RIEL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1),
  5450
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'SISTEMA RETRÁCTIL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'REFUERZOS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'CANDADO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1),
  5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1),
  5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'POLINERA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  3000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  3000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA PISO' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  15000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  15000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  2
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'PINTURA Y MANO DE OBRA' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  5000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  5000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  3
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA LUZ' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1500
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1500
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  4
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA DE AIRE' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  30000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  30000
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  5
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 42 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 48 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 43 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1),
  1
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 45 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MANO DE OBRA GENERAL' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1),
  50
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 35 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1),
  50
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 2 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1)
  );
INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  (SELECT id FROM organizaciones LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1),
  6
WHERE 
  (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = 'PLATAFORMA 3 40 FT' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = 'MONTADA DE LLANTAS' LIMIT 1)
  );
