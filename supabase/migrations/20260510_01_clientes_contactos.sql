-- ============================================================
-- Agregar columna contactos (JSONB) a la tabla clientes
-- Almacena un arreglo de contactos por cliente
-- ============================================================

ALTER TABLE clientes 
  ADD COLUMN IF NOT EXISTS contactos JSONB DEFAULT '[]'::jsonb;

-- Agregar referencia al contacto que solicita la cotización
ALTER TABLE cotizaciones
  ADD COLUMN IF NOT EXISTS contacto_id TEXT;

-- Comentarios
COMMENT ON COLUMN clientes.contactos IS 
  'Array de objetos con: {id, nombre, departamento, puesto, telefono, correo}';
COMMENT ON COLUMN cotizaciones.contacto_id IS 
  'ID del contacto del cliente que solicita esta cotización (referencia a clientes.contactos[].id)';
