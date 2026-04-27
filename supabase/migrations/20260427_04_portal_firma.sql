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
