/**
 * Pruebas de mutación sobre supabase/functions/make-server-feea4382/motor/equipos_gestion.ts
 * Verifica que la suite Deno (equipos_gestion.test.ts) mata cada mutación sobre las reglas de negocio.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const TARGET = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/equipos_gestion.ts'
);
const TEST_FILE = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/equipos_gestion.test.ts'
);

const MUTACIONES = [
  {
    id: 'M1_rol_sin_check',
    desc: 'Permitir cualquier rol (quitar check ROLES_GESTION_EQUIPOS)',
    buscar: 'if (!ROLES_GESTION_EQUIPOS.has(rol)) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M2_rol_vendedor',
    desc: 'Agregar vendedor a ROLES_GESTION_EQUIPOS',
    buscar: 'new Set(["admin", "propietario"])',
    reemplazar: 'new Set(["admin", "propietario", "vendedor"])',
  },
  {
    id: 'M3_fecha_calendario',
    desc: 'Quitar validación de fecha calendario real (acepta 2026-02-30)',
    buscar: 'dt.getUTCFullYear() !== anio ||\n    dt.getUTCMonth() !== mes - 1 ||\n    dt.getUTCDate() !== dia',
    reemplazar: 'false',
  },
  {
    id: 'M4_cobros_409_a_400',
    desc: 'Cambiar status de orden_con_cobros_vigentes de 409 a 400',
    buscar: 'case "orden_con_cobros_vigentes":\n      return new EquiposGestionError(409, prefijo, limpio, detailObj);',
    reemplazar: 'case "orden_con_cobros_vigentes":\n      return new EquiposGestionError(400, prefijo, limpio, detailObj);',
  },
  {
    id: 'M5_material_sin_bandera',
    desc: 'Quitar bandera requiere_confirmacion_material en orden_con_material_entregado',
    buscar: 'requiere_confirmacion_material: true,',
    reemplazar: 'requiere_confirmacion_material: false,',
  },
  {
    id: 'M6_origen_cotizacion_400',
    desc: 'Cambiar status de orden_origen_cotizacion/orden_cancelada de 409 a 400',
    buscar: 'case "orden_origen_cotizacion":\n    case "orden_cancelada":\n      return new EquiposGestionError(409, prefijo, limpio, detailObj);',
    reemplazar: 'case "orden_origen_cotizacion":\n    case "orden_cancelada":\n      return new EquiposGestionError(400, prefijo, limpio, detailObj);',
  },
  {
    id: 'M7_motivo_vacio_permitido',
    desc: 'Quitar validación de motivo vacío antes de RPC cancelar',
    buscar: 'if (!motivo) {\n    throw new EquiposGestionError(',
    reemplazar: 'if (false && !motivo) {\n    throw new EquiposGestionError(',
  },
  {
    id: 'M8_confirmo_material_forzado_true',
    desc: 'Forzar p_confirmo_material_entregado a true siempre',
    buscar: 'p_confirmo_material_entregado: Boolean(params.confirmoMaterialEntregado),',
    reemplazar: 'p_confirmo_material_entregado: true,',
  },
  {
    id: 'M9_cambiar_cliente_sin_validacion',
    desc: 'Permitir cambiar cliente sin clienteId ni etiqueta',
    buscar: 'if (!clienteId && !etiqueta) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M10_listar_sin_filtro_canceladas',
    desc: 'Quitar filtro is("cancelada_el", null) al listar activas',
    buscar: 'query = query\n      .is("cancelada_el", null)',
    reemplazar: 'query = query\n      /* mutado */',
  },
];

function correrTests() {
  const res = spawnSync('deno', ['test', '--allow-all', TEST_FILE], {
    encoding: 'utf8',
  });
  return res.status === 0;
}

const original = fs.readFileSync(TARGET, 'utf8');
let muertas = 0;
let vivas = [];

try {
  if (!correrTests()) {
    console.error('La suite base no pasó antes de mutar.');
    process.exit(1);
  }

  for (const m of MUTACIONES) {
    const normOrig = original.replace(/\r\n/g, '\n');
    if (!normOrig.includes(m.buscar)) {
      console.error(`[ERROR] Patrón no encontrado para ${m.id}`);
      process.exit(1);
    }
    const mutado = normOrig.replace(m.buscar, m.reemplazar);
    fs.writeFileSync(TARGET, mutado, 'utf8');
    const paso = correrTests();
    if (!paso) {
      muertas++;
      console.log(`[MUERTA] ${m.id} — ${m.desc}`);
    } else {
      vivas.push(m.id);
      console.log(`[VIVA]   ${m.id} — ${m.desc}`);
    }
  }
} finally {
  fs.writeFileSync(TARGET, original, 'utf8');
}

console.log(`\nResumen mutaciones: ${muertas}/${MUTACIONES.length} muertas, ${vivas.length} vivas.`);
if (vivas.length > 0) {
  process.exit(1);
}
