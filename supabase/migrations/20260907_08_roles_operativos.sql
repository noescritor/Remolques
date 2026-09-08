-- Migración 8: Roles operativos de producción

ALTER TABLE perfiles_organizacion
ADD COLUMN IF NOT EXISTS area_operativa text DEFAULT 'Ventas'
CHECK (area_operativa IN ('Ventas', 'Compras', 'Almacén', 'Gerencia', 'General'));
