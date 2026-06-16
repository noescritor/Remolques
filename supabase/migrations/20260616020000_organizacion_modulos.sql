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
