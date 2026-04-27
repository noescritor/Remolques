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
