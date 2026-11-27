/**
 * Pruebas de mutación sobre supabase/functions/make-server-feea4382/motor/cuentas_permisos.ts
 * Verifica que la suite cuentas_permisos.test.ts mata cada mutación sobre los controles de acceso y paginación.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const TARGET = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/cuentas_permisos.ts'
);
const TEST_FILE = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/cuentas_permisos.test.ts'
);

const MUTACIONES = [
  {
    id: 'M1_rol_admin_desactivado',
    desc: 'Permitir cualquier rol en exigirAdminOPropietario',
    buscar: 'if (!ROLES_ADMINISTRADORES.has(rol)) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M2_agregar_usuario_a_admins',
    desc: 'Incluir usuario en ROLES_ADMINISTRADORES',
    buscar: 'new Set(["admin", "propietario"])',
    reemplazar: 'new Set(["admin", "propietario", "usuario"])',
  },
  {
    id: 'M3_superadmin_sin_check_org',
    desc: 'Quitar check de organización principal en exigirSuperAdminOrgPrincipal',
    buscar: 'if (!params.orgId || params.orgId !== params.orgPrincipalId) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M4_superadmin_sin_check_rol',
    desc: 'Quitar validación de rol en exigirSuperAdminOrgPrincipal',
    buscar: 'return await exigirAdminOPropietario(',
    reemplazar: 'return "propietario"; /* mutado */ await exigirAdminOPropietario(',
  },
  {
    id: 'M5_permitir_invitar_propietario',
    desc: 'Permitir invitar con rol propietario en crearInvitacionSegura',
    buscar: 'if (rolNorm === "propietario") {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M6_borrar_invitacion_sin_org',
    desc: 'Quitar filtro organizacion_id al borrar invitación',
    buscar: '.eq("id", params.invitacionId)\n    .eq("organizacion_id", params.orgId);',
    reemplazar: '.eq("id", params.invitacionId);',
  },
  {
    id: 'M7_listar_equipo_sin_paginacion',
    desc: 'Cortar listUsers en la primera página (pierde usuarios >50)',
    buscar: 'if (users.length < perPage) {\n      break;\n    }',
    reemplazar: 'break;',
  },
  {
    id: 'M8_listar_equipo_sin_org',
    desc: 'Quitar filtro organizacion_id en listarEquipoOrganizacion',
    buscar: '.from("perfiles_organizacion")\n    .select("*")\n    .eq("organizacion_id", orgId);',
    reemplazar: '.from("perfiles_organizacion")\n    .select("*");',
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
const vivas = [];

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
