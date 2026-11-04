-- =========================================================================
-- Prueba de Concurrencia de Dos Sesiones para T6 (Editor de Recetas)
-- =========================================================================
-- Demuestra el bloqueo pesimista FOR UPDATE OF rb en guardar_linea_receta y
-- eliminar_linea_receta evitando carreras de historial y ediciones fantasma.
--
-- Ejecutar en dos terminales psql separadas conectadas a la base de prueba:
--   psql -h localhost -p 54331 -U tester -d <base_desechable>
-- =========================================================================

-- PREPARACIÓN (Ejecutar en Sesión 1 antes de comenzar):
/*
BEGIN;
SELECT id INTO TEMP TABLE t_mod FROM modelos WHERE organizacion_id = '11111111-1111-1111-1111-111111111111' LIMIT 1;
SELECT id INTO TEMP TABLE t_fase FROM fases_despiece WHERE organizacion_id = '11111111-1111-1111-1111-111111111111' LIMIT 1;
SELECT id INTO TEMP TABLE t_mat FROM productos WHERE organizacion_id = '11111111-1111-1111-1111-111111111111' AND tipo_item = 'materia_prima' LIMIT 1;

-- Crear línea inicial con cantidad 2
SELECT guardar_linea_receta(
    (SELECT id FROM t_mod),
    (SELECT id FROM t_mat),
    2.0,
    'fija',
    (SELECT id FROM t_fase),
    '11111111-1111-1111-1111-111111111111',
    p_motivo => 'Línea base concurrencia'
) AS linea_id;
COMMIT;
*/

-- =========================================================================
-- ESCENARIO A: Dos sesiones actualizan la misma línea a la vez (2 -> 5 y 2 -> 7)
-- =========================================================================
-- Sesión 1 inicia transacción, actualiza a 5 y duerme 3 segundos manteniendo el lock FOR UPDATE.
-- Sesión 2 intenta actualizar a 7 simultáneamente; queda bloqueada esperando a Sesión 1.
-- Al hacer COMMIT en Sesión 1, Sesión 2 adquiere el lock, lee los datos vigentes (5),
-- actualiza a 7 y registra en historial: datos_anteriores = 5, datos_nuevos = 7.

-- SESIÓN 1:
-- BEGIN;
-- SELECT guardar_linea_receta('<modelo_id>', '<mat_id>', 5.0, 'fija', '<fase_id>', '11111111-1111-1111-1111-111111111111', p_linea_id => '<linea_id>');
-- SELECT pg_sleep(3);
-- COMMIT;

-- SESIÓN 2 (Lanzada inmediatamente después de Sesión 1):
-- BEGIN;
-- SELECT guardar_linea_receta('<modelo_id>', '<mat_id>', 7.0, 'fija', '<fase_id>', '11111111-1111-1111-1111-111111111111', p_linea_id => '<linea_id>');
-- COMMIT;

-- VERIFICACIÓN ESCENARIO A:
-- SELECT accion, (datos_anteriores->>'cantidad')::numeric AS cant_ant, (datos_nuevos->>'cantidad')::numeric AS cant_nueva, created_at
-- FROM receta_base_historial WHERE linea_id = '<linea_id>' ORDER BY created_at ASC;
-- Resultado esperado:
-- 1. crear_linea:    NULL -> 2.0
-- 2. modificar_linea: 2.0  -> 5.0  (Sesión 1)
-- 3. modificar_linea: 5.0  -> 7.0  (Sesión 2 leyó 5.0 gracias a FOR UPDATE)


-- =========================================================================
-- ESCENARIO B: Sesión 1 borra la línea mientras Sesión 2 intenta editarla
-- =========================================================================
-- Sesión 1 adquiere FOR UPDATE y elimina la línea, manteniendo la transacción abierta 3 segundos.
-- Sesión 2 intenta modificar la línea; se bloquea en FOR UPDATE.
-- Cuando Sesión 1 hace COMMIT, la fila ha sido eliminada.
-- Sesión 2 despierta, detecta que la fila no existe (v_ant_data IS NULL o NOT FOUND),
-- y aborta arrojando: 'linea_no_encontrada: La línea de receta ... no existe o no pertenece al modelo'.
-- NO se registra ninguna modificación fantasma en receta_base_historial.

-- SESIÓN 1:
-- BEGIN;
-- SELECT eliminar_linea_receta('<linea_id>', '11111111-1111-1111-1111-111111111111', '<modelo_id>', p_motivo => 'Borrado concurrente');
-- SELECT pg_sleep(3);
-- COMMIT;

-- SESIÓN 2 (Lanzada inmediatamente después de Sesión 1):
-- BEGIN;
-- SELECT guardar_linea_receta('<modelo_id>', '<mat_id>', 9.0, 'fija', '<fase_id>', '11111111-1111-1111-1111-111111111111', p_linea_id => '<linea_id>');
-- -- Resultado: ERROR: linea_no_encontrada: La línea de receta ... no existe o no pertenece al modelo
-- ROLLBACK;
