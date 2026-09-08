-- ========== 20260427_01_relational_schema.sql ==========
-- Fase 1: Creación de Schema Relacional

-- 0. Limpiar tablas anteriores en caso de que ya existan con tipos incorrectos (ej. UUID)
DROP TABLE IF EXISTS auditoria CASCADE;
DROP TABLE IF EXISTS proyectos CASCADE;
DROP TABLE IF EXISTS plantillas_cotizacion CASCADE;
DROP TABLE IF EXISTS ajustes CASCADE;
DROP TABLE IF EXISTS pagos CASCADE;
DROP TABLE IF EXISTS items_cotizacion CASCADE;
DROP TABLE IF EXISTS cotizaciones CASCADE;
DROP TABLE IF EXISTS productos CASCADE;
DROP TABLE IF EXISTS clientes CASCADE;

-- Clientes
CREATE TABLE clientes (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre_razon_social TEXT NOT NULL,
  nombre_contacto TEXT,
  telefono TEXT,
  correo TEXT,
  direccion TEXT,
  ciudad TEXT,
  estado TEXT,
  codigo_postal TEXT,
  pais TEXT NOT NULL DEFAULT 'México',
  tipo_pago_preferido TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Productos
CREATE TABLE productos (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tipo TEXT CHECK (tipo IN ('bien', 'servicio')),
  nombre TEXT NOT NULL,
  descripcion TEXT,
  unidad TEXT NOT NULL,
  precio_unitario NUMERIC(12,2),
  costo NUMERIC(12,2),
  tasa_iva NUMERIC(4,2) DEFAULT 0.16,
  servicio JSONB,
  stock_actual INT DEFAULT 0,
  stock_minimo INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Cotizaciones
CREATE TABLE cotizaciones (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  folio TEXT NOT NULL UNIQUE,
  cliente_id TEXT REFERENCES clientes(id),
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  validez_dias INT NOT NULL DEFAULT 30,
  estado TEXT CHECK (estado IN ('Borrador','Enviada','Aprobada','Cancelada','Pagada')),
  con_factura BOOLEAN DEFAULT true,
  descripcion TEXT,
  subtotal NUMERIC(12,2),
  iva NUMERIC(12,2),
  total NUMERIC(12,2),
  nota TEXT,
  costos_indirectos JSONB,
  comisiones_pago JSONB,
  -- Portal de cliente (Fase 3)
  token_publico TEXT DEFAULT gen_random_uuid()::text,
  token_expira_en TIMESTAMPTZ,
  -- Firma digital (Fase 3)
  firma_imagen TEXT,
  firma_nombre TEXT,
  firma_fecha TIMESTAMPTZ,
  firma_ip TEXT,
  -- Versiones (Fase 2)
  cotizacion_padre_id TEXT REFERENCES cotizaciones(id),
  version INT DEFAULT 1,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Items de cotización
CREATE TABLE items_cotizacion (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  cotizacion_id TEXT REFERENCES cotizaciones(id) ON DELETE CASCADE,
  producto_id TEXT REFERENCES productos(id),
  posicion INT NOT NULL,
  cantidad NUMERIC(10,3) NOT NULL,
  unidad TEXT NOT NULL,
  descripcion TEXT NOT NULL,
  precio_unitario NUMERIC(12,2),
  costo_unitario NUMERIC(12,2),
  iva_item NUMERIC(12,2),
  total_item NUMERIC(12,2),
  metadata JSONB
);

-- Pagos
CREATE TABLE pagos (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  cotizacion_id TEXT REFERENCES cotizaciones(id),
  tipo_pago TEXT,
  referencia TEXT,
  monto NUMERIC(12,2) NOT NULL,
  fecha DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Ajustes de la empresa
CREATE TABLE ajustes (
  id TEXT PRIMARY KEY DEFAULT '00000000-0000-0000-0000-000000000001',
  data JSONB NOT NULL
);

-- Plantillas (Fase 2)
CREATE TABLE plantillas_cotizacion (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre TEXT NOT NULL,
  descripcion TEXT,
  items JSONB NOT NULL,
  nota TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Proyectos (Fase 4)
CREATE TABLE proyectos (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  cotizacion_id TEXT REFERENCES cotizaciones(id),
  nombre TEXT NOT NULL,
  estado TEXT CHECK (estado IN ('planificacion','en_curso','pausado','completado')),
  fecha_inicio DATE,
  fecha_entrega DATE,
  porcentaje_avance INT DEFAULT 0,
  notas TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Auditoría (log de cambios)
CREATE TABLE auditoria (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  tabla TEXT NOT NULL,
  registro_id TEXT NOT NULL,
  accion TEXT CHECK (accion IN ('INSERT','UPDATE','DELETE')),
  datos_anteriores JSONB,
  datos_nuevos JSONB,
  usuario_id TEXT,
  ip TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS en todas las tablas
ALTER TABLE clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE cotizaciones ENABLE ROW LEVEL SECURITY;
ALTER TABLE items_cotizacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE pagos ENABLE ROW LEVEL SECURITY;
ALTER TABLE ajustes ENABLE ROW LEVEL SECURITY;
ALTER TABLE plantillas_cotizacion ENABLE ROW LEVEL SECURITY;
ALTER TABLE proyectos ENABLE ROW LEVEL SECURITY;
ALTER TABLE auditoria ENABLE ROW LEVEL SECURITY;

-- Políticas de RLS: Acceso total para usuarios autenticados
CREATE POLICY "Acceso total para usuarios autenticados en clientes" ON clientes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en productos" ON productos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en cotizaciones" ON cotizaciones FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en items" ON items_cotizacion FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en pagos" ON pagos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en ajustes" ON ajustes FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en plantillas" ON plantillas_cotizacion FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en proyectos" ON proyectos FOR ALL TO authenticated USING (true) WITH CHECK (true);
CREATE POLICY "Acceso total para usuarios autenticados en auditoria" ON auditoria FOR ALL TO authenticated USING (true) WITH CHECK (true);


-- ========== 20260427_03_plantillas_historial.sql ==========
-- ============================================================
-- FASE 2 — Plantillas de Cotización e Historial de Precios
-- ============================================================

-- Plantillas
CREATE TABLE IF NOT EXISTS plantillas_cotizacion (
  id         TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  nombre     TEXT NOT NULL,
  descripcion TEXT,
  items      JSONB NOT NULL DEFAULT '[]',
  nota       TEXT,
  con_factura BOOLEAN DEFAULT true,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS con_factura BOOLEAN DEFAULT true;
ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE plantillas_cotizacion ALTER COLUMN items SET DEFAULT '[]';

ALTER TABLE plantillas_cotizacion ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "plantillas_auth_all" ON plantillas_cotizacion;
CREATE POLICY "plantillas_auth_all"
  ON plantillas_cotizacion FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);

-- Historial de precios por producto
CREATE TABLE IF NOT EXISTS historial_precios (
  id           TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  producto_id  TEXT REFERENCES productos(id) ON DELETE CASCADE,
  precio_anterior NUMERIC(12,2) NOT NULL,
  precio_nuevo    NUMERIC(12,2) NOT NULL,
  fecha        TIMESTAMPTZ DEFAULT now()
);

ALTER TABLE historial_precios ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "historial_auth_all" ON historial_precios;
CREATE POLICY "historial_auth_all"
  ON historial_precios FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);


-- ========== 20260427_04_portal_firma.sql ==========
-- ============================================================
-- FASE 3 — Portal de Cliente y Firma Digital
-- Las columnas token_publico, firma_imagen, etc. ya existen en
-- el schema base (20260427_01). Este script agrega solo lo que
-- puede faltar si el schema fue creado antes de esos campos.
-- Es seguro ejecutarlo aunque ya existan.
-- ============================================================

ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS token_publico TEXT DEFAULT gen_random_uuid()::text;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS token_expira_en TIMESTAMPTZ;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS firma_imagen TEXT;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS firma_nombre TEXT;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS firma_fecha TIMESTAMPTZ;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS firma_ip TEXT;
ALTER TABLE cotizaciones ADD COLUMN IF NOT EXISTS comentario_cliente TEXT;

-- Asegurar que cada cotización tiene token_publico
UPDATE cotizaciones SET token_publico = gen_random_uuid()::text WHERE token_publico IS NULL;


-- ========== 20260427_05_fix_plantillas_schema.sql ==========
-- ============================================================
-- FASE 3 HOTFIX — Plantillas no guardan
-- Corrige instalaciones donde plantillas_cotizacion fue creada
-- por el schema base antes de existir con_factura/updated_at.
-- ============================================================

ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS con_factura BOOLEAN DEFAULT true;
ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE plantillas_cotizacion ALTER COLUMN items SET DEFAULT '[]';

DROP POLICY IF EXISTS "plantillas_auth_all" ON plantillas_cotizacion;
CREATE POLICY "plantillas_auth_all"
  ON plantillas_cotizacion FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);


-- ========== 20260427_06_items_metadata_columns.sql ==========
-- ============================================================
-- HOTFIX — Campos extendidos de items de cotizacion
-- El backend actual guarda estos valores en metadata para
-- compatibilidad, pero estas columnas permiten consultarlos
-- directamente si se decide mapearlos en el futuro.
-- ============================================================

ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS numero_proyecto TEXT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS incluir_setup BOOLEAN;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS meses_cobrados INT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS asientos_extra INT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;


-- ========== 20260505_01_saas_transition.sql ==========
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


-- ========== 20260509_01_saas_invitations_trigger.sql ==========
-- ============================================================
-- SAAS MULTI-TENANT: INVITACIONES Y TRIGGERS DE AUTH
-- ============================================================

-- 1. Crear tabla de invitaciones (Pre-registro)
CREATE TABLE IF NOT EXISTS invitaciones_equipo (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  email TEXT NOT NULL,
  rol TEXT CHECK (rol IN ('propietario', 'admin', 'usuario')) DEFAULT 'usuario',
  invitado_por UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  UNIQUE(organizacion_id, email)
);

-- RLS para invitaciones: los usuarios de una organización pueden ver sus invitaciones
ALTER TABLE invitaciones_equipo ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Ver invitaciones de mi org" ON invitaciones_equipo 
  FOR SELECT TO authenticated 
  USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

CREATE POLICY "Admins pueden crear invitaciones" ON invitaciones_equipo 
  FOR INSERT TO authenticated 
  WITH CHECK (
    organizacion_id IN (
      SELECT organizacion_id FROM perfiles_organizacion 
      WHERE usuario_id = auth.uid() AND rol IN ('propietario', 'admin')
    )
  );

CREATE POLICY "Admins pueden eliminar invitaciones" ON invitaciones_equipo 
  FOR DELETE TO authenticated 
  USING (
    organizacion_id IN (
      SELECT organizacion_id FROM perfiles_organizacion 
      WHERE usuario_id = auth.uid() AND rol IN ('propietario', 'admin')
    )
  );

-- 2. Trigger en auth.users para asignar usuarios al registrarse
CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER AS $$
DECLARE
  invitacion RECORD;
BEGIN
  -- Buscar si el usuario fue invitado a alguna organización
  SELECT * INTO invitacion FROM invitaciones_equipo WHERE email = NEW.email;

  IF FOUND THEN
    -- Si fue invitado, asignarlo a la organización con el rol definido
    INSERT INTO perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (invitacion.organizacion_id, NEW.id, invitacion.rol);
    
    -- (Opcional) Borrar la invitación una vez aceptada
    DELETE FROM invitaciones_equipo WHERE id = invitacion.id;
  ELSE
    -- FASE 1: Solo por invitación. Si no hay invitación, bloqueamos el registro.
    -- Cuando se quiera abrir al público, aquí se crearía una nueva organización automáticamente.
    RAISE EXCEPTION 'Registro denegado: El correo % no tiene una invitación activa.', NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Eliminar el trigger si ya existía y volver a crearlo
DROP TRIGGER IF EXISTS on_auth_user_created_trigger ON auth.users;

CREATE TRIGGER on_auth_user_created_trigger
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION on_auth_user_created();

-- 3. Función auxiliar para obtener el ID de la organización actual (útil para Edge Functions)
CREATE OR REPLACE FUNCTION get_current_org_id()
RETURNS UUID AS $$
DECLARE
  org_id UUID;
BEGIN
  -- Usamos LIMIT 1 para evitar errores si un usuario estuviera en múltiples organizaciones accidentalmente
  SELECT organizacion_id INTO org_id 
  FROM perfiles_organizacion 
  WHERE usuario_id = auth.uid() 
  LIMIT 1;
  
  RETURN org_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;


-- ========== 20260509_02_fix_rls_policies.sql ==========
-- ============================================================
-- FIX: Reemplazar TODAS las políticas RLS con get_current_org_id()
-- Esta función es SECURITY DEFINER y bypasea RLS automáticamente
-- ============================================================

-- 1. Borrar TODAS las políticas actuales (las que usan subqueries problemáticas)

-- perfiles_organizacion
DROP POLICY IF EXISTS "Usuarios pueden ver perfiles de su org" ON perfiles_organizacion;
DROP POLICY IF EXISTS "Usuarios ven su propio perfil" ON perfiles_organizacion;

-- invitaciones_equipo
DROP POLICY IF EXISTS "Ver invitaciones de mi org" ON invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden crear invitaciones" ON invitaciones_equipo;
DROP POLICY IF EXISTS "Admins pueden eliminar invitaciones" ON invitaciones_equipo;

-- tablas de negocio
DROP POLICY IF EXISTS "s_clientes" ON clientes;
DROP POLICY IF EXISTS "s_productos" ON productos;
DROP POLICY IF EXISTS "s_cotizaciones" ON cotizaciones;
DROP POLICY IF EXISTS "s_items" ON items_cotizacion;
DROP POLICY IF EXISTS "s_pagos" ON pagos;
DROP POLICY IF EXISTS "s_plantillas" ON plantillas_cotizacion;
DROP POLICY IF EXISTS "s_proyectos" ON proyectos;
DROP POLICY IF EXISTS "s_auditoria" ON auditoria;
DROP POLICY IF EXISTS "s_historial" ON historial_precios;

-- organizaciones
DROP POLICY IF EXISTS "Usuarios pueden ver sus organizaciones" ON organizaciones;

-- 2. Recrear TODAS usando get_current_org_id() (SECURITY DEFINER, sin RLS circular)

-- perfiles_organizacion: el usuario ve sus propios registros
CREATE POLICY "po_select" ON perfiles_organizacion 
  FOR SELECT TO authenticated 
  USING (usuario_id = auth.uid());

-- organizaciones
CREATE POLICY "org_select" ON organizaciones 
  FOR SELECT TO authenticated 
  USING (id = get_current_org_id());

-- invitaciones_equipo
CREATE POLICY "inv_select" ON invitaciones_equipo 
  FOR SELECT TO authenticated 
  USING (organizacion_id = get_current_org_id());

CREATE POLICY "inv_insert" ON invitaciones_equipo 
  FOR INSERT TO authenticated 
  WITH CHECK (organizacion_id = get_current_org_id());

CREATE POLICY "inv_delete" ON invitaciones_equipo 
  FOR DELETE TO authenticated 
  USING (organizacion_id = get_current_org_id());

-- clientes
CREATE POLICY "rls_clientes" ON clientes 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- productos
CREATE POLICY "rls_productos" ON productos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- cotizaciones
CREATE POLICY "rls_cotizaciones" ON cotizaciones 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- items_cotizacion
CREATE POLICY "rls_items" ON items_cotizacion 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- pagos
CREATE POLICY "rls_pagos" ON pagos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- plantillas_cotizacion
CREATE POLICY "rls_plantillas" ON plantillas_cotizacion 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- proyectos
CREATE POLICY "rls_proyectos" ON proyectos 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- auditoria
CREATE POLICY "rls_auditoria" ON auditoria 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- historial_precios
CREATE POLICY "rls_historial" ON historial_precios 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());


-- ========== 20260510_01_clientes_contactos.sql ==========
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


-- ========== 20260614154900_inventario.sql ==========
-- Agregar columna stock_reservado a productos
ALTER TABLE productos ADD COLUMN stock_reservado INT DEFAULT 0;

-- Crear tabla de movimientos_inventario
CREATE TABLE movimientos_inventario (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id UUID NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
  tipo_movimiento TEXT NOT NULL CHECK (tipo_movimiento IN ('Entrada', 'Salida', 'Reserva', 'Liberacion', 'Ajuste')),
  cantidad INT NOT NULL,
  referencia TEXT,
  cotizacion_id TEXT REFERENCES cotizaciones(id) ON DELETE SET NULL,
  usuario_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- Habilitar RLS en movimientos_inventario
ALTER TABLE movimientos_inventario ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Usuarios ven movimientos de su org" ON movimientos_inventario FOR SELECT USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios insertan movimientos en su org" ON movimientos_inventario FOR INSERT WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios actualizan movimientos de su org" ON movimientos_inventario FOR UPDATE USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));
CREATE POLICY "Usuarios borran movimientos de su org" ON movimientos_inventario FOR DELETE USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

-- FUNCION Y TRIGGER PARA ACTUALIZAR STOCK AL CAMBIAR ESTADO DE COTIZACION
CREATE OR REPLACE FUNCTION procesar_inventario_por_cotizacion()
RETURNS TRIGGER AS $$
DECLARE
  rec RECORD;
BEGIN
  IF NEW.estado = 'Aprobada' AND OLD.estado IS DISTINCT FROM 'Aprobada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
      VALUES (rec.organizacion_id, rec.producto_id, 'Reserva', rec.cantidad, 'Reserva por Cotización ' || NEW.folio, NEW.id);
      
      UPDATE productos SET stock_reservado = stock_reservado + rec.cantidad WHERE id = rec.producto_id;
    END LOOP;
  ELSIF NEW.estado = 'Pagada' AND OLD.estado IS DISTINCT FROM 'Pagada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      IF OLD.estado = 'Aprobada' THEN
        INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
        VALUES (rec.organizacion_id, rec.producto_id, 'Salida', rec.cantidad, 'Venta (Stock reservado liquidado) Cotización ' || NEW.folio, NEW.id);
        
        UPDATE productos SET stock_actual = stock_actual - rec.cantidad, stock_reservado = stock_reservado - rec.cantidad WHERE id = rec.producto_id;
      ELSE
        INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
        VALUES (rec.organizacion_id, rec.producto_id, 'Salida', rec.cantidad, 'Venta Directa Cotización ' || NEW.folio, NEW.id);
        
        UPDATE productos SET stock_actual = stock_actual - rec.cantidad WHERE id = rec.producto_id;
      END IF;
    END LOOP;
  ELSIF NEW.estado IN ('Cancelada', 'Rechazada') AND OLD.estado = 'Aprobada' THEN
    FOR rec IN SELECT i.organizacion_id, i.producto_id, i.cantidad FROM items_cotizacion i JOIN productos p ON i.producto_id = p.id WHERE i.cotizacion_id = NEW.id AND p.tipo = 'bien' LOOP
      INSERT INTO movimientos_inventario (organizacion_id, producto_id, tipo_movimiento, cantidad, referencia, cotizacion_id)
      VALUES (rec.organizacion_id, rec.producto_id, 'Liberacion', rec.cantidad, 'Liberación por Cancelación ' || NEW.folio, NEW.id);
      
      UPDATE productos SET stock_reservado = stock_reservado - rec.cantidad WHERE id = rec.producto_id;
    END LOOP;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_procesar_inventario
AFTER UPDATE OF estado ON cotizaciones
FOR EACH ROW
EXECUTE FUNCTION procesar_inventario_por_cotizacion();


-- ========== 20260614170000_rediseno_ui.sql ==========
-- ==========================================
-- Migración para Rediseño UI y Nuevos Módulos
-- ==========================================

-- 1. Añadir nuevos campos a cotizaciones
ALTER TABLE cotizaciones
ADD COLUMN IF NOT EXISTS estado_produccion text DEFAULT 'Pendiente',
ADD COLUMN IF NOT EXISTS fecha_entrega timestamptz;

-- 2. Crear tabla de categorías de producto
CREATE TABLE IF NOT EXISTS categorias_producto (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  color text,
  icono text,
  orden int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categorias_producto ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_categorias_producto" ON categorias_producto 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- 3. Crear tabla de campos dinámicos para clientes (capas de personalización)
CREATE TABLE IF NOT EXISTS categorias_cliente (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
  nombre text NOT NULL,
  color text,
  icono text,
  orden int DEFAULT 0,
  created_at timestamptz DEFAULT now()
);

ALTER TABLE categorias_cliente ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_categorias_cliente" ON categorias_cliente 
  FOR ALL TO authenticated 
  USING (organizacion_id = get_current_org_id()) 
  WITH CHECK (organizacion_id = get_current_org_id());

-- 4. Añadir columnas de categoría foráneas a productos y clientes
ALTER TABLE productos
ADD COLUMN IF NOT EXISTS categoria_id uuid REFERENCES categorias_producto(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS imagen_url text;

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS categoria_id uuid REFERENCES categorias_cliente(id) ON DELETE SET NULL,
ADD COLUMN IF NOT EXISTS origen_lead text,
ADD COLUMN IF NOT EXISTS giro_empresa text;


-- ========== 20260615070000_fix_inventario_stock.sql ==========
-- Migracion correctiva para inventario  
-- Asegurar que stock_actual y stock_reservado existan y no sean null en productos  
  
ALTER TABLE productos ADD COLUMN IF NOT EXISTS stock_actual INT DEFAULT 0;  
ALTER TABLE productos ADD COLUMN IF NOT EXISTS stock_reservado INT DEFAULT 0;  
  
UPDATE productos SET stock_actual = 0 WHERE stock_actual IS NULL;  
UPDATE productos SET stock_reservado = 0 WHERE stock_reservado IS NULL;  
  
ALTER TABLE productos ALTER COLUMN stock_actual SET DEFAULT 0;  
ALTER TABLE productos ALTER COLUMN stock_reservado SET DEFAULT 0; 


-- ========== 20260616011000_fix_trigger_case_insensitive.sql ==========
-- ============================================================
-- FIX: Hacer que el trigger de registro de usuarios sea insensible a mayúsculas/minúsculas
-- y configurar 'search_path = public' con calificadores de esquema para evitar
-- fallos de resolución de relaciones cuando el trigger es llamado por supabase_auth_admin.
-- ============================================================

CREATE OR REPLACE FUNCTION on_auth_user_created()
RETURNS TRIGGER AS $$
DECLARE
  invitacion RECORD;
BEGIN
  -- Buscar si el usuario fue invitado a alguna organización (insensible a mayúsculas/minúsculas)
  SELECT * INTO invitacion 
  FROM public.invitaciones_equipo 
  WHERE LOWER(email) = LOWER(NEW.email);

  IF FOUND THEN
    -- Si fue invitado, asignarlo a la organización con el rol definido
    INSERT INTO public.perfiles_organizacion (organizacion_id, usuario_id, rol)
    VALUES (invitacion.organizacion_id, NEW.id, invitacion.rol);
    
    -- Borrar la invitación una vez aceptada
    DELETE FROM public.invitaciones_equipo WHERE id = invitacion.id;
  ELSE
    -- Si no hay invitación, bloqueamos el registro
    RAISE EXCEPTION 'Registro denegado: El correo % no tiene una invitación activa.', NEW.email;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;


-- ========== 20260616020000_organizacion_modulos.sql ==========
-- ============================================================
-- MIGRACIÓN: MÓDULOS DE ORGANIZACIÓN (FEATURE FLAGS)
-- Agrega soporte para activar/desactivar módulos por inquilino.
-- ============================================================

-- 1. Agregar columna 'modulos' de tipo JSONB a la tabla 'organizaciones'
ALTER TABLE public.organizaciones 
ADD COLUMN IF NOT EXISTS modulos JSONB 
DEFAULT '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true}'::jsonb;

-- 2. Actualizar las organizaciones existentes para que tengan todos los módulos habilitados por defecto
UPDATE public.organizaciones 
SET modulos = '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true}'::jsonb 
WHERE modulos IS NULL;


-- ========== 20260616030000_modulo_notas.sql ==========
-- 1. Crear la tabla notas_simples
CREATE TABLE public.notas_simples (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
  folio SERIAL,
  cliente_nombre TEXT NOT NULL,
  items JSONB NOT NULL DEFAULT '[]'::jsonb,
  total NUMERIC(12,2) NOT NULL DEFAULT 0.00,
  estado_taller TEXT NOT NULL CHECK (estado_taller IN ('Pendiente', 'En Proceso', 'Listo', 'Entregado')) DEFAULT 'Pendiente',
  urgencia TEXT NOT NULL CHECK (urgencia IN ('Baja', 'Media', 'Alta', 'Urgente')) DEFAULT 'Media',
  fecha_entrega TIMESTAMPTZ,
  creado_por_nombre TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. Habilitar Row Level Security (RLS)
ALTER TABLE public.notas_simples ENABLE ROW LEVEL SECURITY;

-- 3. Crear políticas RLS para tenant SaaS
CREATE POLICY "s_notas_simples" ON public.notas_simples 
FOR ALL TO authenticated 
USING (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid())) 
WITH CHECK (organizacion_id IN (SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()));

-- 4. Crear índice para organizacion_id
CREATE INDEX idx_notas_simples_org ON public.notas_simples(organizacion_id);

-- 5. Actualizar los módulos de organizaciones existentes y el valor por defecto de la columna
ALTER TABLE public.organizaciones 
ALTER COLUMN modulos SET DEFAULT '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true, "notas": true}'::jsonb;

-- Actualizar organizaciones existentes para que hereden "notas": true manteniendo sus otros módulos
UPDATE public.organizaciones 
SET modulos = COALESCE(modulos, '{"cotizaciones": true, "clientes": true, "productos": true, "calculadora": true, "inventario": true}'::jsonb) || '{"notas": true}'::jsonb;


-- ========== 20260707163000_fix_ajustes_rls.sql ==========
-- Fix RLS policy on ajustes table to prevent leaking settings across organizations and resolve .single() queries failing
DROP POLICY IF EXISTS "Acceso total para usuarios autenticados en ajustes" ON ajustes;
DROP POLICY IF EXISTS "rls_ajustes" ON ajustes;

CREATE POLICY "rls_ajustes" ON ajustes
  FOR ALL TO authenticated
  USING (id = get_current_org_id()::text)
  WITH CHECK (id = get_current_org_id()::text);


-- ========== 20260907_01_materiales_bom.sql ==========
-- Migración 1: Materiales y Lista de Materiales (BOM)

ALTER TABLE productos 
ADD COLUMN IF NOT EXISTS tipo_item text DEFAULT 'producto_terminado' 
CHECK (tipo_item IN ('producto_terminado', 'materia_prima'));

CREATE TABLE IF NOT EXISTS producto_materiales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    producto_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    material_id TEXT NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad_por_unidad numeric NOT NULL CHECK (cantidad_por_unidad > 0),
    created_at timestamptz DEFAULT now(),
    UNIQUE (producto_id, material_id)
);

ALTER TABLE producto_materiales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_producto_materiales" ON producto_materiales
    FOR ALL TO authenticated
    USING (
        producto_id IN (SELECT id FROM productos WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        producto_id IN (SELECT id FROM productos WHERE organizacion_id = get_current_org_id())
    );


-- ========== 20260907_02_proveedores.sql ==========
-- Migración 2: Proveedores

CREATE TABLE IF NOT EXISTS proveedores (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    nombre text NOT NULL,
    contacto text,
    telefono text,
    tiempo_entrega_dias integer DEFAULT 0,
    condiciones_pago text,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE proveedores ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_proveedores" ON proveedores
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE TABLE IF NOT EXISTS proveedor_materiales (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    proveedor_id uuid NOT NULL REFERENCES proveedores(id) ON DELETE CASCADE,
    material_id text NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    created_at timestamptz DEFAULT now(),
    UNIQUE (proveedor_id, material_id)
);

ALTER TABLE proveedor_materiales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_proveedor_materiales" ON proveedor_materiales
    FOR ALL TO authenticated
    USING (
        proveedor_id IN (SELECT id FROM proveedores WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        proveedor_id IN (SELECT id FROM proveedores WHERE organizacion_id = get_current_org_id())
    );


-- ========== 20260907_03_compras_proveedor.sql ==========
-- Migración 3: Compras a Proveedor

CREATE TABLE IF NOT EXISTS compras_proveedor (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    folio text NOT NULL,
    cotizacion_id text REFERENCES cotizaciones(id) ON DELETE SET NULL,
    proveedor_id uuid REFERENCES proveedores(id) ON DELETE SET NULL,
    estado text DEFAULT 'Pendiente' CHECK (estado IN ('Pendiente', 'Recibida', 'Cancelada')),
    fecha timestamptz DEFAULT now(),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE compras_proveedor ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_compras_proveedor" ON compras_proveedor
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());

CREATE TABLE IF NOT EXISTS compra_items (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    compra_id uuid NOT NULL REFERENCES compras_proveedor(id) ON DELETE CASCADE,
    material_id text NOT NULL REFERENCES productos(id) ON DELETE CASCADE,
    cantidad numeric NOT NULL CHECK (cantidad > 0),
    costo_unitario numeric NOT NULL CHECK (costo_unitario >= 0),
    created_at timestamptz DEFAULT now()
);

ALTER TABLE compra_items ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_compra_items" ON compra_items
    FOR ALL TO authenticated
    USING (
        compra_id IN (SELECT id FROM compras_proveedor WHERE organizacion_id = get_current_org_id())
    )
    WITH CHECK (
        compra_id IN (SELECT id FROM compras_proveedor WHERE organizacion_id = get_current_org_id())
    );


-- ========== 20260907_04_credito_cliente.sql ==========
-- Migración 4: Crédito de cliente

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS limite_credito numeric DEFAULT 0;

CREATE OR REPLACE VIEW vista_saldo_cliente AS
SELECT 
    c.id AS cliente_id,
    c.organizacion_id,
    c.limite_credito,
    COALESCE(
        (SELECT SUM(total) FROM cotizaciones WHERE cliente_id = c.id AND estado IN ('Aprobada', 'Pagada')),
        0
    ) - COALESCE(
        (SELECT SUM(p.monto) 
         FROM pagos p 
         JOIN cotizaciones ct ON p.cotizacion_id = ct.id 
         WHERE ct.cliente_id = c.id AND ct.estado IN ('Aprobada', 'Pagada')),
        0
    ) AS saldo_usado
FROM clientes c;


-- ========== 20260907_05_estado_produccion_ampliado.sql ==========
-- Migración 5: Estado de producción ampliado
-- Nota: La columna `estado_produccion` en `cotizaciones` es de tipo `text` sin constraint CHECK,
-- por lo que soporta nativamente los nuevos valores:
-- 'Pendiente de aprobar', 'Aprobada', 'Requisición: falta material', 'Compra en curso', 'Listo para producción', 'Surtido'
-- No es necesario alterar el esquema.


-- ========== 20260907_06_cotizacion_eventos.sql ==========
-- Migración 6: Bitácora de Trazabilidad

CREATE TABLE IF NOT EXISTS cotizacion_eventos (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL REFERENCES organizaciones(id) ON DELETE CASCADE,
    cotizacion_id text NOT NULL REFERENCES cotizaciones(id) ON DELETE CASCADE,
    evento text NOT NULL,
    usuario_id uuid REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at timestamptz DEFAULT now()
);

ALTER TABLE cotizacion_eventos ENABLE ROW LEVEL SECURITY;

CREATE POLICY "rls_cotizacion_eventos" ON cotizacion_eventos
    FOR ALL TO authenticated
    USING (organizacion_id = get_current_org_id())
    WITH CHECK (organizacion_id = get_current_org_id());


-- ========== 20260907_07_movimiento_devoluciones.sql ==========
-- Migración 7: Devoluciones en Movimientos de Inventario

ALTER TABLE movimientos_inventario 
DROP CONSTRAINT IF EXISTS movimientos_inventario_tipo_movimiento_check;

ALTER TABLE movimientos_inventario 
ADD CONSTRAINT movimientos_inventario_tipo_movimiento_check 
CHECK (tipo_movimiento IN ('Entrada', 'Salida', 'Reserva', 'Liberacion', 'Ajuste', 'Devolucion_Interna', 'Devolucion_Cliente', 'Devolucion_Proveedor'));


-- ========== 20260907_08_roles_operativos.sql ==========
-- Migración 8: Roles operativos de producción

ALTER TABLE perfiles_organizacion
ADD COLUMN IF NOT EXISTS area_operativa text DEFAULT 'Ventas'
CHECK (area_operativa IN ('Ventas', 'Compras', 'Almacén', 'Gerencia', 'General'));


-- ========== 20260907_09_pagos_proveedor.sql ==========
-- Pagos a proveedores (Cuentas por Pagar)
CREATE TABLE IF NOT EXISTS pagos_proveedor (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    compra_id UUID REFERENCES compras_proveedor(id) ON DELETE CASCADE,
    monto DECIMAL(12, 2) NOT NULL,
    fecha_pago TIMESTAMPTZ DEFAULT NOW(),
    metodo_pago TEXT NOT NULL,
    referencia TEXT,
    comprobante_url TEXT,
    notas TEXT,
    usuario_id UUID,
    organizacion_id UUID,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Habilitar RLS
ALTER TABLE pagos_proveedor ENABLE ROW LEVEL SECURITY;

-- Políticas de seguridad para pagos_proveedor
CREATE POLICY "Usuarios pueden ver pagos a proveedores de su organización"
    ON pagos_proveedor FOR SELECT
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden insertar pagos a proveedores"
    ON pagos_proveedor FOR INSERT
    WITH CHECK (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden actualizar pagos a proveedores"
    ON pagos_proveedor FOR UPDATE
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));

CREATE POLICY "Usuarios pueden eliminar pagos a proveedores"
    ON pagos_proveedor FOR DELETE
    USING (organizacion_id = auth.uid() OR organizacion_id IN (
        SELECT organizacion_id FROM perfiles_organizacion WHERE usuario_id = auth.uid()
    ));


-- ========== 20260907_10_compras_vencimiento.sql ==========
-- Agregar fecha de vencimiento a compras_proveedor para programar cuentas por pagar
ALTER TABLE compras_proveedor 
ADD COLUMN IF NOT EXISTS fecha_vencimiento_pago TIMESTAMPTZ;

-- Actualizar las existentes para que venzan en 30 días si no tienen
UPDATE compras_proveedor 
SET fecha_vencimiento_pago = fecha + INTERVAL '30 days'
WHERE fecha_vencimiento_pago IS NULL;


