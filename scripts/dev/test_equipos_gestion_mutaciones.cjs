/**
 * Pruebas de mutación sobre:
 * 1) motor/equipos_gestion.ts (10 mutaciones de reglas de negocio)
 * 2) Los 12 filtros de equipos cancelados repartidos en:
 *    plan_produccion.ts, calidad.ts, cobros.ts, checklist_almacen.ts, generar_ordenes_cotizacion.ts
 *    (+ listarPlanesPago en cobros.ts)
 * Verifica empíricamente que quitar CUALQUIERA de estas guardas hace fallar deno test.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const MOTOR_DIR = path.resolve(__dirname, '../../supabase/functions/make-server-feea4382/motor');
const TEST_FILES = [
  path.join(MOTOR_DIR, 'equipos_gestion.test.ts'),
  path.join(MOTOR_DIR, 'equipos_filtros_cancelados.test.ts'),
];

const MUTACIONES = [
  // --- Reglas en equipos_gestion.ts (10) ---
  {
    id: 'M1_rol_sin_check',
    file: 'equipos_gestion.ts',
    desc: 'Permitir cualquier rol (quitar check ROLES_GESTION_EQUIPOS)',
    buscar: 'if (!ROLES_GESTION_EQUIPOS.has(rol)) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M2_rol_vendedor',
    file: 'equipos_gestion.ts',
    desc: 'Agregar vendedor a ROLES_GESTION_EQUIPOS',
    buscar: 'new Set(["admin", "propietario"])',
    reemplazar: 'new Set(["admin", "propietario", "vendedor"])',
  },
  {
    id: 'M3_fecha_calendario',
    file: 'equipos_gestion.ts',
    desc: 'Quitar validación de fecha calendario real (acepta 2026-02-30)',
    buscar: 'dt.getUTCFullYear() !== anio ||\n    dt.getUTCMonth() !== mes - 1 ||\n    dt.getUTCDate() !== dia',
    reemplazar: 'false',
  },
  {
    id: 'M4_cobros_409_a_400',
    file: 'equipos_gestion.ts',
    desc: 'Cambiar status de orden_con_cobros_vigentes de 409 a 400',
    buscar: 'case "orden_con_cobros_vigentes":\n      return new EquiposGestionError(409, prefijo, limpio, detailObj);',
    reemplazar: 'case "orden_con_cobros_vigentes":\n      return new EquiposGestionError(400, prefijo, limpio, detailObj);',
  },
  {
    id: 'M5_material_sin_bandera',
    file: 'equipos_gestion.ts',
    desc: 'Quitar bandera requiere_confirmacion_material en orden_con_material_entregado',
    buscar: 'requiere_confirmacion_material: true,',
    reemplazar: 'requiere_confirmacion_material: false,',
  },
  {
    id: 'M6_origen_cotizacion_400',
    file: 'equipos_gestion.ts',
    desc: 'Cambiar status de orden_origen_cotizacion/orden_cancelada de 409 a 400',
    buscar: 'case "orden_origen_cotizacion":\n    case "orden_cancelada":\n      return new EquiposGestionError(409, prefijo, limpio, detailObj);',
    reemplazar: 'case "orden_origen_cotizacion":\n    case "orden_cancelada":\n      return new EquiposGestionError(400, prefijo, limpio, detailObj);',
  },
  {
    id: 'M7_motivo_vacio_permitido',
    file: 'equipos_gestion.ts',
    desc: 'Quitar validación de motivo vacío antes de RPC cancelar',
    buscar: 'if (!motivo) {\n    throw new EquiposGestionError(',
    reemplazar: 'if (false && !motivo) {\n    throw new EquiposGestionError(',
  },
  {
    id: 'M8_confirmo_material_forzado_true',
    file: 'equipos_gestion.ts',
    desc: 'Forzar p_confirmo_material_entregado a true siempre',
    buscar: 'p_confirmo_material_entregado: Boolean(params.confirmoMaterialEntregado),',
    reemplazar: 'p_confirmo_material_entregado: true,',
  },
  {
    id: 'M9_cambiar_cliente_sin_validacion',
    file: 'equipos_gestion.ts',
    desc: 'Permitir cambiar cliente sin clienteId ni etiqueta',
    buscar: 'if (!clienteId && !etiqueta) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M10_listar_sin_filtro_canceladas',
    file: 'equipos_gestion.ts',
    desc: 'Quitar filtro is("cancelada_el", null) al listar activas',
    buscar: 'query = query\n      .is("cancelada_el", null)',
    reemplazar: 'query = query\n      /* mutado */',
  },

  // --- Los 12 filtros de equipos cancelados (R2 punto 4) + listarPlanesPago ---
  {
    id: 'F1_plan_produccion_480',
    file: 'plan_produccion.ts',
    desc: 'Quitar filtro !t.orden_trabajo?.cancelada_el en obtenerPlanProduccion',
    buscar: '.filter((t: any) => !t.orden_trabajo?.cancelada_el)',
    reemplazar: '.filter(() => true)',
  },
  {
    id: 'F2_plan_produccion_947',
    file: 'plan_produccion.ts',
    desc: 'Quitar filtro !t.orden_trabajo?.cancelada_el en obtenerTrazabilidadOperario',
    buscar: '.filter((t: any) => Boolean(t) && !t.orden_trabajo?.cancelada_el)',
    reemplazar: '.filter((t: any) => Boolean(t))',
  },
  {
    id: 'F3_calidad_379',
    file: 'calidad.ts',
    desc: 'Quitar filtro !insp.orden?.cancelada_el en listarInspeccionesCalidad',
    buscar: '.filter((insp: any) => !insp.orden?.cancelada_el)',
    reemplazar: '.filter(() => true)',
  },
  {
    id: 'F4_cobros_390',
    file: 'cobros.ts',
    desc: 'Quitar .is("cancelada_el", null) en obtenerCobranzaCotizacion',
    buscar: '.eq("cotizacion_id", cotizacionId)\n      .eq("organizacion_id", orgId)\n      .is("cancelada_el", null)',
    reemplazar: '.eq("cotizacion_id", cotizacionId)\n      .eq("organizacion_id", orgId)',
  },
  {
    id: 'F5_cobros_551',
    file: 'cobros.ts',
    desc: 'Quitar chequeo orden.cancelada_el en obtenerCobranzaEquipo',
    buscar: 'if (ordErr || !orden || orden.cancelada_el) {',
    reemplazar: 'if (ordErr || !orden) {',
  },
  {
    id: 'F6_cobros_611',
    file: 'cobros.ts',
    desc: 'Quitar chequeo orden.cancelada_el en guardarValorEquipo',
    buscar: 'if (orden.cancelada_el) {\n    throw new CobrosError(409, "orden_cancelada"',
    reemplazar: 'if (false && orden.cancelada_el) {\n    throw new CobrosError(409, "orden_cancelada"',
  },
  {
    id: 'F6b_cobros_listar_planes',
    file: 'cobros.ts',
    desc: 'Quitar filtro de equipo cancelado en listarPlanesPago',
    buscar: '.filter((p: any) => !p.orden_trabajo_id || !p.orden_trabajo?.cancelada_el)',
    reemplazar: '.filter(() => true)',
  },
  {
    id: 'F7_checklist_73',
    file: 'checklist_almacen.ts',
    desc: 'Quitar chequeo otCheck.cancelada_el en listarDespieceOT',
    buscar: 'if (otCheck && otCheck.cancelada_el) {',
    reemplazar: 'if (false && otCheck && otCheck.cancelada_el) {',
  },
  {
    id: 'F8_checklist_189',
    file: 'checklist_almacen.ts',
    desc: 'Quitar chequeo ot.cancelada_el en generarDespieceOT',
    buscar: 'if (ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se puede generar despiece',
    reemplazar: 'if (false && ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se puede generar despiece',
  },
  {
    id: 'F9_checklist_562',
    file: 'checklist_almacen.ts',
    desc: 'Quitar chequeo ot.cancelada_el en entregarFaseCompleta',
    buscar: 'if (ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se puede entregar material',
    reemplazar: 'if (false && ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se puede entregar material',
  },
  {
    id: 'F10_checklist_665',
    file: 'checklist_almacen.ts',
    desc: 'Quitar chequeo ot.cancelada_el en agregarLineaManual',
    buscar: 'if (ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se pueden agregar líneas de despiece',
    reemplazar: 'if (false && ot.cancelada_el) {\n    throw new Error("orden_cancelada: No se pueden agregar líneas de despiece',
  },
  {
    id: 'F11_generar_ordenes_447',
    file: 'generar_ordenes_cotizacion.ts',
    desc: 'Quitar .is("cancelada_el", null) en actualizarOrdenTrabajoSegura',
    buscar: '.eq("id", id)\n    .eq("organizacion_id", orgId)\n    .is("cancelada_el", null)\n    .select()',
    reemplazar: '.eq("id", id)\n    .eq("organizacion_id", orgId)\n    .select()',
  },
  {
    id: 'F12_generar_ordenes_482',
    file: 'generar_ordenes_cotizacion.ts',
    desc: 'Quitar chequeo orden.cancelada_el en regenerarFichaDeOrden',
    buscar: 'if (orden.cancelada_el) {\n    const err = new Error("No se puede regenerar la ficha',
    reemplazar: 'if (false && orden.cancelada_el) {\n    const err = new Error("No se puede regenerar la ficha',
  },
];

