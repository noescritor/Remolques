/**
 * Pruebas de concurrencia real con dos sesiones independientes de Postgres 17:
 * 1) cancelar_orden_trabajo vs registrar_cobro (aplicado a esa orden)
 * 2) cancelar_orden_trabajo (confirmo_material=false) vs registrar_entrega_despiece
 *
 * Verifica tanto carreras simultáneas (Promise.all) como bloqueo determinista (BEGIN + FOR UPDATE).
 */

const { Client } = require('pg');

const PG_CFG = {
  host: process.env.PGHOST || '127.0.0.1',
  port: Number(process.env.PGPORT || 54331),
  user: process.env.PGUSER || 'tester',
  password: process.env.PGPASSWORD || 'test',
  database: process.env.PGDATABASE || 'test_equipos_gestion',
};

const ORG_A = '11111111-1111-4111-8111-111111111111';
const USER_A = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
const CLI_A1 = 'cli-eq-a1';
const COT_A = 'cot-eq-a1';

async function newClient() {
  const c = new Client(PG_CFG);
  await c.connect();
  return c;
}

async function crearOrdenPrueba(client, sufijo) {
  const { rows: [linea] } = await client.query(
    `SELECT id FROM lineas_producto WHERE organizacion_id = $1 AND clave = 'plataforma' LIMIT 1`,
    [ORG_A]
  );
  const { rows: [ot] } = await client.query(
    `INSERT INTO ordenes_trabajo (organizacion_id, cotizacion_id, cliente_id, nomenclatura_id, modelo, tipo_equipo, origen, linea_producto_id, estado)
     VALUES ($1, $2, $3, $4, 'Plataforma 40 ft', '01', 'cotizacion', $5, 'Pendiente')
     RETURNING id`,
    [ORG_A, COT_A, CLI_A1, `CONC-${sufijo}`, linea.id]
  );
  return ot.id;
}

