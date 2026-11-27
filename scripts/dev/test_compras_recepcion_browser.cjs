/**
 * Prueba E2E de navegador (Chrome headless + CDP) para compras-recepcion-2026-11-24.
 * Prerrequisitos:
 *   1. Postgres local con test_compras_rec migrado (20261125_02) y sembrado (seed_compras_recepcion.sql)
 *   2. node scripts/dev/local_supabase_bridge.cjs (puerto 54321)
 *   3. deno run --allow-net --allow-env --allow-read supabase/functions/make-server-feea4382/index.ts (puerto 8000)
 *   4. npx vite --port 5173 --strictPort (VITE_API_URL=http://127.0.0.1:8000)
 *
 * Uso:
 *   node scripts/dev/test_compras_recepcion_browser.cjs
 */

const { spawn } = require('node:child_process');
const { writeFileSync, mkdirSync, existsSync } = require('node:fs');
const { join, resolve } = require('node:path');
const os = require('node:os');
const http = require('node:http');
const WebSocket = require('ws');

const REPO_ROOT = resolve(__dirname, '../..');
const DIR_EVIDENCIA = join(REPO_ROOT, 'COORDINACION', 'EVIDENCIA');
if (!existsSync(DIR_EVIDENCIA)) mkdirSync(DIR_EVIDENCIA, { recursive: true });

const CHROME_PATH =
  process.env.CHROME_PATH || 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
const VITE_URL = process.env.VITE_URL || 'http://localhost:5173';
const API_URL = process.env.API_URL || 'http://127.0.0.1:8000';
const BRIDGE_URL = process.env.BRIDGE_URL || 'http://127.0.0.1:54321';

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));
function assert(cond, msg) {
  if (!cond) throw new Error(`ASSERT FAIL: ${msg}`);
  console.log(`  OK: ${msg}`);
}

function httpGetJson(url) {
  return new Promise((resolveFn, reject) => {
    http
      .get(url, (res) => {
        let data = '';
        res.on('data', (c) => (data += c));
        res.on('end', () => resolveFn(JSON.parse(data)));
      })
      .on('error', reject);
  });
}

