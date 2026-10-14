/**
 * Generador de migración para normalizar notas heredadas (2R-1g corrección)
 * Genera: supabase/migrations/20261015_02_normalizar_notas.sql
 */

const fs = require('fs');
const path = require('path');

const outSqlPath = path.resolve(__dirname, '../supabase/migrations/20261015_02_normalizar_notas.sql');

function generarSql() {
  const lines = [];

  lines.push('-- Migración: Normalizar notas heredadas en opcion_costos y costos_modelo');
  lines.push('-- Idempotente: limpia textos descriptivos incrustados en \'notas\' moviéndolos a \'fuente\',');
  lines.push('-- dejando notas = \'import-2r1e\' e \'import-2r1c\' de manera exacta.');
  lines.push('');
  lines.push('BEGIN;');
  lines.push('');
  lines.push('DO $$');
  lines.push('DECLARE');
  lines.push('    v_actualizadas_dolly INT := 0;');
  lines.push('    v_actualizadas_pintura INT := 0;');
  lines.push('BEGIN');
  lines.push('    -- 1. Normalizar opcion_costos del Dolly (5 filas de rines y llantas con notas descriptivas)');
  lines.push('    UPDATE opcion_costos');
  lines.push('    SET fuente = \'Factura Leolca (cantidad por eje supuesta igual a plataforma y góndola)\',');
  lines.push('        notas = \'import-2r1e\'');
  lines.push('    WHERE tipo_modelo = \'dolly\'');
  lines.push('      AND notas LIKE \'%; import-2r1e\';');
  lines.push('    GET DIAGNOSTICS v_actualizadas_dolly = ROW_COUNT;');
  lines.push('');
  lines.push('    -- 2. Normalizar costos_modelo de Plataforma (1 fila de pintura con notas descriptivas)');
  lines.push('    UPDATE costos_modelo');
  lines.push('    SET fuente = \'Factura Leolca (cantidad original: 1 1/2 cubeta)\',');
  lines.push('        notas = \'import-2r1c\'');
  lines.push('    WHERE notas LIKE \'%1 1/2 Cubeta%import-2r1c%\';');
  lines.push('    GET DIAGNOSTICS v_actualizadas_pintura = ROW_COUNT;');
  lines.push('');
  lines.push('    RAISE NOTICE \'Notas normalizadas: dolly opcion_costos = %, plataforma pintura costos_modelo = %\',');
  lines.push('        v_actualizadas_dolly, v_actualizadas_pintura;');
  lines.push('END $$;');
  lines.push('');
  lines.push('COMMIT;');
  lines.push('');

  fs.writeFileSync(outSqlPath, lines.join('\n'), 'utf8');
  console.log(`Migración generada exitosamente en ${outSqlPath}`);
}

generarSql();
