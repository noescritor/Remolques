/**
 * Puente local ligero PostgREST + Auth + RPC sobre PostgreSQL local.
 * Permite correr el backend Deno (`supabase/functions/make-server-feea4382/index.ts`)
 * y pruebas E2E de navegador contra una base de datos Postgres local sin tocar producción.
 *
 * Variables de entorno:
 *   PGHOST       (default: 127.0.0.1)
 *   PGPORT       (default: 54331)
 *   PGUSER       (default: tester)
 *   PGPASSWORD   (default: '')
 *   PGDATABASE   (requerida; ej. test_acero_f)
 *   BRIDGE_PORT  (default: 54321)
 */

const http = require('node:http');
const { Pool } = require('pg');

const PGDATABASE = process.env.PGDATABASE;
if (!PGDATABASE) {
  console.error('[bridge] Debes definir PGDATABASE en el entorno (ej. PGDATABASE=test_acero_f).');
  process.exit(1);
}

const BRIDGE_PORT = Number(process.env.BRIDGE_PORT || 54321);
const pool = new Pool({
  host: process.env.PGHOST || '127.0.0.1',
  port: Number(process.env.PGPORT || 54331),
  user: process.env.PGUSER || 'tester',
  password: process.env.PGPASSWORD ?? '',
  database: PGDATABASE,
});

function parseFilterVal(raw) {
  if (raw.startsWith('eq.')) return { op: '=', val: raw.slice(3) };
  if (raw.startsWith('neq.')) return { op: '!=', val: raw.slice(4) };
  if (raw.startsWith('gte.')) return { op: '>=', val: raw.slice(4) };
  if (raw.startsWith('lte.')) return { op: '<=', val: raw.slice(4) };
  if (raw.startsWith('gt.')) return { op: '>', val: raw.slice(3) };
  if (raw.startsWith('lt.')) return { op: '<', val: raw.slice(3) };
  if (raw.startsWith('ilike.')) return { op: 'ILIKE', val: raw.slice(6).replace(/\*/g, '%') };
  if (raw.startsWith('like.')) return { op: 'LIKE', val: raw.slice(5).replace(/\*/g, '%') };
  if (raw.startsWith('is.')) {
    const v = raw.slice(3).toLowerCase();
    return { op: 'IS', val: v === 'null' ? null : v === 'true' ? true : v === 'false' ? false : v };
  }
  if (raw.startsWith('in.(') && raw.endsWith(')')) {
    const inner = raw.slice(4, -1).trim();
    const arr = inner ? inner.split(',').map((s) => s.trim().replace(/^"|"$/g, '')) : [];
    return { op: 'IN', val: arr };
  }
  return { op: '=', val: raw };
}

function buildWhere(searchParams, startIdx = 1) {
  const clauses = [];
  const params = [];
  let idx = startIdx;
  for (const [k, v] of searchParams.entries()) {
    if (['select', 'order', 'limit', 'offset', 'on_conflict'].includes(k)) continue;
    const { op, val } = parseFilterVal(v);
    let colExpr = `"${k}"`;
    if (k.includes('->>')) {
      const [c, j] = k.split('->>');
      colExpr = `("${c}"->>'${j}')`;
    } else if (k.includes('.')) {
      continue;
    }
    if (op === 'IS') {
      if (val === null) clauses.push(`${colExpr} IS NULL`);
      else if (val === true) clauses.push(`${colExpr} IS TRUE`);
      else if (val === false) clauses.push(`${colExpr} IS FALSE`);
      else clauses.push(`${colExpr} IS NOT NULL`);
    } else if (op === 'IN') {
      if (!val.length) {
        clauses.push('FALSE');
      } else {
        const ph = val.map(() => `$${idx++}`).join(', ');
        clauses.push(`${colExpr} IN (${ph})`);
        params.push(...val);
      }
    } else {
      clauses.push(`${colExpr} ${op} $${idx++}`);
      params.push(val);
    }
  }
  return {
    sql: clauses.length ? 'WHERE ' + clauses.join(' AND ') : '',
    params,
    nextIdx: idx,
  };
}

