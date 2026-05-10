-- ============================================================
-- MIGRACIÓN A SAAS (MULTI-TENANT) EN PRODUCCIÓN
-- Este script altera las tablas existentes sin perder datos.
-- ============================================================

-- 1. Crear las nuevas tablas centrales
CREATE TABLE IF NOT EXISTS organizaciones (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  nombre TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

CREATE TABLE IF NOT EXISTS perfiles_organizacion (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID REFERENCES organizaciones(id) ON DELETE CASCADE,
  usuario_id UUID NOT NULL, 
  rol TEXT CHECK (rol IN ('propietario', 'admin', 'usuario')) DEFAULT 'usuario',
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(organizacion_id, usuario_id)
);

-- 2. Crear una Organización por Defecto para los datos existentes
INSERT INTO organizaciones (id, nombre) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Organización Principal')
ON CONFLICT DO NOTHING;

-- Si tienes usuarios existentes en auth.users, puedes agregarlos manualmente o 
-- con un trigger. Por ahora, debes vincularlos manualmente desde el panel.

-- 3. Añadir la columna organizacion_id como NULLABLE primero
ALTER TABLE clientes ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE productos ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE pagos ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE proyectos ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE auditoria ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);
ALTER TABLE historial_precios ADD COLUMN IF NOT EXISTS organizacion_id UUID REFERENCES organizaciones(id);

-- 4. Actualizar todos los registros existentes a la organización por defecto
UPDATE clientes SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE productos SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE cotizaciones SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE items_cotizacion SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE pagos SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE plantillas_cotizacion SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE proyectos SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE auditoria SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;
UPDATE historial_precios SET organizacion_id = '00000000-0000-0000-0000-000000000001' WHERE organizacion_id IS NULL;

-- 5. Ahora que todo tiene datos, podemos hacer la columna NOT NULL de forma segura
ALTER TABLE clientes ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE productos ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE cotizaciones ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE items_cotizacion ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE pagos ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE plantillas_cotizacion ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE proyectos ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE auditoria ALTER COLUMN organizacion_id SET NOT NULL;
ALTER TABLE historial_precios ALTER COLUMN organizacion_id SET NOT NULL;

-- 6. Habilitar RLS en las nuevas tablas
ALTER TABLE organizaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE perfiles_organizacion ENABLE ROW LEVEL SECURITY;

-- 7. Borrar las políticas viejas
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en clientes" ON clientes;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en productos" ON productos;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en cotizaciones" ON cotizaciones;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en items" ON items_cotizacion;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en pagos" ON pagos;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en proyectos" ON proyectos;
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en auditoria" ON auditoria;
DROP POLICY IF EXISTS "plantillas_auth_all" ON plantillas_cotizacion;
DROP POLICY IF EXISTS "historial_auth_all" ON historial_precios;

-- 8. Crear las nuevas políticas RLS restrictivas para SaaS
CREATE POLICY "Usuarios pueden ver sus organizaciones" ON organizaciones FOR SELECT TO authenticated USING (id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios pueden ver perfiles de su org" ON perfiles_organizacion FOR SELECT TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

CREATE POLICY "s_clientes" ON clientes FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_productos" ON productos FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_cotizaciones" ON cotizaciones FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_items" ON items_cotizacion FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_pagos" ON pagos FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_plantillas" ON plantillas_cotizacion FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_proyectos" ON proyectos FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_auditoria" ON auditoria FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "s_historial" ON historial_precios FOR ALL TO authenticated USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

-- Índices de rendimiento
CREATE INDEX IF NOT EXISTS idx_perfiles_usuario ON perfiles_organizacion(usuario_id);
CREATE INDEX IF NOT EXISTS idx_clientes_org ON clientes(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_productos_org ON productos(organizacion_id);
CREATE INDEX IF NOT EXISTS idx_cotizaciones_org ON cotizaciones(organizacion_id);
