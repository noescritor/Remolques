/**
 * Prueba E2E de navegador (Chrome headless + CDP) para el Bloque G (Almacén desde factura CFDI).
 * Prerrequisitos:
 *   1. Postgres local con BD migrada y sembrada con scripts/dev/seed_almacen_g.sql
 *   2. node scripts/dev/local_supabase_bridge.cjs (puerto 54321)
 *   3. deno run --allow-net --allow-env --allow-read supabase/functions/make-server-feea4382/index.ts (puerto 8000)
 *   4. npx vite --port 5173 --strictPort (VITE_API_URL=http://127.0.0.1:8000)
 *
 * Uso:
 *   node scripts/dev/test_almacen_g_browser.cjs
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
    '--remote-debugging-port=9236',
    `--user-data-dir=${join(os.tmpdir(), `chrome_almacen_g_${Date.now()}`)}`,
    'about:blank',
  ]);

  let ws;
  let cutPropuesta = false;
  let cutRecibir = false;

  try {
    let targets = [];
    for (let i = 0; i < 25; i++) {
      try {
        targets = await httpGetJson('http://127.0.0.1:9236/json');
        if (targets.length) break;
      } catch {}
      await sleep(300);
    }
    if (!targets.length) throw new Error('No se pudo conectar a Chrome DevTools en :9236');

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
          resolve: (v) => {
            clearTimeout(timer);
            resolveFn(v);
          },
          reject: (e) => {
            clearTimeout(timer);
            reject(e);
          },
        });
        ws.send(JSON.stringify({ id, method, params }));
      });
    }

    async function evalJs(expr) {
      const r = await cdp('Runtime.evaluate', {
        expression: expr,
        returnByValue: true,
        awaitPromise: true,
      });
      if (r.exceptionDetails) {
        throw new Error('JS exception: ' + JSON.stringify(r.exceptionDetails));
      }
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
      if (msg.method === 'Page.javascriptDialogOpening') {
        await cdp('Page.handleJavaScriptDialog', { accept: true }).catch(() => {});
        return;
      }
      if (msg.method === 'Runtime.consoleAPICalled' && msg.params?.type === 'error') {
        const txt = msg.params.args.map((a) => a.value || a.description).join(' ');
        if (!cutPropuesta && !cutRecibir) consoleErrors.push(txt);
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
          (cutPropuesta && url.includes('/almacen/facturas/') && url.includes('/propuesta')) ||
          (cutRecibir && url.includes('/almacen/facturas/') && url.includes('/recibir') && request.method === 'POST')
        ) {
          await cdp('Fetch.fulfillRequest', {
            requestId,
            responseCode: 500,
            responseHeaders: [
              { name: 'Content-Type', value: 'application/json' },
              { name: 'Access-Control-Allow-Origin', value: '*' },
            ],
            body: Buffer.from(JSON.stringify({ error: 'Corte de API simulado Bloque G' })).toString('base64'),
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
    await cdp('Fetch.enable', {
      patterns: [
        { urlPattern: 'https://remolques-remolques-api.gehkp3.easypanel.host/*' },
        { urlPattern: 'https://remolques-remolques-supa.gehkp3.easypanel.host/*' },
        { urlPattern: `${VITE_URL}/undefined/*` },
        { urlPattern: `${API_URL}/almacen/*` },
      ],
    });
    await cdp('Emulation.setDeviceMetricsOverride', {
      width: 1366,
      height: 900,
      deviceScaleFactor: 1,
      mobile: false,
    });

    // 1. Inyectar sesión local y abrir CxP Facturas
    console.log('1. Inyectando sesión y abriendo /cxp?tab=facturas...');
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
          user_metadata: { nombre: 'E2E', organizacion_id: '00000000-0000-0000-0000-000000000001' }
        }
      });
      localStorage.setItem('sb-remolques-remolques-supa-auth-token', tok);
      localStorage.setItem('sb-127-auth-token', tok);
    })()`);

    await cdp('Page.navigate', { url: `${VITE_URL}/cxp?tab=facturas` });
    await waitForText('Facturas', 20000);
    await sleep(800);
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('[role="tab"]')).find(b => /Facturas/i.test(b.textContent || ''));
      if (btn) {
        btn.dispatchEvent(new PointerEvent('pointerdown', { bubbles: true }));
        btn.dispatchEvent(new MouseEvent('mousedown', { bubbles: true }));
        btn.click();
      }
    })()`);
    await waitForText('F-E2E-001', 20000);
    await waitForText('F-E2E-004-CANC', 10000);
    // Cerrar modal de bienvenida si apareció (con Escape + botón X)
    await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape' });
    await sleep(300);
    await evalJs(`(() => {
      const dlgs = Array.from(document.querySelectorAll('[role="dialog"]'));
      for (const d of dlgs) {
        if (d.innerText.includes('Bienvenido')) {
          const closeBtn = Array.from(d.querySelectorAll('button')).find(b => !b.innerText.includes('Siguiente'));
          if (closeBtn) closeBtn.click();
        }
      }
      // Scrollear tabla horizontalmente para mostrar botones de acción
      const scroller = document.querySelector('.overflow-x-auto');
      if (scroller) scroller.scrollLeft = scroller.scrollWidth;
    })()`);
    await sleep(600);

    const botonesCheck = await evalJs(`(() => {
      const rows = Array.from(document.querySelectorAll('tr'));
      const findRow = (folio) => rows.find(r => r.innerText.includes(folio));
      const hasAlmacen = (r) => r && Array.from(r.querySelectorAll('button')).some(b => b.innerText.trim().includes('Almacén'));
      return {
        f001: hasAlmacen(findRow('F-E2E-001')),
        f002: hasAlmacen(findRow('F-E2E-002')),
        f003: hasAlmacen(findRow('F-E2E-003-VIEJA')),
        f004Canc: hasAlmacen(findRow('F-E2E-004-CANC')),
      };
    })()`);
    assert(botonesCheck.f001 && botonesCheck.f002 && botonesCheck.f003, 'Botón Almacén visible en facturas abiertas');
    assert(!botonesCheck.f004Canc, 'Botón Almacén oculto en factura cancelada');
    await shot('almacen_g_01_cxp_boton.png');

    // Helper para abrir modal Almacén por folio
    async function abrirAlmacenDe(folio) {
      const ok = await evalJs(`(() => {
        const rows = Array.from(document.querySelectorAll('tr'));
        const row = rows.find(r => r.innerText.includes(${JSON.stringify(folio)}));
        if (!row) return false;
        const btn = Array.from(row.querySelectorAll('button')).find(b => b.innerText.trim().includes('Almacén'));
        if (!btn) return false;
        btn.click();
        return true;
      })()`);
      assert(ok, `Abrir modal Almacén para ${folio}`);
    }

    // 2. Corte de API en carga de propuesta + Reintentar
    console.log('2. Probando corte de API en propuesta + Reintentar...');
    cutPropuesta = true;
    await abrirAlmacenDe('F-E2E-001');
    const errPropText = await (async () => {
      const start = Date.now();
      while (Date.now() - start < 15000) {
        const txt = await evalJs(`document.querySelector('[role="dialog"]')?.innerText || ''`);
        if (txt.includes('Reintentar')) return txt;
        await sleep(200);
      }
      return await evalJs(`Array.from(document.querySelectorAll('[role="dialog"]')).map(d => d.innerText).join(' ||| ')`);
    })();
    console.log('  DLG_ERR_PROP:', errPropText.slice(0, 200));
    assert(errPropText.includes('Corte de API simulado Bloque G') || errPropText.includes('Reintentar'), 'Aviso de error y Reintentar visibles tras corte en propuesta');

    cutPropuesta = false;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Reintentar'));
      btn && btn.click();
    })()`);
    await waitForText('TORNILLO HEX 1/2');
    await sleep(400);

    // 3. Verificar propuesta F-E2E-001 (doble conteo OC-E2E-DUP-01, KGM bloqueado, servicio sin marcar)
    console.log('3. Verificando propuesta F-E2E-001...');
    const propInfo = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const txt = dlg ? dlg.innerText : '';
      return {
        tieneDup: txt.includes('OC-E2E-DUP-01'),
        tieneAlias: txt.includes('Recordado'),
        tieneSimilitud: txt.includes('Sugerido'),
        tieneKgm: txt.includes('KGM') || txt.toLowerCase().includes('factor'),
        tieneServicio: txt.toLowerCase().includes('servicio') || txt.includes('Flete'),
      };
    })()`);
    assert(propInfo.tieneDup, 'Advertencia posible_compra_duplicada muestra folio OC-E2E-DUP-01');
    assert(propInfo.tieneAlias, 'Origen alias (Recordado) visible en propuesta');
    assert(propInfo.tieneSimilitud, 'Origen similitud (Sugerido) visible en propuesta');
    assert(propInfo.tieneKgm, 'Unidad KGM / factor visible en propuesta');
    assert(propInfo.tieneServicio, 'Servicio probable visible en propuesta');
    await shot('almacen_g_02_modal_propuesta.png');

    // 4. Verificar que Lamina (KGM) y Flete (servicio) vienen desmarcadas por defecto,
    //    probar corte de API en POST /recibir y luego confirmar las 2 seleccionadas (Tornillo + Cable).
    console.log('4. Probando recepción parcial + corte de API en recibir...');
    const selInicial = await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const rows = Array.from(dlg.querySelectorAll('tbody tr'));
      const isRowChecked = (concepto) => {
        const r = rows.find(x => (x.querySelector('td:nth-child(2)')?.innerText || '').includes(concepto));
        if (!r) return null;
        const cb = r.querySelector('td:first-child input[type="checkbox"], td:first-child button[role="checkbox"]');
        if (!cb) return null;
        return Boolean(cb.checked || cb.getAttribute('aria-checked') === 'true' || cb.getAttribute('data-state') === 'checked');
      };
      return {
        tornillo: isRowChecked('TORNILLO HEX 1/2'),
        cable: isRowChecked('Cable Calibre 12 rollo'),
        lamina: isRowChecked('Lamina Calibre 14 acero'),
        flete: isRowChecked('Flete y maniobra'),
      };
    })()`);
    assert(selInicial.tornillo === true && selInicial.cable === true, 'Tornillo (alias) y Cable (sugerido) marcados por defecto');
    assert(selInicial.lamina === false, 'Lamina (KGM sin factor) desmarcada/bloqueada por defecto');
    assert(selInicial.flete === false, 'Flete (servicio probable) desmarcado por defecto');
    await sleep(200);

    cutRecibir = true;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Recibir') && !b.disabled);
      if (!btn) throw new Error('Botón Recibir no encontrado o deshabilitado');
      btn.click();
    })()`);
    await sleep(1000);
    const modalSigueAbierto = await evalJs(`Boolean(document.querySelector('[role="dialog"]'))`);
    assert(modalSigueAbierto, 'Tras corte de API en recibir, el modal permanece abierto sin perder estado');

    cutRecibir = false;
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Recibir') && !b.disabled);
      if (!btn) throw new Error('Botón Recibir no habilitado tras recuperar API');
      btn.click();
      // Intento de doble clic inmediato (debe estar bloqueado por guardando)
      btn.click();
    })()`);
    await waitForText('Ver en Inventario');
    await sleep(400);
    // Cerrar modal de F-E2E-001
    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.trim() === 'Cerrar');
      btn && btn.click();
    })()`);
    await sleep(500);

    // 5. Recibir F-E2E-002 (USD TC 20) y luego F-E2E-003-VIEJA (fecha anterior)
    console.log('5. Recibiendo F-E2E-002 (USD) y F-E2E-003-VIEJA (fecha anterior)...');
    for (const folio of ['F-E2E-002', 'F-E2E-003-VIEJA']) {
      await abrirAlmacenDe(folio);
      await waitForText('Valvula Hidraulica 3/4');
      await sleep(300);
      await evalJs(`(() => {
        const dlg = document.querySelector('[role="dialog"]');
        const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Recibir') && !b.disabled);
        if (!btn) throw new Error('Botón Recibir deshabilitado en ' + ${JSON.stringify(folio)});
        btn.click();
      })()`);
      await waitForText('Ver en Inventario');
      await sleep(300);
      if (folio === 'F-E2E-003-VIEJA') {
        // Navegar a Inventario usando el botón "Ver en Inventario" (sin recargar página)
        await evalJs(`(() => {
          const dlg = document.querySelector('[role="dialog"]');
          const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.includes('Ver en Inventario'));
          btn && btn.click();
        })()`);
      } else {
        await evalJs(`(() => {
          const dlg = document.querySelector('[role="dialog"]');
          const btn = Array.from(dlg.querySelectorAll('button')).find(b => b.innerText.trim() === 'Cerrar');
          btn && btn.click();
        })()`);
      }
      await sleep(500);
    }

    // 6. Verificar Inventario actualizado (stock entero/decimal sin .0000, último costo USD=1000 no pisado por vieja=700, servicio ausente)
    console.log('6. Verificando tabla de Inventario...');
    await waitForText('Productos Físicos');
    await waitForText('Tornillo Hexagonal 1/2');
    await sleep(800);

    const invCheck = await evalJs(`(() => {
      const rows = Array.from(document.querySelectorAll('tbody tr'));
      const getRow = (name) => {
        const r = rows.find(x => x.innerText.includes(name));
        if (!r) return null;
        return Array.from(r.querySelectorAll('td')).map(td => td.innerText.trim());
      };
      return {
        tornillo: getRow('Tornillo Hexagonal 1/2'),
        cable: getRow('Cable Calibre 12'),
        valvula: getRow('Valvula Hidraulica 3/4'),
        flete: getRow('Flete de entrega'),
        tieneCerosFeos: document.body.innerText.includes('.0000'),
      };
    })()`);
    console.log('  INV:', JSON.stringify(invCheck));
    assert(invCheck.tornillo && invCheck.tornillo[1] === '22', 'Tornillo stock=22 (12+10, sin .0000)');
    assert(invCheck.cable && invCheck.cable[1] === '15', 'Cable stock=15 (12.5+2.5, sin .0000)');
    assert(invCheck.valvula && invCheck.valvula[1] === '6', 'Valvula stock=6 (2+3+1)');
    assert(invCheck.valvula && invCheck.valvula[4].includes('1,000.00') && invCheck.valvula[4].includes('2026-11-22'), 'Valvula ultimo costo=$1,000.00 (USD*20) preservado ante factura vieja');
    assert(!invCheck.flete, 'Producto servicio (Flete de entrega) no aparece en Inventario');
    assert(!invCheck.tieneCerosFeos, 'Ninguna cantidad muestra .0000');
    await shot('almacen_g_03_inventario_actualizado.png');

    // 7. Abrir modal Recepciones y anular F-E2E-003-VIEJA
    console.log('7. Abriendo Recepciones y anulando F-E2E-003-VIEJA...');
    await evalJs(`(() => {
      const btn = Array.from(document.querySelectorAll('button')).find(b => b.innerText.trim() === 'Recepciones');
      if (!btn) throw new Error('Botón Recepciones no encontrado');
      btn.click();
    })()`);
    await waitForText('F-E2E-003-VIEJA');
    await sleep(400);
    await shot('almacen_g_04_recepciones_anular.png');

    await evalJs(`(() => {
      const dlg = document.querySelector('[role="dialog"]');
      const cards = Array.from(dlg.querySelectorAll('div.rounded-md.border'));
      const card = cards.find(c => c.innerText.includes('F-E2E-003-VIEJA') && c.innerText.includes('Anular'));
      if (!card) throw new Error('Tarjeta de recepción F-E2E-003-VIEJA no encontrada');
      const btn = Array.from(card.querySelectorAll('button')).find(b => b.innerText.includes('Anular'));
      btn.click();
    })()`);
    await waitForText('Motivo de la anulación');
    await evalJs(`(() => {
      const inp = document.getElementById('motivo-anulacion-rec');
      const setter = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value').set;
      setter.call(inp, 'Prueba E2E anulacion controlada');
      inp.dispatchEvent(new Event('input', { bubbles: true }));
    })()`);
    await sleep(200);
    await evalJs(`(() => {
      const btns = Array.from(document.querySelectorAll('button'));
      const btn = btns.find(b => b.innerText.includes('Confirmar anulación'));
      if (!btn || btn.disabled) throw new Error('Botón Confirmar anulación no disponible');
      btn.click();
    })()`);
    await waitForText('Prueba E2E anulacion controlada');
    await sleep(500);

    // Cerrar modal Recepciones y comprobar que Valvula bajó a 5
    await cdp('Input.dispatchKeyEvent', { type: 'keyDown', key: 'Escape', code: 'Escape' });
    await sleep(700);
    const valvulaPostAnul = await evalJs(`(() => {
      const rows = Array.from(document.querySelectorAll('tbody tr'));
      const r = rows.find(x => x.innerText.includes('Valvula Hidraulica 3/4'));
      return r ? Array.from(r.querySelectorAll('td')).map(td => td.innerText.trim()) : null;
    })()`);
    assert(valvulaPostAnul && valvulaPostAnul[1] === '5', 'Tras anular F-E2E-003-VIEJA, Valvula baja de 6 a 5');
    assert(valvulaPostAnul && valvulaPostAnul[4].includes('1,000.00'), 'Ultimo costo ($1,000.00) se conserva tras anulación');

    // 8. Responsive 768px y 375px sin desbordamiento horizontal
    console.log('8. Verificando responsive 768px y 375px...');
    for (const [w, h, shotName] of [
      [768, 900, null],
      [375, 812, 'almacen_g_05_mobile_inventario.png'],
    ]) {
      await cdp('Emulation.setDeviceMetricsOverride', {
        width: w,
        height: h,
        deviceScaleFactor: 1,
        mobile: w < 500,
      });
      await sleep(400);
      const ov = await evalJs(`({ sw: document.documentElement.scrollWidth, iw: window.innerWidth })`);
      assert(ov.sw <= ov.iw + 2, `Sin overflow horizontal en /inventario a ${w}px (${ov.sw} <= ${ov.iw})`);
      if (shotName) await shot(shotName);
    }

    assert(consoleErrors.length === 0, `0 errores de consola (encontrados: ${consoleErrors.length}: ${consoleErrors.join(' | ')})`);
    console.log('\n=== E2E BLOQUE G COMPLETO: TODO PASA ===');
  } finally {
    try { ws && ws.close(); } catch {}
    try { chrome && chrome.kill(); } catch {}
  }
}

main().catch((err) => {
  console.error('E2E BLOQUE G FALLO:', err);
  process.exit(1);
});
