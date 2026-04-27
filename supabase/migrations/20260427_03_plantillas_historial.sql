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
