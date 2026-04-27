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