function correrTests() {
  const res = spawnSync('deno', ['test', '--allow-all', ...TEST_FILES], {
    encoding: 'utf8',
  });
  return res.status === 0;
}

if (!correrTests()) {
  console.error('La suite base no pasó antes de mutar.');
  process.exit(1);
}

let muertas = 0;
let vivas = [];

for (const m of MUTACIONES) {
  const filePath = path.join(MOTOR_DIR, m.file);
  const original = fs.readFileSync(filePath, 'utf8');
  const normOrig = original.replace(/\r\n/g, '\n');
  if (!normOrig.includes(m.buscar)) {
    console.error(`[ERROR] Patrón no encontrado para ${m.id} en ${m.file}`);
    process.exit(1);
  }
  const mutado = normOrig.replace(m.buscar, m.reemplazar);
  try {
    fs.writeFileSync(filePath, mutado, 'utf8');
    const paso = correrTests();
    if (!paso) {
      muertas++;
      console.log(`[MUERTA] ${m.id} — ${m.desc}`);
    } else {
      vivas.push(m.id);
      console.log(`[VIVA]   ${m.id} — ${m.desc}`);
    }
  } finally {
    fs.writeFileSync(filePath, original, 'utf8');
  }
}

console.log(`\nResumen mutaciones: ${muertas}/${MUTACIONES.length} muertas, ${vivas.length} vivas.`);
if (vivas.length > 0) {
  process.exit(1);
}
