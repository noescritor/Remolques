/**
 * Prueba E2E de navegador (Chrome headless + CDP) para el Bloque F (acero XML -> precios).
 * Prerrequisitos:
 *   1. Postgres local con BD migrada y sembrada con scripts/dev/seed_acero_f.sql
 *   2. node scripts/dev/local_supabase_bridge.cjs (puerto 54321)
 *   3. deno run --allow-net --allow-env --allow-read supabase/functions/make-server-feea4382/index.ts (puerto 8000)
 *   4. npx vite --port 5173 --strictPort (VITE_API_URL=http://127.0.0.1:8000)
 *
 * Uso:
 *   node scripts/dev/test_acero_f_browser.cjs
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

function httpGetJson(url) {
  return new Promise((resolveFn, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolveFn(JSON.parse(data)));
    }).on('error', reject);
  });
}

async function main() {
  const chrome = spawn(CHROME_PATH, [
    '--headless=new',
    '--disable-gpu',
    '--no-sandbox',
    '--remote-debugging-port=9235',
    `--user-data-dir=${join(os.tmpdir(), `chrome_acero_f_${Date.now()}`)}`,
    'about:blank',
  ]);

  let ws;
  let cutPropuesta = false;
  let cutAplicar = false;
  const dialogs = [];

  try {
    let targets = [];
    for (let i = 0; i < 20; i++) {
      try {
        targets = await httpGetJson('http://127.0.0.1:9235/json');
        if (targets.length) break;
      } catch {}
      await sleep(300);
    }
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
      if (msg.method === 'Page.javascriptDialogOpening') {
        dialogs.push(msg.params?.message || '');
        await cdp('Page.handleJavaScriptDialog', { accept: true }).catch(() => {});
        return;
      }
      if (msg.method === 'Runtime.consoleAPICalled' && msg.params?.type === 'error') {
        const txt = msg.params.args.map((a) => a.value || a.description).join(' ');
        if (!cutPropuesta && !cutAplicar) consoleErrors.push(txt);
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
          (cutPropuesta && url.includes('/acero/cfdi/') && url.includes('/propuesta')) ||
          (cutAplicar && url.includes('/acero/cfdi/') && url.includes('/aplicar') && request.method === 'POST')
        ) {
          await cdp('Fetch.fulfillRequest', {
            requestId,
            responseCode: 500,
            responseHeaders: [
              { name: 'Content-Type', value: 'application/json' },
              { name: 'Access-Control-Allow-Origin', value: '*' },
            ],
            body: Buffer.from(JSON.stringify({ error: 'Corte de API simulado Bloque F' })).toString('base64'),
          });
          return;
        }
        if (url.startsWith('https://remolques-remolques-api.gehkp3.easypanel.host') || url.startsWith(`${VITE_URL}/undefined`)) {
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
                JSON.stringify({ id: 'a988611b-2949-4ab7-b670-daf4a21f4e18', email: 'admin@remolques.com', aud: 'authenticated', role: 'authenticated' })
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
        { urlPattern: `${API_URL}/acero/cfdi/*` },
      ],
    });
    await cdp('Emulation.setDeviceMetricsOverride', { width: 1366, height: 900, deviceScaleFactor: 1, mobile: false });

    // 1. Inyectar sesión local
    await cdp('Page.navigate', { url: `${VITE_URL}/` });
    await sleep(1500);
    await evalJs(`(() => {
      localStorage.setItem('welcomeTourCompleted', 'true');
      const tok = JSON.stringify({
        access_token: 'local-e2e-token',
        token_type: 'bearer',
        expires_in: 36000,
        expires_at: Math.floor(Date.now()/1000) + 36000,
        refresh_token: 'local-refresh',
        user: { id: 'a988611b-2949-4ab7-b670-daf4a21f4e18', email: 'admin@remolques.com', aud: 'authenticated', role: 'authenticated', user_metadata: { nombre: 'E2E' } }
      });
      localStorage.setItem('sb-remolques-remolques-supa-auth-token', tok);
      localStorage.setItem('sb-127-auth-token', tok);
    })()`);

    // 2. Ir a /cxp -> Facturas
    await cdp('Page.navigate', { url: `${VITE_URL}/cxp` });
    await sleep(2500);
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('[role="tab"]')).find(b => /Facturas/i.test(b.textContent || ''));
      if (btn) {
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        btn.click();
      }
    })()`);
    await sleep(1800);

    const checkFacturas = await evalJs(`(() => {
      const rows = Array.from(document.querySelectorAll('tr'));
      const r101 = rows.find(r => r.textContent.includes('FAC-ACERO-101'));
      const rCancel = rows.find(r => r.textContent.includes('FAC-CANCELADA-99'));
      const btn101 = r101 ? Array.from(r101.querySelectorAll('button')).find(b => b.textContent.trim() === 'Acero') : null;
      const btnCancel = rCancel ? Array.from(rCancel.querySelectorAll('button')).find(b => b.textContent.trim() === 'Acero') : null;
      return { has101: Boolean(r101), hasBtn101: Boolean(btn101), hasCancel: Boolean(rCancel), hasBtnCancel: Boolean(btnCancel) };
    })()`);
    console.log('CHECK_FACTURAS:', JSON.stringify(checkFacturas));
    if (!checkFacturas.hasBtn101 || checkFacturas.hasBtnCancel) {
      throw new Error('Fallo check botones Acero: ' + JSON.stringify(checkFacturas));
    }

    // 3. Corte de API en propuesta + Reintentar
    cutPropuesta = true;
    await evalJs(`(() => {
      const r101 = Array.from(document.querySelectorAll('tr')).find(r => r.textContent.includes('FAC-ACERO-101'));
      Array.from(r101.querySelectorAll('button')).find(b => b.textContent.trim() === 'Acero').click();
    })()`);
    await sleep(1200);
    const errPropuesta = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.textContent : '';
      return { hasError: txt.includes('Corte de API simulado'), hasReintentar: txt.includes('Reintentar') };
    })()`);
    console.log('CHECK_CORTE_PROPUESTA:', JSON.stringify(errPropuesta));
    if (!errPropuesta.hasError || !errPropuesta.hasReintentar) throw new Error('Fallo corte propuesta');

    cutPropuesta = false;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      Array.from(dlg.querySelectorAll('button')).find(b => /Reintentar/i.test(b.textContent)).click();
    })()`);
    await sleep(1500);

    const checkPropuesta = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.textContent : '';
      return {
        recordado: txt.includes('Recordado'),
        sugerido: txt.includes('Sugerido'),
        sinSugerencia: txt.includes('Sin sugerencia'),
        descuento: txt.includes('descuentos'),
        kgmBloqueada: txt.includes('Captura kg/pieza'),
        placaAPlaca: txt.includes('[placa] Placa'),
      };
    })()`);
    console.log('CHECK_PROPUESTA_101:', JSON.stringify(checkPropuesta));
    if (!checkPropuesta.recordado || !checkPropuesta.sugerido || !checkPropuesta.sinSugerencia || !checkPropuesta.descuento || !checkPropuesta.kgmBloqueada || !checkPropuesta.placaAPlaca) {
      throw new Error('Faltan badges/banderas en propuesta 101: ' + JSON.stringify(checkPropuesta));
    }
    await shot('acero_f_01_propuesta.png');

    // Capturar factor 45 en KGM y confirmar variaciones >30%
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const kgmInput = Array.from(dlg.querySelectorAll('input[type="number"]')).find(i => i.placeholder === 'kg/pza');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
      setter.call(kgmInput, '45');
      kgmInput.dispatchEvent(new Event('input', { bubbles: true }));
      kgmInput.dispatchEvent(new Event('change', { bubbles: true }));
    })()`);
    await sleep(400);
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const labels = Array.from(dlg.querySelectorAll('label')).filter(l => /Variación > 30%|Factura más vieja/i.test(l.textContent || ''));
      for (const l of labels) {
        const cb = l.querySelector('button[role="checkbox"]');
        if (cb && cb.getAttribute('data-state') !== 'checked') cb.click();
      }
    })()`);
    await sleep(400);

    // Corte al aplicar (preserva estado)
    cutAplicar = true;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      Array.from(dlg.querySelectorAll('button')).find(b => /Aplicar 2 seleccionadas/i.test(b.textContent)).click();
    })()`);
    await sleep(1000);
    const checkCorteAplicar = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.textContent : '';
      const kgmInput = Array.from(dlg.querySelectorAll('input[type="number"]')).find(i => i.placeholder === 'kg/pza');
      return { hasAlert: txt.includes('Corte de API simulado'), factorPreservado: kgmInput?.value };
    })()`);
    console.log('CHECK_CORTE_APLICAR:', JSON.stringify(checkCorteAplicar));
    if (!checkCorteAplicar.hasAlert || checkCorteAplicar.factorPreservado !== '45') {
      throw new Error('Corte al aplicar fallo: ' + JSON.stringify(checkCorteAplicar));
    }

    // Aplicar de verdad (doble clic rápido)
    cutAplicar = false;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => /Aplicar 2 seleccionadas/i.test(b.textContent));
      btn.click();
      btn.click();
    })()`);
    await sleep(1800);
    const checkAplicado = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.textContent : '';
      return {
        exito: txt.includes('2 precio(s) actualizado(s)'),
        yaAplicada: txt.includes('Ya aplicada'),
        botonVerMatriz: txt.includes('Ver en Precios de acero'),
      };
    })()`);
    console.log('CHECK_APLICADO:', JSON.stringify(checkAplicado));
    if (!checkAplicado.exito || !checkAplicado.yaAplicada) {
      throw new Error('Fallo al aplicar precios: ' + JSON.stringify(checkAplicado));
    }
    await shot('acero_f_02_aplicado.png');

    // Cerrar y abrir FAC-ACERO-VIEJA
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      Array.from(dlg.querySelectorAll('button')).find(b => b.textContent.trim() === 'Cerrar').click();
    })()`);
    await sleep(500);
    await evalJs(`(() => {
      const rVieja = Array.from(document.querySelectorAll('tr')).find(r => r.textContent.includes('FAC-ACERO-VIEJA'));
      Array.from(rVieja.querySelectorAll('button')).find(b => b.textContent.trim() === 'Acero').click();
    })()`);
    await sleep(1500);
    const checkVieja = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.textContent : '';
      return {
        usdTc: txt.includes('USD') && txt.includes('TC 20'),
        fechaVieja: txt.includes('Factura más vieja'),
        variacionAlta: txt.includes('Variación > 30%'),
      };
    })()`);
    console.log('CHECK_VIEJA:', JSON.stringify(checkVieja));
    if (!checkVieja.usdTc || !checkVieja.fechaVieja || !checkVieja.variacionAlta) {
      throw new Error('Faltan advertencias en FAC-ACERO-VIEJA: ' + JSON.stringify(checkVieja));
    }
    await shot('acero_f_03_advertencias.png');

    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      Array.from(dlg.querySelectorAll('button')).find(b => b.textContent.trim() === 'Cerrar').click();
    })()`);
    await sleep(400);

    // 4. Navegar a /calculadora -> Precios de acero
    await cdp('Page.navigate', { url: `${VITE_URL}/calculadora` });
    await sleep(2200);
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('[role="tab"]')).find(b => /Precios de acero/i.test(b.textContent || ''));
      if (btn) {
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        btn.click();
      }
    })()`);
    await sleep(1200);

    const checkMatriz = await evalJs(`(() => {
      const txt = document.body.textContent || '';
      return { tieneSinIva: txt.includes('s/IVA'), tieneGestionarAlias: txt.includes('Gestionar alias') };
    })()`);
    console.log('CHECK_MATRIZ:', JSON.stringify(checkMatriz));
    if (!checkMatriz.tieneSinIva || !checkMatriz.tieneGestionarAlias) {
      throw new Error('Matriz incompleta: ' + JSON.stringify(checkMatriz));
    }

    await evalJs(`(() => {
      document.querySelector('button[aria-label^="Editar material"]').click();
    })()`);
    await sleep(600);
    await shot('acero_f_04_matriz_y_editor.png');
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      Array.from(dlg.querySelectorAll('button')).find(b => /Cancelar/i.test(b.textContent)).click();
    })()`);
    await sleep(400);

    // 5. Comparador (O1: etiqueta "Mostrar resultados con IVA")
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('[role="tab"]')).find(b => /Comparador/i.test(b.textContent || ''));
      if (btn) {
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        btn.click();
      }
    })()`);
    await sleep(800);
    const checkComp = await evalJs(`(document.body.textContent || '').includes('Mostrar resultados con IVA')`);
    console.log('CHECK_COMPARADOR_O1:', checkComp);
    if (!checkComp) throw new Error('Falta etiqueta O1 en ComparadorAcero');

    // 6. Costeo de Placa
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('[role="tab"]')).find(b => /Costeo de Placa/i.test(b.textContent || ''));
      if (btn) {
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        btn.click();
      }
    })()`);
    await sleep(1000);
    const checkPlaca = await evalJs(`(() => {
      const txt = document.body.textContent || '';
      const factorVal = document.querySelector('#factor-input')?.value;
      return {
        notaOk: txt.includes('El factor cubre mano de obra y proceso de la placa trabajada. El precio de la matriz es siempre el de la placa sin factor.'),
        factorVal,
      };
    })()`);
    console.log('CHECK_PLACA:', JSON.stringify(checkPlaca));
    if (!checkPlaca.notaOk || checkPlaca.factorVal !== '1.5') throw new Error('Fallo CosteoPlaca');
    await shot('acero_f_05_costeo_placa.png');

    // 7. Responsive 768px y 375px
    for (const w of [768, 375]) {
      await cdp('Emulation.setDeviceMetricsOverride', { width: w, height: 844, deviceScaleFactor: 1, mobile: w < 500 });
      await sleep(500);
      const ov = await evalJs(`({ w: window.innerWidth, sw: document.documentElement.scrollWidth })`);
      console.log(`RESPONSIVE_${w}:`, JSON.stringify(ov));
      if (ov.sw > ov.w + 2) throw new Error(`Overflow horizontal en ${w}px: ${JSON.stringify(ov)}`);
    }

    console.log('CONSOLE_ERRORS:', consoleErrors.length, consoleErrors);
    console.log('DIALOGS:', dialogs.length);
    if (consoleErrors.length > 0) throw new Error('Errores de consola: ' + consoleErrors.join(' | '));
    console.log('E2E_ACERO_F_OK');
  } finally {
    if (ws) ws.close();
    chrome.kill();
  }
}

main().catch((err) => {
  console.error('E2E_FAILED:', err);
  process.exit(1);
});
