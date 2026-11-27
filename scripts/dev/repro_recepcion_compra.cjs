/**
 * Reproducción "antes / después" de la recepción de compras (PUT /compras-proveedor/:id).
 * - En `main` (antes): PUT devuelve 200, compra queda 'Recibida', movimiento Entrada se inserta,
 *   pero `ajustar_stock(uuid, numeric)` falla y `productos.stock_actual` sigue en 10 -> FALLA este script.
 * - En `compras-recepcion-2026-11-24` (después): PUT ejecuta `recibir_compra_proveedor` atómicamente,
 *   stock sube de 10 a 15, segunda llamada es idempotente -> PASA este script.
 *
 * Prerrequisitos:
 *   1. Postgres local con BD sembrada con scripts/dev/seed_compras_recepcion.sql
 *   2. local_supabase_bridge.cjs en :54321
 *   3. Deno API en :8000
 *
 * Uso:
 *   PGDATABASE=test_compras_rec node scripts/dev/repro_recepcion_compra.cjs
 */

const { Pool } = require('pg');

const API_URL = process.env.API_URL || 'http://127.0.0.1:8000';
const COMPRA_ID = '22222222-2222-4222-8222-222222222301';
const PROD_ID = 'prod-cr-e2e-1';
const ORG_ID = '00000000-0000-0000-0000-000000000001';

async function main() {
  const pool = new Pool({
    host: process.env.PGHOST || '127.0.0.1',
    port: Number(process.env.PGPORT || 54331),
    user: process.env.PGUSER || 'tester',
    password: process.env.PGPASSWORD ?? '',
    database: process.env.PGDATABASE || 'test_compras_rec',
  });

  try {
    const before = await pool.query('SELECT stock_actual FROM productos WHERE id = $1', [PROD_ID]);
    const stockAntes = Number(before.rows[0]?.stock_actual);
    console.log('Stock antes:', stockAntes);

    const res = await fetch(`${API_URL}/compras-proveedor/${COMPRA_ID}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer local-e2e-token',
        'x-org-id': ORG_ID,
      },
      body: JSON.stringify({ estado: 'Recibida' }),
    });
    const body = await res.json().catch(() => ({}));
    console.log('PUT /compras-proveedor/:id -> HTTP', res.status, JSON.stringify(body).slice(0, 180));

    const afterCompra = await pool.query('SELECT folio, estado FROM compras_proveedor WHERE id = $1', [COMPRA_ID]);
    const afterProd = await pool.query('SELECT stock_actual FROM productos WHERE id = $1', [PROD_ID]);
    const afterMovs = await pool.query(
      "SELECT tipo_movimiento, cantidad, referencia FROM movimientos_inventario WHERE producto_id = $1 AND referencia = 'Compra OC-CR-REPRO'",
      [PROD_ID],
    );

    const stockDespues = Number(afterProd.rows[0]?.stock_actual);
    console.log('Compra:', afterCompra.rows[0]);
    console.log('Movimientos:', afterMovs.rows);
    console.log('Stock después:', stockDespues);

    if (res.status !== 200) throw new Error(`Se esperaba HTTP 200, llegó ${res.status}`);
    if (afterCompra.rows[0]?.estado !== 'Recibida') throw new Error('La compra no quedó Recibida');
    if (afterMovs.rows.length !== 1) throw new Error(`Se esperaba 1 movimiento Entrada, hay ${afterMovs.rows.length}`);
    if (stockDespues !== stockAntes + 5) {
      throw new Error(`BUG REPRODUCIDO: stock esperaba ${stockAntes + 5} pero quedó en ${stockDespues}`);
    }

    // Segunda llamada simultánea/repetida debe ser idempotente (stock sigue igual)
    const res2 = await fetch(`${API_URL}/compras-proveedor/${COMPRA_ID}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: 'Bearer local-e2e-token',
        'x-org-id': ORG_ID,
      },
      body: JSON.stringify({ estado: 'Recibida' }),
    });
    const afterProd2 = await pool.query('SELECT stock_actual FROM productos WHERE id = $1', [PROD_ID]);
    if (res2.status !== 200 || Number(afterProd2.rows[0]?.stock_actual) !== stockAntes + 5) {
      throw new Error(`Idempotencia falló: HTTP=${res2.status}, stock=${afterProd2.rows[0]?.stock_actual}`);
    }

    console.log('REPRO_RECEPCION_COMPRA: PASA (stock subió de', stockAntes, 'a', stockDespues, 'e idempotencia OK)');
  } finally {
    await pool.end();
  }
}

main().catch((err) => {
  console.error('REPRO_RECEPCION_COMPRA FALLO:', err.message || err);
  process.exit(1);
});
