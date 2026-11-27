import { assertEquals, assertRejects } from "https://deno.land/std@0.224.0/assert/mod.ts";
import {
  CuentasPermisosError,
  exigirAdminOPropietario,
  exigirSuperAdminOrgPrincipal,
  crearInvitacionSegura,
  eliminarInvitacionSegura,
  listarEquipoOrganizacion,
  eliminarClienteSeguro,
} from "./cuentas_permisos.ts";

const ORG_PRINCIPAL = "00000000-0000-0000-0000-000000000001";
const ORG_A = "11111111-1111-4111-8111-111111111111";
const ORG_B = "22222222-2222-4222-8222-222222222222";

function createMockClient(opts: {
  perfiles?: Array<{ id?: string; organizacion_id: string; usuario_id: string; rol: string }>;
  invitaciones?: Array<Record<string, any>>;
  authUsers?: Array<{ id: string; email: string }>;
}) {
  const perfiles = [...(opts.perfiles || [])];
  const invitaciones = [...(opts.invitaciones || [])];
  const authUsers = [...(opts.authUsers || [])];

  return {
    invitaciones,
    auth: {
      admin: {
        listUsers: async ({ page = 1, perPage = 50 } = {}) => {
          const start = (page - 1) * perPage;
          return {
            data: { users: authUsers.slice(start, start + perPage) },
            error: null,
          };
        },
      },
    },
    from: (table: string) => {
      const filters: Array<{ col: string; val: any }> = [];
      let op: "select" | "insert" | "delete" = "select";
      let payload: any = null;

      const getSource = () => {
        if (table === "perfiles_organizacion") return perfiles;
        if (table === "invitaciones_equipo") return invitaciones;
        return [];
      };

      const applyFilters = (rows: any[]) =>
        rows.filter((r) => filters.every((f) => r[f.col] === f.val));

      const chain: any = {
        select: () => chain,
        insert: (p: any) => {
          op = "insert";
          payload = p;
          return chain;
        },
        delete: () => {
          op = "delete";
          return chain;
        },
        eq: (col: string, val: any) => {
          filters.push({ col, val });
          return chain;
        },
        maybeSingle: async () => {
          const matches = applyFilters(getSource());
          return { data: matches[0] || null, error: null };
        },
        single: async () => {
          if (op === "insert" && table === "invitaciones_equipo") {
            const nuevo = { id: `inv-${invitaciones.length + 1}`, ...payload };
            invitaciones.push(nuevo);
            return { data: nuevo, error: null };
          }
          const matches = applyFilters(getSource());
          return { data: matches[0] || null, error: matches[0] ? null : { message: "No rows" } };
        },
        then: (resolve: any, reject: any) => {
          try {
            if (op === "delete" && table === "invitaciones_equipo") {
              for (let i = invitaciones.length - 1; i >= 0; i--) {
                const r = invitaciones[i];
                if (filters.every((f) => r[f.col] === f.val)) {
                  invitaciones.splice(i, 1);
                }
              }
              resolve({ data: null, error: null });
              return;
            }
            resolve({ data: applyFilters(getSource()), error: null });
          } catch (e) {
            reject(e);
          }
        },
      };
      return chain;
    },
  };
}

Deno.test("cuentas_permisos: solo admin o propietario pasan exigirAdminOPropietario", async () => {
  const client = createMockClient({
    perfiles: [
      { organizacion_id: ORG_A, usuario_id: "u-prop", rol: "propietario" },
      { organizacion_id: ORG_A, usuario_id: "u-admin", rol: "admin" },
      { organizacion_id: ORG_A, usuario_id: "u-user", rol: "usuario" },
    ],
  });

  assertEquals(await exigirAdminOPropietario(client, ORG_A, "u-prop"), "propietario");
  assertEquals(await exigirAdminOPropietario(client, ORG_A, "u-admin"), "admin");

  const errUser = await assertRejects(
    () => exigirAdminOPropietario(client, ORG_A, "u-user"),
    CuentasPermisosError
  );
  assertEquals(errUser.status, 403);

  const errOtraOrg = await assertRejects(
    () => exigirAdminOPropietario(client, ORG_B, "u-admin"),
    CuentasPermisosError
  );
  assertEquals(errOtraOrg.status, 403);
});