async function pruebaCobroVsCancelar() {
  const admin = await newClient();
  const s1 = await newClient();
  const s2 = await newClient();

  try {
    // Asegurar cotización con saldo suficiente
    await admin.query(`UPDATE cotizaciones SET total = 900000, estado = 'Aprobada' WHERE id = $1`, [COT_A]);

    // 1A. Carrera simultánea (5 rondas)
    let ganoCancelar = 0;
    let ganoCobro = 0;
    for (let i = 1; i <= 5; i++) {
      const otId = await crearOrdenPrueba(admin, `COB-${i}-${Date.now()}`);
      const [r1, r2] = await Promise.allSettled([
        s1.query(`SELECT cancelar_orden_trabajo($1, $2, $3, 'Cancelación concurrente', false)`, [ORG_A, USER_A, otId]),
        s2.query(
          `SELECT registrar_cobro($1, $2, 1000, DATE '2026-11-26', 'Transferencia', $3, NULL, NULL, $4::jsonb, false, $5)`,
          [ORG_A, COT_A, `CONC-REF-${i}`, JSON.stringify([{ orden_trabajo_id: otId, monto: 1000 }]), USER_A]
        ),
      ]);

      const { rows: [estado] } = await admin.query(
        `SELECT
           (ot.cancelada_el IS NOT NULL) AS cancelada,
           (SELECT COUNT(*)::int FROM pago_aplicaciones pa JOIN pagos p ON p.id = pa.pago_id
            WHERE pa.orden_trabajo_id = ot.id AND p.estado = 'vigente') AS cobros_vigentes
         FROM ordenes_trabajo ot WHERE ot.id = $1`,
        [otId]
      );

      if (estado.cancelada && estado.cobros_vigentes > 0) {
        throw new Error(`INVARIANTE VIOLADO en ronda ${i}: orden cancelada Y con cobros vigentes!`);
      }
      if (r1.status === 'fulfilled' && r2.status === 'rejected') {
        if (!String(r2.reason?.message || '').includes('orden_cancelada')) {
          throw new Error(`Error inesperado en cobro ronda ${i}: ${r2.reason?.message}`);
        }
        ganoCancelar++;
      } else if (r2.status === 'fulfilled' && r1.status === 'rejected') {
        if (!String(r1.reason?.message || '').includes('orden_con_cobros_vigentes')) {
          throw new Error(`Error inesperado en cancelar ronda ${i}: ${r1.reason?.message}`);
        }
        ganoCobro++;
      } else {
        throw new Error(`Estado inesperado ronda ${i}: cancelar=${r1.status}, cobro=${r2.status}`);
      }
    }

    // 1B. Bloqueo determinista: s1 abre TX y cancela (retiene FOR UPDATE), s2 intenta cobrar (espera), s1 hace COMMIT -> s2 falla orden_cancelada
    const otDet1 = await crearOrdenPrueba(admin, `COBDET1-${Date.now()}`);
    await s1.query('BEGIN');
    await s1.query(`SELECT cancelar_orden_trabajo($1, $2, $3, 'Lock determinista', false)`, [ORG_A, USER_A, otDet1]);
    const pCobro = s2.query(
      `SELECT registrar_cobro($1, $2, 500, DATE '2026-11-26', 'Efectivo', NULL, NULL, NULL, $3::jsonb, false, $4)`,
      [ORG_A, COT_A, JSON.stringify([{ orden_trabajo_id: otDet1, monto: 500 }]), USER_A]
    );
    await new Promise((r) => setTimeout(r, 150));
    await s1.query('COMMIT');
    let errCobro = null;
    try {
      await pCobro;
    } catch (e) {
      errCobro = e;
    }
    if (!errCobro || !String(errCobro.message).includes('orden_cancelada')) {
      throw new Error(`Determinista 1B falló: esperaba orden_cancelada, obtuve ${errCobro?.message}`);
    }

    // 1C. Inverso determinista: s1 abre TX y registra cobro (retiene FOR UPDATE), s2 intenta cancelar (espera), s1 hace COMMIT -> s2 falla orden_con_cobros_vigentes
    const otDet2 = await crearOrdenPrueba(admin, `COBDET2-${Date.now()}`);
    await s1.query('BEGIN');
    await s1.query(
      `SELECT registrar_cobro($1, $2, 500, DATE '2026-11-26', 'Efectivo', NULL, NULL, NULL, $3::jsonb, false, $4)`,
      [ORG_A, COT_A, JSON.stringify([{ orden_trabajo_id: otDet2, monto: 500 }]), USER_A]
    );
    const pCanc = s2.query(`SELECT cancelar_orden_trabajo($1, $2, $3, 'Lock inverso', false)`, [ORG_A, USER_A, otDet2]);
    await new Promise((r) => setTimeout(r, 150));
    await s1.query('COMMIT');
    let errCanc = null;
    try {
      await pCanc;
    } catch (e) {
      errCanc = e;
    }
    if (!errCanc || !String(errCanc.message).includes('orden_con_cobros_vigentes')) {
      throw new Error(`Determinista 1C falló: esperaba orden_con_cobros_vigentes, obtuve ${errCanc?.message}`);
    }

    console.log(
      `[OK] Concurrencia cancelar vs registrar_cobro: 5/5 simultáneas (cancelar=${ganoCancelar}, cobro=${ganoCobro}) + 2/2 deterministas (ambos sentidos) sin violación ni deadlock.`
    );
  } finally {
    await admin.end();
    await s1.end();
    await s2.end();
  }
}