async function resolveNested(table, rows, selectStr) {
  if (!selectStr || !rows.length) return rows;

  if (table === 'acero_precios_historial' && selectStr.includes('acero_materiales')) {
    for (const r of rows) {
      if (r.material_id) {
        const res = await pool.query('SELECT nombre, tipo FROM acero_materiales WHERE id = $1', [r.material_id]);
        r.material = res.rows[0] || null;
      } else {
        r.material = null;
      }
    }
  }

  if (table === 'facturas_proveedor' && selectStr.includes('proveedores')) {
    for (const r of rows) {
      if (r.proveedor_id) {
        const res = await pool.query('SELECT id, nombre, rfc FROM proveedores WHERE id = $1', [r.proveedor_id]);
        r.proveedores = res.rows[0] || null;
        r.proveedor = res.rows[0] || null;
      } else {
        r.proveedores = null;
        r.proveedor = null;
      }
    }
  }

  if (table === 'calidad_plantillas' && selectStr.includes('lineas_producto')) {
    for (const r of rows) {
      if (r.linea_producto_id) {
        const res = await pool.query('SELECT id, clave, nombre FROM lineas_producto WHERE id = $1', [r.linea_producto_id]);
        r.linea = res.rows[0] || null;
      } else r.linea = null;
    }
  }

  if (table === 'ordenes_trabajo') {
    if (selectStr.includes('clientes')) {
      for (const r of rows) {
        if (r.cliente_id) {
          const res = await pool.query('SELECT nombre_razon_social FROM clientes WHERE id = $1', [r.cliente_id]);
          r.cliente = res.rows[0] || null;
        } else r.cliente = null;
      }
    }
    if (selectStr.includes('lineas_producto')) {
      for (const r of rows) {
        if (r.linea_producto_id) {
          const res = await pool.query('SELECT id, clave, nombre FROM lineas_producto WHERE id = $1', [r.linea_producto_id]);
          r.linea = res.rows[0] || null;
        } else r.linea = null;
      }
    }
  }

  return rows;
}

const RPC_SIGNATURES = {
  aplicar_precios_acero_cfdi: ['p_org', 'p_usuario', 'p_factura_id', 'p_lineas'],
  renombrar_proveedor_acero: ['p_org', 'p_de', 'p_a'],
  recibir_factura_almacen: ['p_org', 'p_usuario', 'p_factura_id', 'p_lineas', 'p_confirmo_doble', 'p_notas'],
  anular_recepcion_almacen: ['p_org', 'p_usuario', 'p_recepcion_id', 'p_motivo'],
  registrar_cobro: ['p_org_id', 'p_cotizacion_id', 'p_monto', 'p_fecha', 'p_tipo_pago', 'p_referencia', 'p_notas', 'p_descripcion_especie', 'p_aplicaciones', 'p_permitir_saldo_a_favor', 'p_usuario_id'],
  anular_cobro: ['p_org_id', 'p_pago_id', 'p_motivo', 'p_usuario_id'],
  guardar_plan_pago: ['p_org_id', 'p_cotizacion_id', 'p_plan_id', 'p_orden_trabajo_id', 'p_nombre', 'p_notas', 'p_parcialidades'],
  registrar_seguimiento_cobranza: ['p_org_id', 'p_cliente_id', 'p_fecha_contacto', 'p_medio', 'p_contacto', 'p_resultado', 'p_nota', 'p_promesa_fecha', 'p_promesa_monto', 'p_proxima_accion', 'p_proxima_accion_fecha', 'p_cotizacion_id', 'p_orden_trabajo_id', 'p_usuario_id'],
  anular_seguimiento_cobranza: ['p_org_id', 'p_seguimiento_id', 'p_motivo', 'p_usuario_id'],
  sembrar_calidad_plantillas: ['p_org'],
  resumen_calidad_ordenes: ['p_org'],
};

