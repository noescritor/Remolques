-- Prueba de concurrencia real en dos sesiones para Bloque E1
-- Se ejecuta con dos conexiones psql en paralelo contra test_cobros_e1 (verificado vía script PowerShell/Node).
--
-- Escenario A: Dos sesiones llaman registrar_cobro simultáneamente por 60,000 cada una
-- sobre una cotización de 100,000 sin permitir_excedente:
--   Sesión 1 obtiene FOR UPDATE sobre cotizaciones, inserta 60,000 y hace COMMIT.
--   Sesión 2 espera el lock FOR UPDATE, ve saldo_pendiente = 40,000 < 60,000 y falla con saldo_excedido.
--   Resultado: exactamente 1 pago vigente de 60,000.
--
-- Escenario B: Dos sesiones llaman anular_cobro simultáneamente sobre el mismo pago:
--   Sesión 1 obtiene FOR UPDATE sobre pagos, marca estado='anulado' y devuelve ok.
--   Sesión 2 espera el lock FOR UPDATE, ve estado='anulado' y falla con cobro_ya_anulado.
--   Resultado: exactamente 1 anulación efectiva.

\set ON_ERROR_STOP on
SELECT 'Ver instrucciones y ejecutar con 2 sesiones paralelas contra test_cobros_e1' AS nota;