async function pruebaMaterialVsCancelar() {
  const admin = await newClient();
  const s1 = await newClient();
  const s2 = await newClient();

  try {
    const { rows: [faseDesp] } = await admin.query(
      `SELECT id FROM fases_despiece WHERE organizacion_id = $1 AND activo = true LIMIT 1`,
      [ORG_A]
    );

    async function crearLineaParaOrden(otId, tag) {
      const { rows: [lin] } = await admin.query(
        `INSERT INTO orden_despiece_lineas (organizacion_id, orden_trabajo_id, equipo_indice, fase_id, fase_clave, descripcion, unidad, cantidad_requerida, origen, clave_origen)
         VALUES ($1, $2, 1, $3, 'paso_1', 'Material Concurrencia', 'pz', 10, 'manual', $4)
         RETURNING id`,
        [ORG_A, otId, faseDesp.id, `conc::${tag}`]
      );
      return lin.id;
    }

    let ganoCancelar = 0;
    let ganoEntrega = 0;
    for (let i = 1; i <= 5; i++) {
      const otId = await crearOrdenPrueba(admin, `MAT-${i}-${Date.now()}`);
      const lineaId = await crearLineaParaOrden(otId, `${i}-${Date.now()}`);

      const [r1, r2] = await Promise.allSettled([
        s1.query(`SELECT cancelar_orden_trabajo($1, $2, $3, 'Cancelación vs material', false)`, [ORG_A, USER_A, otId]),
        s2.query(
          `SELECT registrar_entrega_despiece($1, $2, 2, 'entrega', NULL, 'Operario Conc', 'Entrega conc', $3)`,
          [ORG_A, lineaId, USER_A]
        ),
      ]);

      const { rows: [estado] } = await admin.query(
        `SELECT
           (ot.cancelada_el IS NOT NULL) AS cancelada,
           (SELECT COUNT(*)::int FROM orden_despiece_entregas e WHERE e.orden_trabajo_id = ot.id AND e.anulada = false) AS entregas_vigentes
         FROM ordenes_trabajo ot WHERE ot.id = $1`,
        [otId]
      );

      if (estado.cancelada && estado.entregas_vigentes > 0) {
        throw new Error(`INVARIANTE VIOLADO material ronda ${i}: orden cancelada sin confirmación Y con entrega vigente!`);
      }
      if (r1.status === 'fulfilled' && r2.status === 'rejected') {
        if (!String(r2.reason?.message || '').includes('orden_cancelada')) {
          throw new Error(`Error inesperado entrega ronda ${i}: ${r2.reason?.message}`);
        }
        ganoCancelar++;
      } else if (r2.status === 'fulfilled' && r1.status === 'rejected') {
        if (!String(r1.reason?.message || '').includes('orden_con_material_entregado')) {
          throw new Error(`Error inesperado cancelar ronda ${i}: ${r1.reason?.message}`);
        }
        ganoEntrega++;
      } else {
        throw new Error(`Estado inesperado material ronda ${i}: cancelar=${r1.status}, entrega=${r2.status}`);
      }
    }

    // Determinista: s1 entrega (lock FOR UPDATE en ordenes_trabajo), s2 intenta cancelar sin confirmar -> s2 espera y recibe orden_con_material_entregado
    const otDet = await crearOrdenPrueba(admin, `MATDET-${Date.now()}`);
    const linDet = await crearLineaParaOrden(otDet, `det-${Date.now()}`);
    await s1.query('BEGIN');
    await s1.query(
      `SELECT registrar_entrega_despiece($1, $2, 3, 'entrega', NULL, 'Operario Det', 'Det', $3)`,
      [ORG_A, linDet, USER_A]
    );
    const pCanc = s2.query(`SELECT cancelar_orden_trabajo($1, $2, $3, 'Cancel det', false)`, [ORG_A, USER_A, otDet]);
    await new Promise((r) => setTimeout(r, 150));
    await s1.query('COMMIT');
    let errCanc = null;
    try {
      await pCanc;
    } catch (e) {
      errCanc = e;
    }
    if (!errCanc || !String(errCanc.message).includes('orden_con_material_entregado')) {
      throw new Error(`Determinista material falló: esperaba orden_con_material_entregado, obtuve ${errCanc?.message}`);
    }

    console.log(
      `[OK] Concurrencia cancelar vs registrar_entrega_despiece: 5/5 simultáneas (cancelar=${ganoCancelar}, entrega=${ganoEntrega}) + determinista sin violación ni deadlock.`
    );
  } finally {
    await admin.end();
    await s1.end();
    await s2.end();
  }
}

(async () => {
  await pruebaCobroVsCancelar();
  await pruebaMaterialVsCancelar();
  console.log('TODAS LAS PRUEBAS DE CONCURRENCIA PASARON.');
})().catch((err) => {
  console.error('FALLO CONCURRENCIA:', err);
  process.exit(1);
});
