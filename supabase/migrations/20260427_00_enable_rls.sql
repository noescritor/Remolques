-- Fase 0: Habilitar RLS en kv_store_feea4382

-- 1. Habilitar Row Level Security (RLS) en la tabla
ALTER TABLE kv_store_feea4382 ENABLE ROW LEVEL SECURITY;

-- 2. Crear política para permitir acceso solo a usuarios autenticados
-- Esto asegura que la anon key por sí sola no puede leer ni modificar datos.
-- Requiere un JWT de Supabase Auth en las peticiones.
CREATE POLICY "Acceso total para usuarios autenticados" 
ON kv_store_feea4382 
FOR ALL 
TO authenticated 
USING (true) 
WITH CHECK (true);
