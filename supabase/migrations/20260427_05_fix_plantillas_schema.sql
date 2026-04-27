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
