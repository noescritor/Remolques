-- Migración 20261013_01_costos_derivados.sql
-- Sub-bloque 2R-1d: Costos derivados de variantes de plataforma
-- Idempotente, una sola transacción.

BEGIN;

-- 1. Agregar columna costos_derivados_de en tabla modelos
ALTER TABLE modelos ADD COLUMN IF NOT EXISTS costos_derivados_de uuid REFERENCES modelos(id) ON DELETE SET NULL;

COMMENT ON COLUMN modelos.costos_derivados_de IS 'ID del modelo del cual se derivaron o copiaron los costos (NULL = costos propios medidos)';

-- 2. Actualizar escala a 'por_largo' para las opciones de piso de plataforma insertadas en 2R-1c
UPDATE opcion_costos
SET escala = 'por_largo'
WHERE tipo_modelo = 'plataforma'
  AND notas = 'import-2r1c'
  AND opcion_id IN (
    SELECT oc.id
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'piso'
      AND oc.clave IN ('laminado_madera', 'laminado_plastico')
  );

COMMIT;
