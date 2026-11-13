-- Asigna fase_id a las 61 líneas de receta_base de PLATAFORMA 3 43 FT que quedaron sin fase
-- (líneas de acero interpoladas después de 20261102_01_despiece_union.sql, con paso NULL).
-- Criterio: se copia la fase del mismo material en PLATAFORMA 3 42 FT, solo si ese material
-- tiene exactamente UNA fase allí. Idempotente: solo toca líneas con fase_id NULL.
--
-- Verificación previa en producción (2026-11-13): las 61 líneas tenían exactamente 1 fase en la 42 ft
-- (0 sin coincidencia, 0 ambiguas). Resultado esperado: UPDATE 61; la 43 ft queda en 202/202.

WITH ref AS (
  SELECT r.material_id, (array_agg(DISTINCT r.fase_id))[1] AS fase_id
  FROM receta_base r
  JOIN modelos m ON m.id = r.modelo_id
  JOIN productos pm ON pm.id = m.producto_id
  WHERE pm.nombre = 'PLATAFORMA 3 42 FT' AND r.fase_id IS NOT NULL
  GROUP BY r.material_id
  HAVING count(DISTINCT r.fase_id) = 1
)
UPDATE receta_base t
SET fase_id = ref.fase_id
FROM ref, modelos m, productos pm
WHERE t.material_id = ref.material_id
  AND t.fase_id IS NULL
  AND m.id = t.modelo_id AND pm.id = m.producto_id
  AND pm.nombre = 'PLATAFORMA 3 43 FT';
