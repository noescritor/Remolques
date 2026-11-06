-- Migración: 20261105_03_gondola_volumen_costos_tina.sql
-- Propósito: Actualizar escala a 'por_volumen' en opcion_costos para las opciones de tina_material de góndola (A-36 y Hardox 450).
-- Idempotente y multi-tenant (sin UUIDs fijos).
--
-- Para revertir:
-- UPDATE public.opcion_costos
-- SET escala = 'fija'
-- WHERE tipo_modelo = 'gondola'
--   AND opcion_id IN (
--     SELECT oc.id
--     FROM public.opciones_configuracion oc
--     JOIN public.grupos_configuracion gc ON oc.grupo_id = gc.id
--     WHERE gc.clave = 'tina_material' AND oc.clave IN ('a36', 'hardox_450')
--   );

BEGIN;

UPDATE public.opcion_costos
SET escala = 'por_volumen'
WHERE tipo_modelo = 'gondola'
  AND opcion_id IN (
    SELECT oc.id
    FROM public.opciones_configuracion oc
    JOIN public.grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave IN ('a36', 'hardox_450')
  );

COMMIT;
