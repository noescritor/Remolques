/**
 * Pruebas de mutación sobre:
 *  A) supabase/functions/make-server-feea4382/motor/cuentas_permisos.ts (motor)
 *  B) supabase/functions/make-server-feea4382/index.ts (rutas HTTP reales)
 * Verifica que las suites de pruebas matan cada mutación que relaja o elimina los controles.
 */

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const MOTOR_TARGET = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/cuentas_permisos.ts'
);
const MOTOR_TEST = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/motor/cuentas_permisos.test.ts'
);

const INDEX_TARGET = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/index.ts'
);
const RUTAS_TEST = path.resolve(
  __dirname,
  '../../supabase/functions/make-server-feea4382/cuentas_permisos_rutas.test.ts'
);

const MUTACIONES_MOTOR = [
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
  {
    id: 'M9_eliminar_cliente_sin_check_equipos',
    desc: 'Quitar verificación de equipos antes de borrar cliente',
    buscar: 'if (totalEquipos > 0) {',
    reemplazar: 'if (false) {',
  },
  {
    id: 'M10_eliminar_cliente_sin_org',
    desc: 'Quitar filtro organizacion_id al borrar cliente',
    buscar: '.from("clientes")\n    .delete()\n    .eq("id", params.clienteId)\n    .eq("organizacion_id", params.orgId);',
    reemplazar: '.from("clientes")\n    .delete()\n    .eq("id", params.clienteId);',
  },
];

const MUTACIONES_INDEX = [
  {
    id: 'R1_post_invitaciones_sin_control',
    desc: 'Quitar control crearInvitacionSegura en POST /invitaciones (index.ts)',
    buscar: `    const data = await crearInvitacionSegura(adminClient, {
      orgId,
      usuarioId: user?.id || null,
      email,
      rol,
    });`,
    reemplazar: `    const { data } = await adminClient.from("invitaciones_equipo").insert({ organizacion_id: orgId, email, rol }).select().single();`,
  },
  {
    id: 'R2_delete_invitaciones_sin_control',
    desc: 'Quitar control eliminarInvitacionSegura en DELETE /invitaciones/:id (index.ts)',
    buscar: `    const res = await eliminarInvitacionSegura(adminClient, {
      orgId,
      usuarioId: user?.id || null,
      invitacionId: id,
    });`,
    reemplazar: `    await adminClient.from("invitaciones_equipo").delete().eq("id", id); const res = { success: true };`,
  },
  {
    id: 'R3_post_crear_org_sin_superadmin',
    desc: 'Quitar exigirSuperAdminOrgPrincipal en POST /organizaciones/crear-con-invitacion (index.ts)',
    buscar: `    // Restringir a admin/propietario de la Organización Principal (Super-Admin)
    await exigirSuperAdminOrgPrincipal(adminClient, {
      orgId: currentOrgId,
      usuarioId: user?.id || null,
      orgPrincipalId: ORG_PRINCIPAL_ID,
    });`,
    reemplazar: `    /* mutado: sin exigirSuperAdminOrgPrincipal */`,
  },
  {
    id: 'R4_get_organizaciones_sin_superadmin',
    desc: 'Quitar exigirSuperAdminOrgPrincipal en GET /organizaciones (index.ts)',
    buscar: `    await exigirSuperAdminOrgPrincipal(adminClient, {
      orgId: currentOrgId,
      usuarioId: user?.id || null,
      orgPrincipalId: ORG_PRINCIPAL_ID,
    });

    const { data, error } = await adminClient
      .from("organizaciones")`,
    reemplazar: `    /* mutado: sin exigirSuperAdminOrgPrincipal */
    const { data, error } = await adminClient
      .from("organizaciones")`,
  },
  {
    id: 'R5_put_modulos_org_sin_superadmin',
    desc: 'Quitar exigirSuperAdminOrgPrincipal en PUT /organizaciones/:id/modulos (index.ts)',
    buscar: `    await exigirSuperAdminOrgPrincipal(adminClient, {
      orgId: currentOrgId,
      usuarioId: user?.id || null,
      orgPrincipalId: ORG_PRINCIPAL_ID,
    });

    const id = c.req.param("id");`,
    reemplazar: `    /* mutado: sin exigirSuperAdminOrgPrincipal */
    const id = c.req.param("id");`,
  },
  {
    id: 'R6_delete_cliente_sin_check_equipos',
    desc: 'Quitar eliminarClienteSeguro en DELETE /clientes/:id (index.ts)',
    buscar: `    const resultado = await eliminarClienteSeguro(supabase, {
      orgId,
      clienteId: id,
    });`,
    reemplazar: `    await supabase.from('clientes').delete().eq('id', id); const resultado = { success: true };`,
  },
];

function correrSuite(testFile, flags) {
  const res = spawnSync('deno', ['test', ...flags, testFile], {
    encoding: 'utf8',
  });
  return res.status === 0;
}

function ejecutarBloque(nombre, targetFile, testFile, flags, mutaciones) {
  console.log(`\n=== ${nombre} ===`);
  const original = fs.readFileSync(targetFile, 'utf8');
  let muertas = 0;
  const vivas = [];

  try {
    if (!correrSuite(testFile, flags)) {
      console.error(`La suite base (${path.basename(testFile)}) no pasó antes de mutar.`);
      process.exit(1);
    }

    for (const m of mutaciones) {
      const normOrig = original.replace(/\r\n/g, '\n');
      if (!normOrig.includes(m.buscar)) {
        console.error(`[ERROR] Patrón no encontrado para ${m.id} en ${path.basename(targetFile)}`);
        process.exit(1);
      }
      const mutado = normOrig.replace(m.buscar, m.reemplazar);
      fs.writeFileSync(targetFile, mutado, 'utf8');
      const paso = correrSuite(testFile, flags);
      if (!paso) {
        muertas++;
        console.log(`[MUERTA] ${m.id} — ${m.desc}`);
      } else {
        vivas.push(m.id);
        console.log(`[VIVA]   ${m.id} — ${m.desc}`);
      }
    }
  } finally {
    fs.writeFileSync(targetFile, original, 'utf8');
  }

  console.log(`Subtotal ${nombre}: ${muertas}/${mutaciones.length} muertas, ${vivas.length} vivas.`);
  return { muertas, total: mutaciones.length, vivas };
}

const rMotor = ejecutarBloque(
  'Motor (motor/cuentas_permisos.ts)',
  MOTOR_TARGET,
  MOTOR_TEST,
  ['--allow-read', '--no-check'],
  MUTACIONES_MOTOR
);

const rIndex = ejecutarBloque(
  'Rutas reales (index.ts)',
  INDEX_TARGET,
  RUTAS_TEST,
  ['--allow-all', '--no-check'],
  MUTACIONES_INDEX
);

const totalMuertas = rMotor.muertas + rIndex.muertas;
const total = rMotor.total + rIndex.total;
const totalVivas = rMotor.vivas.length + rIndex.vivas.length;

console.log(`\nResumen global mutaciones: ${totalMuertas}/${total} muertas, ${totalVivas} vivas.`);
if (totalVivas > 0) {
  process.exit(1);
}