const JSON_RPC_PARAMS = new Set([
  'p_lineas',
  'p_resultados',
  'p_payload',
  'p_aplicaciones',
  'p_parcialidades',
]);

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://127.0.0.1:${BRIDGE_PORT}`);
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const rawBody = Buffer.concat(chunks).toString('utf8');
  let body = null;
  if (rawBody) {
    try { body = JSON.parse(rawBody); } catch { body = rawBody; }
  }

  res.setHeader('Content-Type', 'application/json');
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Headers', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS, HEAD');
  if (req.method === 'OPTIONS') {
    res.statusCode = 204;
    return res.end();
  }

  try {
    if (url.pathname === '/auth/v1/user') {
      const { rows } = await pool.query('SELECT id, email FROM auth.users LIMIT 1');
      if (!rows.length) {
        res.statusCode = 401;
        return res.end(JSON.stringify({ message: 'No user in auth.users' }));
      }
      return res.end(JSON.stringify({
        id: rows[0].id,
        email: rows[0].email,
        aud: 'authenticated',
        role: 'authenticated',
      }));
    }

    if (url.pathname.startsWith('/rest/v1/rpc/')) {
      const fn = url.pathname.replace('/rest/v1/rpc/', '');
      const paramNames = RPC_SIGNATURES[fn];
      if (!paramNames) {
        res.statusCode = 404;
        return res.end(JSON.stringify({ message: `RPC ${fn} not mapped in local_supabase_bridge` }));
      }
      const args = paramNames.map((p) => {
        const v = body && body[p] !== undefined ? body[p] : null;
        if (v !== null && JSON_RPC_PARAMS.has(p)) return JSON.stringify(v);
        return v;
      });
      const placeholders = paramNames.map((_, i) => `$${i + 1}`).join(', ');
      if (fn === 'resumen_calidad_ordenes') {
        const { rows } = await pool.query(`SELECT * FROM ${fn}(${placeholders})`, args);
        return res.end(JSON.stringify(rows));
      }
      const { rows } = await pool.query(`SELECT ${fn}(${placeholders}) AS res`, args);
      return res.end(JSON.stringify(rows[0]?.res ?? null));
    }

    if (url.pathname.startsWith('/rest/v1/')) {
      const table = url.pathname.replace('/rest/v1/', '');
      const accept = String(req.headers['accept'] || '');
      const prefer = String(req.headers['prefer'] || '');
      const isSingleObj = accept.includes('application/vnd.pgrst.object+json');

      if (req.method === 'GET' || req.method === 'HEAD') {
        const selectStr = url.searchParams.get('select') || '*';
        let limit = url.searchParams.get('limit') ? parseInt(url.searchParams.get('limit'), 10) : null;
        let offset = url.searchParams.get('offset') ? parseInt(url.searchParams.get('offset'), 10) : null;

        const rangeHeader = req.headers['range'];
        if (rangeHeader && typeof rangeHeader === 'string' && rangeHeader.includes('-')) {
          const [startStr, endStr] = rangeHeader.replace(/^items=/i, '').split('-');
          const start = parseInt(startStr, 10);
          const end = parseInt(endStr, 10);
          if (Number.isFinite(start) && Number.isFinite(end) && end >= start) {
            offset = start;
            limit = end - start + 1;
          }
        }

        const order = url.searchParams.get('order');
        const { sql: whereSql, params } = buildWhere(url.searchParams);
        let orderSql = '';
        if (order) {
          const parts = order.split(',').map((o) => {
            const [col, dir] = o.split('.');
            return `"${col}" ${dir === 'desc' ? 'DESC' : 'ASC'}`;
          });
          orderSql = 'ORDER BY ' + parts.join(', ');
        }
        const limitSql = Number.isFinite(limit) ? `LIMIT ${limit}` : '';
        const offsetSql = Number.isFinite(offset) ? `OFFSET ${offset}` : '';
        const q = `SELECT * FROM "${table}" ${whereSql} ${orderSql} ${limitSql} ${offsetSql}`;
        const { rows } = await pool.query(q, params);
        if (prefer.includes('count=exact')) {
          res.setHeader('Content-Range', `0-${Math.max(0, rows.length - 1)}/${rows.length}`);
        }
        if (req.method === 'HEAD') {
          res.statusCode = 200;
          return res.end();
        }
        await resolveNested(table, rows, selectStr);
        if (isSingleObj) {
          if (rows.length === 0) {
            res.statusCode = 406;
            return res.end(JSON.stringify({ code: 'PGRST116', message: '0 rows' }));
          }
          return res.end(JSON.stringify(rows[0]));
        }
        return res.end(JSON.stringify(rows));
      }

      if (req.method === 'POST') {
        const items = Array.isArray(body) ? body : [body];
        const onConflict = url.searchParams.get('on_conflict');
        const mergeDuplicates = prefer.includes('resolution=merge-duplicates');
        const inserted = [];
        for (const item of items) {
          const cols = Object.keys(item || {});
          const vals = cols.map((c) => item[c]);
          const colList = cols.map((c) => `"${c}"`).join(', ');
          const ph = cols.map((_, i) => `$${i + 1}`).join(', ');
          let conflictSql = '';
          if (onConflict && mergeDuplicates) {
            const conflictCols = onConflict.split(',').map((c) => `"${c.trim()}"`).join(', ');
            const conflictSet = new Set(onConflict.split(',').map((c) => c.trim()));
            const updCols = cols
              .filter((c) => !conflictSet.has(c))
              .map((c) => `"${c}" = EXCLUDED."${c}"`)
              .join(', ');
            conflictSql = updCols
              ? `ON CONFLICT (${conflictCols}) DO UPDATE SET ${updCols}`
              : `ON CONFLICT (${conflictCols}) DO NOTHING`;
          }
          const q = `INSERT INTO "${table}" (${colList}) VALUES (${ph}) ${conflictSql} RETURNING *`;
          const { rows } = await pool.query(q, vals);
          if (rows[0]) inserted.push(rows[0]);
        }
        res.statusCode = 201;
        return res.end(JSON.stringify(isSingleObj ? (inserted[0] || null) : inserted));
      }

      if (req.method === 'PATCH') {
        const cols = Object.keys(body || {});
        const setParts = cols.map((c, i) => `"${c}" = $${i + 1}`);
        const vals = cols.map((c) => body[c]);
        const { sql: whereSql, params } = buildWhere(url.searchParams, cols.length + 1);
        const q = `UPDATE "${table}" SET ${setParts.join(', ')} ${whereSql} RETURNING *`;
        const { rows } = await pool.query(q, [...vals, ...params]);
        return res.end(JSON.stringify(isSingleObj ? (rows[0] || null) : rows));
      }

      if (req.method === 'DELETE') {
        const { sql: whereSql, params } = buildWhere(url.searchParams);
        const q = `DELETE FROM "${table}" ${whereSql} RETURNING *`;
        const { rows } = await pool.query(q, params);
        return res.end(JSON.stringify(isSingleObj ? (rows[0] || null) : rows));
      }
    }

    res.statusCode = 404;
    res.end(JSON.stringify({ error: 'Not found' }));
  } catch (err) {
    console.error('[bridge error]', req.method, url.pathname, err.message);
    res.statusCode = 400;
    res.end(JSON.stringify({ message: err.message, code: err.code || '40000' }));
  }
});

server.listen(BRIDGE_PORT, '127.0.0.1', () => {
  console.log(`[bridge] Local Supabase REST/Auth bridge listening on http://127.0.0.1:${BRIDGE_PORT} (db=${PGDATABASE})`);
});