Deno.test("cuentas_permisos: crearInvitacionSegura bloquea usuario y bloquea rol propietario", async () => {
  const client = createMockClient({
    perfiles: [
      { organizacion_id: ORG_A, usuario_id: "u-admin", rol: "admin" },
      { organizacion_id: ORG_A, usuario_id: "u-user", rol: "usuario" },
    ],
  });

  // Usuario regular no puede invitar -> 403
  const errUser = await assertRejects(
    () =>
      crearInvitacionSegura(client, {
        orgId: ORG_A,
        usuarioId: "u-user",
        email: "nuevo@leolca.mx",
        rol: "usuario",
      }),
    CuentasPermisosError
  );
  assertEquals(errUser.status, 403);

  // Admin no puede invitar con rol propietario -> 403
  const errProp = await assertRejects(
    () =>
      crearInvitacionSegura(client, {
        orgId: ORG_A,
        usuarioId: "u-admin",
        email: "jefe@leolca.mx",
        rol: "propietario",
      }),
    CuentasPermisosError
  );
  assertEquals(errProp.status, 403);
  assertEquals(errProp.codigo, "rol_propietario_prohibido");

  // Admin puede invitar como usuario o admin
  const inv = await crearInvitacionSegura(client, {
    orgId: ORG_A,
    usuarioId: "u-admin",
    email: "  VENTAS@Leolca.MX ",
    rol: "usuario",
  });
  assertEquals(inv.email, "ventas@leolca.mx");
  assertEquals(inv.rol, "usuario");
  assertEquals(inv.organizacion_id, ORG_A);
});

Deno.test("cuentas_permisos: eliminarInvitacionSegura exige admin/propietario y aisla por organizacion", async () => {
  const client = createMockClient({
    perfiles: [
      { organizacion_id: ORG_A, usuario_id: "u-admin-a", rol: "admin" },
      { organizacion_id: ORG_A, usuario_id: "u-user-a", rol: "usuario" },
    ],
    invitaciones: [
      { id: "inv-a", organizacion_id: ORG_A, email: "a@a.mx", rol: "usuario" },
      { id: "inv-b", organizacion_id: ORG_B, email: "b@b.mx", rol: "usuario" },
    ],
  });

  // Usuario regular -> 403
  const err = await assertRejects(
    () =>
      eliminarInvitacionSegura(client, {
        orgId: ORG_A,
        usuarioId: "u-user-a",
        invitacionId: "inv-a",
      }),
    CuentasPermisosError
  );
  assertEquals(err.status, 403);

  // Admin de Org A intenta borrar invitación de Org B -> no se borra inv-b
  await eliminarInvitacionSegura(client, {
    orgId: ORG_A,
    usuarioId: "u-admin-a",
    invitacionId: "inv-b",
  });
  assertEquals(client.invitaciones.some((i) => i.id === "inv-b"), true);

  // Admin de Org A borra su propia invitación
  await eliminarInvitacionSegura(client, {
    orgId: ORG_A,
    usuarioId: "u-admin-a",
    invitacionId: "inv-a",
  });
  assertEquals(client.invitaciones.some((i) => i.id === "inv-a"), false);
});

Deno.test("cuentas_permisos: exigirSuperAdminOrgPrincipal exige org principal Y rol admin/propietario", async () => {
  const client = createMockClient({
    perfiles: [
      { organizacion_id: ORG_PRINCIPAL, usuario_id: "u-super-prop", rol: "propietario" },
      { organizacion_id: ORG_PRINCIPAL, usuario_id: "u-super-user", rol: "usuario" },
      { organizacion_id: ORG_A, usuario_id: "u-org-a-prop", rol: "propietario" },
    ],
  });

  assertEquals(
    await exigirSuperAdminOrgPrincipal(client, {
      orgId: ORG_PRINCIPAL,
      usuarioId: "u-super-prop",
      orgPrincipalId: ORG_PRINCIPAL,
    }),
    "propietario"
  );

  // Usuario regular en Org Principal -> 403
  const errRol = await assertRejects(
    () =>
      exigirSuperAdminOrgPrincipal(client, {
        orgId: ORG_PRINCIPAL,
        usuarioId: "u-super-user",
        orgPrincipalId: ORG_PRINCIPAL,
      }),
    CuentasPermisosError
  );
  assertEquals(errRol.status, 403);

  // Propietario de otra org -> 403
  const errOrg = await assertRejects(
    () =>
      exigirSuperAdminOrgPrincipal(client, {
        orgId: ORG_A,
        usuarioId: "u-org-a-prop",
        orgPrincipalId: ORG_PRINCIPAL,
      }),
    CuentasPermisosError
  );
  assertEquals(errOrg.status, 403);
});

