-- ============================================================================
-- 02b_correccion_recetas_1oct.sql
-- Borra SOLO las recetas planas de las 10 "PLATAFORMA n FT" creadas por
-- 20261001_03_migracion_bom.sql. No toca productos, materiales ni cotizaciones.
--
-- Base del conteo: resultado de 01c_productos_terminados.sql (6-oct-2026)
--   3 productos con 68 líneas  (35 ft x2, 40 ft x2, 40 ft x3)  = 204
--   7 productos con 65 líneas  (42/45/48 ft x2, 42/43/45/48 ft x3) = 455
--   TOTAL esperado = 659 líneas
--
-- SALVAGUARDAS
--   1) Copia de respaldo de TODA la tabla dentro de la base (con RLS activado
--      y sin políticas, para que no sea legible por la API).
--   2) Si el número de líneas a borrar NO es 659, el script falla y no borra nada.
--   3) Todo va en una sola transacción.
-- RECOMENDADO ANTES: pg_dump completo guardado fuera del servidor.
--
-- Para deshacer después:
--   INSERT INTO producto_materiales SELECT * FROM _bak_20261006_producto_materiales
--   ON CONFLICT DO NOTHING;
-- ============================================================================
BEGIN;

CREATE TABLE IF NOT EXISTS _bak_20261006_producto_materiales AS
  TABLE producto_materiales;
ALTER TABLE _bak_20261006_producto_materiales ENABLE ROW LEVEL SECURITY;

DO $$
DECLARE
  borradas integer;
BEGIN
  WITH d AS (
    DELETE FROM producto_materiales
    WHERE producto_id IN (
      SELECT id FROM productos
      WHERE tipo_item = 'producto_terminado'
        AND nombre IN (
          'PLATAFORMA 2 35 FT', 'PLATAFORMA 2 40 FT', 'PLATAFORMA 2 42 FT',
          'PLATAFORMA 2 45 FT', 'PLATAFORMA 2 48 FT', 'PLATAFORMA 3 40 FT',
          'PLATAFORMA 3 42 FT', 'PLATAFORMA 3 43 FT', 'PLATAFORMA 3 45 FT',
          'PLATAFORMA 3 48 FT')
    )
    RETURNING 1
  )
  SELECT count(*) INTO borradas FROM d;

  IF borradas <> 659 THEN
    RAISE EXCEPTION 'Se esperaban 659 líneas y se iban a borrar %. No se borra nada.', borradas;
  END IF;

  RAISE NOTICE 'Líneas de receta borradas: %', borradas;
END
$$;

COMMIT;

-- Verificación posterior (debe dar 0 líneas para las 10 plataformas):
SELECT p.nombre, count(pm.id) AS lineas
FROM productos p
LEFT JOIN producto_materiales pm ON pm.producto_id = p.id
WHERE p.tipo_item = 'producto_terminado' AND p.nombre LIKE 'PLATAFORMA%'
GROUP BY p.nombre ORDER BY p.nombre;
