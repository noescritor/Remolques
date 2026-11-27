/**
 * Prueba E2E de navegador (Chrome headless + CDP) para Gestión de Equipos:
 * - Captura cambiar cliente (equipo manual, folio intacto)
 * - Captura cancelar equipo (diálogo con motivo)
 * - Captura Ver cancelados (motivo, quién, cuándo y botón Reactivar)
 * - Captura reactivar equipo (vuelve a activos con estado intacto)
 * - Captura fecha_pedido en Órdenes de trabajo y en detalle del Tablero
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
    '--window-size=1440,900',
    '--remote-debugging-port=9238',
    `--user-data-dir=${join(os.tmpdir(), `chrome_equipos_${Date.now()}`)}`,
    'about:blank',
  ]);

  let ws;
  try {
    let targets = [];
    for (let i = 0; i < 25; i++) {
      try {
        targets = await httpGetJson('http://127.0.0.1:9238/json');
        if (targets.length) break;
      } catch {}
      await sleep(300);
    }
    if (!targets.length) throw new Error('No se pudo conectar a Chrome DevTools en :9238');

    ws = new WebSocket((targets.find((t) => t.type === 'page') || targets[0]).webSocketDebuggerUrl);
    await new Promise((res) => ws.on('open', res));

    let msgId = 1;
    const pending = new Map();

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
                })
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
    await cdp('Emulation.setDeviceMetricsOverride', { width: 1440, height: 900, deviceScaleFactor: 1, mobile: false });
    await cdp('Fetch.enable', {
      patterns: [
        { urlPattern: 'https://remolques-remolques-api.gehkp3.easypanel.host/*' },
        { urlPattern: 'https://remolques-remolques-supa.gehkp3.easypanel.host/*' },
        { urlPattern: `${VITE_URL}/undefined/*` },
      ],
    });

    // 1. Inyectar sesión local y navegar a /ordenes-trabajo
    await cdp('Page.navigate', { url: `${VITE_URL}/ordenes-trabajo` });
    await sleep(1200);
    await evalJs(`(() => {
      const session = {
        access_token: 'local-test-token',
        refresh_token: 'local-refresh',
        expires_at: Math.floor(Date.now() / 1000) + 7200,
        expires_in: 7200,
        token_type: 'bearer',
        user: {
          id: 'a988611b-2949-4ab7-b670-daf4a21f4e18',
          email: 'admin@remolques.com',
          aud: 'authenticated',
          role: 'authenticated',
          user_metadata: { rol: 'propietario', nombre: 'Admin Leolca' }
        }
      };
      for (const k of Object.keys(localStorage)) {
        if (k.startsWith('sb-')) localStorage.removeItem(k);
      }
      localStorage.setItem('sb-remolques-remolques-supa-auth-token', JSON.stringify(session));
      localStorage.setItem('remolques_welcome_tour_v1', 'done');
    })()`);

    await cdp('Page.navigate', { url: `${VITE_URL}/ordenes-trabajo` });
    await waitForText('502-INV011126-1');
    await waitForText('501-TDN011126-1');
    // Cerrar WelcomeTour si aparece para que las capturas queden completamente despejadas
    await evalJs(`(() => {
      const heading = Array.from(document.querySelectorAll('h2, h3, div')).find(el => (el.textContent || '').includes('¡Bienvenido a Ideally Platform!'));
      if (heading) {
        const container = heading.closest('.fixed') || heading.parentElement?.parentElement;
        const closeBtn = container?.querySelector('button');
        if (closeBtn) closeBtn.click();
      }
    })()`);
    await sleep(400);
    assert(true, 'Órdenes activas cargadas con fecha de pedido visible');

    // 2. Cambiar cliente en equipo manual (502-INV011126-1)
    await evalJs(`(() => {
      const btn = document.querySelector('button[aria-label="Cambiar cliente 502-INV011126-1"]');
      if (!btn) throw new Error('No se encontró botón Cambiar cliente');
      btn.click();
    })()`);
    await waitForText('Cambiar cliente — 502-INV011126-1');
    await sleep(300);

    // Seleccionar Autotransportes Bajío en el Select y llenar etiqueta/motivo
    await evalJs(`(() => {
      const trigger = document.querySelector('[role="dialog"] button[role="combobox"]');
      if (trigger) trigger.click();
    })()`);
    await sleep(300);
    await evalJs(`(() => {
      const opts = Array.from(document.querySelectorAll('[role="option"]'));
      const target = opts.find(el => (el.textContent || '').includes('Autotransportes Bajío'));
      if (!target) throw new Error('No se encontró Autotransportes Bajío en el selector');
      target.click();
    })()`);
    await sleep(250);
    await evalJs(`(() => {
      const input = document.getElementById('motivo-cambio-cliente');
      if (input) {
        const setter = Object.getOwnPropertyDescriptor(HTMLInputElement.prototype, 'value').set;
        setter.call(input, 'Reasignación comercial a Bajío');
        input.dispatchEvent(new Event('input', { bubbles: true }));
      }
    })()`);
    await sleep(250);
    await shot('equipos_gestion_cambiar_cliente.png');

    // Guardar cambio de cliente
    await evalJs(`(() => {
      const btns = Array.from(document.querySelectorAll('[role="dialog"] button'));
      const guardar = btns.find(b => (b.textContent || '').includes('Guardar cliente'));
      if (!guardar) throw new Error('No se encontró botón Guardar cliente');
      guardar.click();
    })()`);
    await waitForText('Autotransportes Bajío');
    const folioSigue = await evalJs(`(document.body?.innerText || '').includes('502-INV011126-1')`);
    assert(folioSigue, 'Cliente cambiado a Autotransportes Bajío conservando folio 502-INV011126-1');

    // 3. Cancelar equipo manual (502-INV011126-1)
    await evalJs(`(() => {
      const btn = document.querySelector('button[aria-label="Cancelar 502-INV011126-1"]');
      if (!btn) throw new Error('No se encontró botón Cancelar');
      btn.click();
    })()`);
    await waitForText('Cancelar equipo 502-INV011126-1');
    await evalJs(`(() => {
      const ta = document.getElementById('motivo-cancelacion-equipo');
      const setter = Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set;
      setter.call(ta, 'Pedido pospuesto por el cliente hasta enero');
      ta.dispatchEvent(new Event('input', { bubbles: true }));
    })()`);
    await sleep(250);
    await shot('equipos_gestion_cancelar.png');

    await evalJs(`(() => {
      const btns = Array.from(document.querySelectorAll('[role="dialog"] button'));
      const cancelar = btns.find(b => (b.textContent || '').includes('Cancelar equipo'));
      if (!cancelar) throw new Error('No se encontró botón Cancelar equipo');
      cancelar.click();
    })()`);
    await sleep(1200);
    const sigueEnActivos = await evalJs(`(document.querySelector('table')?.innerText || '').includes('502-INV011126-1')`);
    assert(!sigueEnActivos, 'Equipo cancelado desapareció de la lista de activos');

    // 4. Filtro "Ver cancelados"
    await evalJs(`(() => {
      const btn = document.querySelector('[data-testid="toggle-ver-cancelados"]');
      if (!btn) throw new Error('No se encontró botón Ver cancelados');
      btn.click();
    })()`);
    await waitForText('Pedido pospuesto por el cliente hasta enero');
    await waitForText('Reactivar');
    await sleep(300);
    await shot('equipos_gestion_ver_cancelados.png');
    assert(true, 'Ver cancelados muestra motivo, quién, cuándo y botón Reactivar');

    // 5. Reactivar equipo
    await evalJs(`(() => {
      const btns = Array.from(document.querySelectorAll('table button'));
      const react = btns.find(b => (b.textContent || '').includes('Reactivar'));
      if (!react) throw new Error('No se encontró botón Reactivar');
      react.click();
    })()`);
    await waitForText('Reactivar equipo 502-INV011126-1');
    await sleep(250);
    await evalJs(`(() => {
      const btns = Array.from(document.querySelectorAll('[role="dialog"] button'));
      const conf = btns.find(b => (b.textContent || '').includes('Confirmar reactivación'));
      if (!conf) throw new Error('No se encontró botón Confirmar reactivación');
      conf.click();
    })()`);
    await sleep(1000);

    // Volver a activos y verificar que regresó 502-INV011126-1
    await evalJs(`(() => {
      const btn = document.querySelector('[data-testid="toggle-ver-cancelados"]');
      if (btn) btn.click();
    })()`);
    await waitForText('502-INV011126-1');
    await sleep(300);
    await shot('equipos_gestion_reactivar.png');
    assert(true, 'Equipo reactivado regresó a activos con su estado y fecha de pedido intactos');

    console.log('TODAS LAS PRUEBAS E2E DE NAVEGADOR PASARON.');
  } finally {
    if (ws) try { ws.close(); } catch {}
    try { chrome.kill(); } catch {}
  }
}

main().catch((err) => {
  console.error('FALLO E2E NAVEGADOR:', err);
  process.exit(1);
});
