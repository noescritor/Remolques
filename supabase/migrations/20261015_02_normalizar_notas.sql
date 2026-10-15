-- Migración: Normalizar notas heredadas en opcion_costos y costos_modelo
-- Idempotente: limpia textos descriptivos incrustados en 'notas' moviéndolos a 'fuente',
-- dejando notas = 'import-2r1e' e 'import-2r1c' de manera exacta.

BEGIN;

DO $$
DECLARE
    v_actualizadas_dolly INT := 0;
    v_actualizadas_pintura INT := 0;
BEGIN
    -- 1. Normalizar opcion_costos del Dolly (5 filas de rines y llantas con notas descriptivas)
    UPDATE opcion_costos
    SET fuente = 'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)',
        notas = 'import-2r1e'
    WHERE tipo_modelo = 'dolly'
      AND notas LIKE '%; import-2r1e';
    GET DIAGNOSTICS v_actualizadas_dolly = ROW_COUNT;

    -- 2. Normalizar costos_modelo de Plataforma (1 fila de pintura con notas descriptivas)
    UPDATE costos_modelo
    SET fuente = 'Factura Leolca (cantidad original: 1 1/2 cubeta)',
        notas = 'import-2r1c'
    WHERE notas LIKE '%1 1/2 Cubeta%import-2r1c%';
    GET DIAGNOSTICS v_actualizadas_pintura = ROW_COUNT;

    RAISE NOTICE 'Notas normalizadas: dolly opcion_costos = %, plataforma pintura costos_modelo = %',
        v_actualizadas_dolly, v_actualizadas_pintura;
END $$;

COMMIT;
