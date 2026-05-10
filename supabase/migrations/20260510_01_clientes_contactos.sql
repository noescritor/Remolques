-- ============================================================
-- Agregar columna contactos (JSONB) a la tabla clientes
-- Almacena un arreglo de contactos por cliente
-- ============================================================

ALTER TABLE clientes 
  ADD COLUMN IF NOT EXISTS contactos JSONB DEFAULT '[]'::jsonb;

-- Comentario para documentar la estructura esperada
COMMENT ON COLUMN clientes.contactos IS 
  'Array de objetos con: {id, nombre, departamento, puesto, telefono, correo}';