Deno.test("cuentas_permisos: listarEquipoOrganizacion pagina auth.admin.listUsers >50 y aisla 2 organizaciones", async () => {
  // Generar 75 usuarios (2 páginas de 50) para verificar que el usuario #65 no pierde su correo
  const authUsers: Array<{ id: string; email: string }> = [];
  for (let i = 1; i <= 75; i++) {
    authUsers.push({ id: `u-${i}`, email: `user${i}@leolca.mx` });
  }

  const client = createMockClient({
    authUsers,
    perfiles: [
      { id: "p1", organizacion_id: ORG_A, usuario_id: "u-1", rol: "propietario" },
      { id: "p2", organizacion_id: ORG_A, usuario_id: "u-65", rol: "usuario" },
      { id: "p3", organizacion_id: ORG_B, usuario_id: "u-70", rol: "admin" },
    ],
  });

  const equipoA = await listarEquipoOrganizacion(client, ORG_A);
  assertEquals(equipoA.length, 2);
  assertEquals(equipoA.map((m: any) => m.email), ["user1@leolca.mx", "user65@leolca.mx"]);

  const equipoB = await listarEquipoOrganizacion(client, ORG_B);
  assertEquals(equipoB.length, 1);
  assertEquals(equipoB[0].email, "user70@leolca.mx");
});

Deno.test("cuentas_permisos: eliminarClienteSeguro rechaza 409 si tiene equipos (activos o cancelados) y borra si no tiene", async () => {
  const ordenes = [
    { id: "ot-1", organizacion_id: ORG_A, cliente_id: "cli-1", cancelada_el: null },
    { id: "ot-2", organizacion_id: ORG_A, cliente_id: "cli-1", cancelada_el: "2026-11-27T00:00:00Z" },
    { id: "ot-3", organizacion_id: ORG_A, cliente_id: "cli-cancelado", cancelada_el: "2026-11-27T00:00:00Z" },
  ];
  const clientes = [
    { id: "cli-1", organizacion_id: ORG_A },
    { id: "cli-cancelado", organizacion_id: ORG_A },
    { id: "cli-libre", organizacion_id: ORG_A },
    { id: "cli-libre-b", organizacion_id: ORG_B },
  ];

  const mock = {
    from(table: string) {
      if (table === "ordenes_trabajo") {
        const filters: Record<string, any> = {};
        const builder: any = {
          select() { return builder; },
          eq(col: string, val: any) { filters[col] = val; return builder; },
          then(resolve: any) {
            const matches = ordenes.filter((o: any) =>
              Object.entries(filters).every(([k, v]) => o[k] === v)
            );
            resolve({ count: matches.length, error: null });
          },
        };
        return builder;
      }
      if (table === "clientes") {
        const filters: Record<string, any> = {};
        const builder: any = {
          delete() { return builder; },
          eq(col: string, val: any) { filters[col] = val; return builder; },
          then(resolve: any) {
            const idx = clientes.findIndex((c: any) =>
              Object.entries(filters).every(([k, v]) => c[k] === v)
            );
            if (idx >= 0) clientes.splice(idx, 1);
            resolve({ error: null });
          },
        };
        return builder;
      }
      throw new Error(`Tabla inesperada: ${table}`);
    },
  };

  // Cliente con 2 equipos (1 activo + 1 cancelado) -> 409 con conteo
  const err2 = await assertRejects(
    () => eliminarClienteSeguro(mock, { orgId: ORG_A, clienteId: "cli-1" }),
    CuentasPermisosError
  );
  assertEquals(err2.status, 409);
  assertEquals(err2.message.includes("2 equipos"), true);

  // Cliente con solo 1 equipo cancelado -> también 409
  const err1 = await assertRejects(
    () => eliminarClienteSeguro(mock, { orgId: ORG_A, clienteId: "cli-cancelado" }),
    CuentasPermisosError
  );
  assertEquals(err1.status, 409);
  assertEquals(err1.message.includes("1 equipo"), true);

  // Cliente sin equipos -> éxito y borra solo su org
  await eliminarClienteSeguro(mock, { orgId: ORG_A, clienteId: "cli-libre" });
  assertEquals(clientes.some((c) => c.id === "cli-libre"), false);
  // Intento de borrar cliente de Org B desde Org A no lo borra
  await eliminarClienteSeguro(mock, { orgId: ORG_A, clienteId: "cli-libre-b" });
  assertEquals(clientes.some((c) => c.id === "cli-libre-b"), true);
});