async function main() {
  const chrome = spawn(CHROME_PATH, [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--remote-debugging-port=9237',
    `--user-data-dir=${join(os.tmpdir(), `chrome_compras_rec_${Date.now()}`)}`,
    'about:blank',
  ]);

  let ws;
  let cutPutCompra = false;

  try {
    let targets = [];
    for (let i = 0; i < 25; i++) {
      try {
        targets = await httpGetJson('http://127.0.0.1:9237/json');
        if (targets.length) break;
      } catch {}
      await sleep(300);
    }
    if (!targets.length) throw new Error('No se pudo conectar a Chrome DevTools en :9237');

    ws = new WebSocket((targets.find((t) => t.type === 'page') || targets[0]).webSocketDebuggerUrl);
    await new Promise((res) => ws.on('open', res));

    let msgId = 1;
    const pending = new Map();
    const consoleErrors = [];

    function cdp(method, params = {}) {
      return new Promise((resolveFn, reject) => {
        const id = msgId++;
        const timer = setTimeout(() => {
          if (pending.has(id)) {
            pending.delete(id);
            reject(new Error(`CDP timeout ${method}`));
          }
        }, 30000);
        pending.set(id, {
          resolve: (v) => { clearTimeout(timer); resolveFn(v); },
          reject: (e) => { clearTimeout(timer); reject(e); },
        });
        ws.send(JSON.stringify({ id, method, params }));
      });
    }

    async function evalJs(expr) {
      const r = await cdp('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
      if (r.exceptionDetails) throw new Error('JS exception: ' + JSON.stringify(r.exceptionDetails));
      return r.result?.value;
    }

    async function waitForText(text, timeoutMs = 15000) {
      const start = Date.now();
      while (Date.now() - start < timeoutMs) {
        const found = await evalJs(`(document.body?.innerText || '').includes(${JSON.stringify(text)})`);
        if (found) return true;
        await sleep(250);
      }
      throw new Error(`Timeout esperando texto: ${text}`);
    }

    async function shot(name) {
      const { data } = await cdp('Page.captureScreenshot', { format: 'png' });
      writeFileSync(join(DIR_EVIDENCIA, name), Buffer.from(data, 'base64'));
      console.log('SHOT:', name);
    }

    ws.on('message', async (raw) => {
      const msg = JSON.parse(raw.toString());
      if (msg.id && pending.has(msg.id)) {
        const { resolve: resFn, reject } = pending.get(msg.id);
        pending.delete(msg.id);
        if (msg.error) reject(new Error(JSON.stringify(msg.error)));
        else resFn(msg.result);
        return;
      }
      if (msg.method === 'Runtime.consoleAPICalled' && msg.params?.type === 'error') {
        const txt = msg.params.args.map((a) => a.value || a.description).join(' ');
        if (!cutPutCompra) consoleErrors.push(txt);
      }
      if (msg.method === 'Fetch.requestPaused') {
        const { requestId, request } = msg.params;
        const url = request.url;
        if (request.method === 'OPTIONS') {
          await cdp('Fetch.fulfillRequest', {
            requestId,
            responseCode: 204,
            responseHeaders: [
              { name: 'Access-Control-Allow-Origin', value: '*' },
              { name: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,DELETE,OPTIONS' },
              { name: 'Access-Control-Allow-Headers', value: 'Authorization,Content-Type,apikey,x-org-id' },
            ],
            body: '',
          });
          return;
        }
        if (cutPutCompra && url.includes('/compras-proveedor/') && request.method === 'PUT') {
          await cdp('Fetch.fulfillRequest', {
            requestId,
            responseCode: 500,
            responseHeaders: [
              { name: 'Content-Type', value: 'application/json' },
              { name: 'Access-Control-Allow-Origin', value: '*' },
            ],
            body: Buffer.from(JSON.stringify({ error: 'Corte de API simulado al recibir compra' })).toString('base64'),
          });
          return;
        }
        if (
          url.startsWith('https://remolques-remolques-api.gehkp3.easypanel.host') ||
          url.startsWith(`${VITE_URL}/undefined`)
        ) {
          const localUrl = url
            .replace('https://remolques-remolques-api.gehkp3.easypanel.host', API_URL)
            .replace(`${VITE_URL}/undefined`, API_URL);
          await cdp('Fetch.continueRequest', { requestId, url: localUrl });
          return;
        }
        if (url.includes('remolques-remolques-supa.gehkp3.easypanel.host')) {
          if (url.includes('/auth/v1/user')) {
            await cdp('Fetch.fulfillRequest', {
              requestId,
              responseCode: 200,
              responseHeaders: [
                { name: 'Content-Type', value: 'application/json' },
                { name: 'Access-Control-Allow-Origin', value: '*' },
              ],
              body: Buffer.from(
                JSON.stringify({
                  id: 'a988611b-2949-4ab7-b670-daf4a21f4e18',
                  email: 'admin@remolques.com',
                  aud: 'authenticated',
                  role: 'authenticated',
                }),
              ).toString('base64'),
            });
            return;
          }
          if (url.includes('/rest/v1/')) {
            const localRest = url.replace('https://remolques-remolques-supa.gehkp3.easypanel.host', BRIDGE_URL);
            await cdp('Fetch.continueRequest', { requestId, url: localRest });
            return;
          }
          await cdp('Fetch.failRequest', { requestId, errorReason: 'Aborted' });
          return;
        }
        await cdp('Fetch.continueRequest', { requestId });
      }
    });

    await cdp('Page.enable');
    await cdp('Runtime.enable');
    await cdp('Fetch.enable', {
      patterns: [
        { urlPattern: 'https://remolques-remolques-api.gehkp3.easypanel.host/*' },
        { urlPattern: 'https://remolques-remolques-supa.gehkp3.easypanel.host/*' },
        { urlPattern: `${VITE_URL}/undefined/*` },
        { urlPattern: `${API_URL}/compras-proveedor/*` },
      ],
    });
    await cdp('Emulation.setDeviceMetricsOverride', { width: 1366, height: 900, deviceScaleFactor: 1, mobile: false });

    // 1. Inyectar sesión admin y abrir /compras
    console.log('1. Abriendo /compras...');
    await cdp('Page.navigate', { url: `${VITE_URL}/` });
    await sleep(1200);
    await evalJs(`(() => {
      localStorage.setItem('welcomeTourCompleted', 'true');
      const tok = JSON.stringify({
        access_token: 'local-e2e-token',
        token_type: 'bearer',
        expires_in: 36000,
        expires_at: Math.floor(Date.now()/1000) + 36000,
        refresh_token: 'local-refresh',
        user: {
          id: 'a988611b-2949-4ab7-b670-daf4a21f4e18',
          email: 'admin@remolques.com',
          aud: 'authenticated',
          role: 'authenticated',
          user_metadata: { nombre: 'E2E', rol: 'admin', organizacion_id: '00000000-0000-0000-0000-000000000001' }
        }
      });
      localStorage.setItem('sb-remolques-remolques-supa-auth-token', tok);
      localStorage.setItem('sb-127-auth-token', tok);
    })()`);

    await cdp('Page.navigate', { url: `${VITE_URL}/compras` });
    await waitForText('OC-CR-E2E', 20000);
    await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape' });
    await sleep(400);

    // 2. Pulsar Recibir en OC-CR-E2E y verificar texto de confirmación
    console.log('2. Abriendo confirmación de OC-CR-E2E...');
    await evalJs(`(() => {
      const cards = Array.from(document.querySelectorAll('div'));
      const row = cards.find(d => d.innerText.includes('OC-CR-E2E') && Array.from(d.children).length === 2);
      const btn = row && Array.from(row.querySelectorAll('button')).find(b => b.innerText.trim() === 'Recibir');
      if (!btn) throw new Error('Botón Recibir no encontrado en OC-CR-E2E');
      btn.click();
    })()`);
    await waitForText('Se sumará al inventario: 2 partidas. Esta acción no se puede deshacer desde aquí.');
    await sleep(300);
    await shot('compras_recepcion_01_confirmacion.png');

    // 3. Corte de API al confirmar -> muestra error y botón Reintentar, compra sigue Pendiente
    console.log('3. Probando corte de API al recibir + Reintentar...');
    cutPutCompra = true;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Confirmar recepción'));
      btn && btn.click();
    })()`);
    await waitForText('Corte de API simulado al recibir compra');
    await sleep(300);
    await shot('compras_recepcion_02_error_reintentar.png');

    const siguePendiente = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const tieneReintentar = Boolean(Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Reintentar')));
      return tieneReintentar;
    })()`);
    assert(siguePendiente, 'Tras fallo de API se muestra aviso + botón Reintentar y el diálogo permanece abierto');

    // 4. Restaurar API y pulsar Reintentar (con doble clic inmediato)
    console.log('4. Reintentando recepción con doble clic...');
    cutPutCompra = false;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Reintentar'));
      if (!btn) throw new Error('Botón Reintentar no encontrado');
      btn.click();
      btn.click();
    })()`);
    await waitForText('Compra OC-CR-E2E recibida en inventario.');
    await sleep(600);

    const estadoPost = await evalJs(`(() => {
      const cards = Array.from(document.querySelectorAll('div'));
      const row = cards.find(d => d.innerText.includes('OC-CR-E2E') && Array.from(d.children).length === 2);
      return row ? row.innerText : '';
    })()`);
    assert(estadoPost.includes('RECIBIDA') || estadoPost.includes('Recibida'), 'OC-CR-E2E pasó a estado Recibida');

    // 5. Navegar a /inventario vía menú lateral SIN recargar página y comprobar stock + historial
    console.log('5. Navegando a /inventario sin recargar...');
    await evalJs(`(() => {
      const links = Array.from(document.querySelectorAll('a, button'));
      const invLink = links.find(el => (el.innerText || '').trim() === 'Inventario');
      if (!invLink) throw new Error('Enlace Inventario no encontrado en sidebar');
      invLink.click();
    })()`);
    await waitForText('Eje Reforzado 3500lb');
    await sleep(600);

    const invCheck = await evalJs(`(() => {
      const rows = Array.from(document.querySelectorAll('tbody tr'));
      const getStock = (name) => {
        const r = rows.find(x => x.innerText.includes(name));
        return r ? Array.from(r.querySelectorAll('td')).map(td => td.innerText.trim()) : null;
      };
      return {
        eje: getStock('Eje Reforzado 3500lb'),
        muelle: getStock('Muelle 4 Hojas'),
      };
    })()`);
    console.log('  INV:', JSON.stringify(invCheck));
    // prod-cr-e2e-1: 10 + 5 (REPRO) + 3 (E2E) = 18; prod-cr-e2e-2: 4 + 7 (CONC) + 2 (E2E) = 13
    assert(invCheck.eje && Number(invCheck.eje[1]) === 18, `Eje Reforzado stock=18 sin recargar (actual=${invCheck.eje?.[1]})`);
    assert(invCheck.muelle && Number(invCheck.muelle[1]) === 13, `Muelle 4 Hojas stock=13 sin recargar (actual=${invCheck.muelle?.[1]})`);
    await shot('compras_recepcion_03_inventario_actualizado.png');

    // Abrir Historial y verificar movimiento Compra OC-CR-E2E
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.trim() === 'Historial');
      btn && btn.click();
    })()`);
    await waitForText('Compra OC-CR-E2E');
    await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape' });
    await sleep(300);

    // 6. Responsive 768px y 375px en /compras sin overflow horizontal
    console.log('6. Verificando responsive 768px y 375px en /compras...');
    await evalJs(`(() => {
      const links = Array.from(document.querySelectorAll('a, button'));
      const compLink = links.find(el => (el.innerText || '').includes('Compras Prov'));
      if (compLink) compLink.click();
    })()`);
    await waitForText('OC-CR-E2E');
    for (const [w, h, shotName] of [
      [768, 900, null],
      [375, 812, 'compras_recepcion_04_mobile_compras.png'],
    ]) {
      await cdp('Emulation.setDeviceMetricsOverride', { width: w, height: h, deviceScaleFactor: 1, mobile: w < 500 });
      await sleep(400);
      const ov = await evalJs(`({ sw: document.documentElement.scrollWidth, iw: window.innerWidth })`);
      assert(ov.sw <= ov.iw + 2, `Sin overflow horizontal en /compras a ${w}px (${ov.sw} <= ${ov.iw})`);
      if (shotName) await shot(shotName);
    }

    assert(consoleErrors.length === 0, `0 errores de consola (encontrados: ${consoleErrors.length}: ${consoleErrors.join(' | ')})`);
    console.log('\n=== E2E COMPRAS RECEPCION COMPLETO: TODO PASA ===');
  } finally {
    try { ws && ws.close(); } catch {}
    try { chrome && chrome.kill(); } catch {}
  }
}

main().catch((err) => {
  console.error('E2E COMPRAS RECEPCION FALLO:', err);
  process.exit(1);
});
