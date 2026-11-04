-- Guion de prueba de concurrencia y bloqueo FOR UPDATE entre dos sesiones simultáneas (T3)
-- Diseñado para ejecutarse en dos ventanas de psql o scripts paralelos conectados a la BD local

-- =====================================================================================
-- ESCENARIO 1: Fase completa atómica contra entrega individual en la misma línea
-- =====================================================================================
-- Sesión 1 (Retenida con pg_sleep dentro de la transacción):
/*
BEGIN;
SELECT registrar_entrega_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_linea_id := '<LINEA_ID>',
    p_cantidad := 2,
    p_tipo := 'entrega',
    p_operario_nombre := 'Operario S1'
);
SELECT pg_sleep(3); -- Mantiene el lock FOR UPDATE durante 3 segundos
COMMIT;
*/

-- Sesión 2 (Ejecutada inmediatamente después de iniciar S1):
/*
-- S2 se bloquea esperando la liberación de fila por S1.
-- Al despertar tras 3 segundos, detecta que la cantidad requerida ya fue satisfecha
-- y arroja la excepción controlada excede_requerido sin corromper datos.
SELECT registrar_entrega_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_linea_id := '<LINEA_ID>',
    p_cantidad := 1,
    p_tipo := 'entrega',
    p_operario_nombre := 'Operario S2'
);
-- Resultado esperado: ERROR: excede_requerido: La cantidad 1 excede el saldo pendiente 0
*/

-- =====================================================================================
-- ESCENARIO 2: Anulación con bloqueo dual FOR UPDATE contra entrega
-- =====================================================================================
-- Sesión 1:
/*
BEGIN;
SELECT anular_entrega_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_entrega_id := '<ENTREGA_ID>',
    p_motivo := 'Anulacion concurrente S1'
);
SELECT pg_sleep(2.5);
COMMIT;
*/

-- Sesión 2:
/*
-- S2 espera a que termine la anulación y lee el saldo pendiente restaurado.
SELECT registrar_entrega_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_linea_id := '<LINEA_ID>',
    p_cantidad := 2,
    p_tipo := 'entrega',
    p_operario_nombre := 'Operario S2'
);
-- Resultado esperado: Éxito tras esperar la liberación de la anulación.
*/

-- =====================================================================================
-- ESCENARIO 3: Dos "entregar_fase_despiece" simultáneas sobre la misma OT y fase
-- =====================================================================================
-- Sesión 1:
/*
BEGIN;
SELECT entregar_fase_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_orden_trabajo_id := '<OT_ID>',
    p_equipo_indice := 1,
    p_fase_id := '<FASE_ID>',
    p_operario_nombre := 'Operario Fase S1'
);
SELECT pg_sleep(2.5);
COMMIT;
*/

-- Sesión 2:
/*
-- S2 espera y al ejecutar encuentra 0 piezas pendientes; entrega 0 líneas sin duplicar.
SELECT entregar_fase_despiece(
    p_org_id := '00000000-0000-0000-0000-000000000001',
    p_orden_trabajo_id := '<OT_ID>',
    p_equipo_indice := 1,
    p_fase_id := '<FASE_ID>',
    p_operario_nombre := 'Operario Fase S2'
);
-- Resultado esperado: {"lineas_entregadas": 0, "detalles": []}
*/
