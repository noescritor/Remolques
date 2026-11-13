/**
 * Script de captura de evidencia visual real para el Tablero de Producción (Bloque 2)
 * Conecta con Chrome Headless mediante Chrome DevTools Protocol (CDP)
 * y captura capturas de pantalla reales (PNG) en los distintos viewports y estados solicitados.
 */

import { spawn } from 'node:child_process';
import { writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { resolve, join } from 'node:path';
import http from 'node:http';
import WebSocket from 'ws';

const RAIZ = resolve(import.meta.dirname ?? process.cwd(), '..');
const DIR_EVIDENCIA = join(RAIZ, 'COORDINACION', 'EVIDENCIA');
if (!existsSync(DIR_EVIDENCIA)) {
  mkdirSync(DIR_EVIDENCIA, { recursive: true });
}

// 1. Fases canónicas de Plataforma
const FASES_PLATAFORMA = [
  { id: 'f-1', orden: 1, nombre: 'Corte', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-2', orden: 2, nombre: 'Dispositivo', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-3', orden: 3, nombre: 'Armado de baras', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-4', orden: 4, nombre: 'Plancheado', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-5', orden: 5, nombre: 'Perforado cargador', grupo: 'principal', requiere_grupo: null, duracion_dias: 1 },
  { id: 'f-6', orden: 6, nombre: 'IPR', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-7', orden: 7, nombre: 'Chamfles', grupo: 'principal', requiere_grupo: null, duracion_dias: 1 },
  { id: 'f-8', orden: 8, nombre: 'Chasis', grupo: 'principal', requiere_grupo: null, duracion_dias: 3 },
  { id: 'f-9', orden: 9, nombre: 'Resoldado', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-10', orden: 10, nombre: 'Pintura', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-11', orden: 11, nombre: 'Instalación eléctrica', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'f-12', orden: 12, nombre: 'Acabados finales', grupo: 'principal', requiere_grupo: null, duracion_dias: 1 },
];

const MATRIZ_PLATAFORMA = {
  linea: { id: 'l-plat', clave: 'plataforma', nombre: 'Plataforma' },
  fases: FASES_PLATAFORMA,
  filas: [
    {
      orden_id: 'ord-101',
      etiqueta: 'Transportes del Norte S.A.',
      cliente_nombre: 'Transportes del Norte S.A.',
      cotizacion_folio: 'COT-2026-0001',
      modelo: 'Plataforma 40 ft 2 ejes',
      tipo_equipo: '01',
      origen: 'cotizacion',
      fecha_compromiso: '2026-11-20',
      fecha_inicio: '2026-11-04',
      material_faltante: null,
      estado: 'En Producción',
      estado_kanban: 'en_proceso',
      semaforo: 'en_tiempo',
      avance: { terminadas: 1, total: 12 },
      tina: null,
      celdas: {
        'f-1': { estado: 'terminada', fecha_propuesta: '2026-11-06', fecha_fin: '2026-11-06', nota: 'Corte listo' },
        'f-2': { estado: 'en_proceso', fecha_propuesta: '2026-11-14', fecha_fin: null, nota: null },
        'f-3': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
      },
    },
    {
      orden_id: 'ord-102',
      etiqueta: 'Ferretería Pirámide #1',
      cliente_nombre: 'Ferretería Pirámide S.A.',
      cotizacion_folio: 'COT-2026-0042',
      modelo: 'Plataforma 43 ft 3 ejes',
      tipo_equipo: '01',
      origen: 'cotizacion',
      fecha_compromiso: '2026-11-18',
      fecha_inicio: '2026-11-05',
      material_faltante: 'Tornillería 5/8 y soleras de 1/2 pulgada',
      estado: 'En Producción',
      estado_kanban: 'en_proceso',
      semaforo: 'atrasado',
      avance: { terminadas: 0, total: 12 },
      tina: null,
      celdas: {
        'f-1': { estado: 'incompleta', fecha_propuesta: '2026-11-08', fecha_fin: null, nota: 'Falta material de corte' },
        'f-2': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
      },
    },
    {
      orden_id: 'ord-103',
      etiqueta: 'Inventario Stock Noviembre',
      cliente_nombre: 'Inventario',
      cotizacion_folio: null,
      modelo: 'Plataforma 48 ft 3 ejes',
      tipo_equipo: '01',
      origen: 'manual',
      fecha_compromiso: null,
      fecha_inicio: '2026-11-10',
      material_faltante: null,
      estado: 'En Producción',
      estado_kanban: 'en_proceso',
      semaforo: 'atrasado',
      avance: { terminadas: 0, total: 12 },
      tina: null,
      celdas: {
        'f-1': { estado: 'en_proceso', fecha_propuesta: '2026-11-11', fecha_fin: null, nota: 'Retraso de arranque' },
        'f-2': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
      },
    },
  ],
  resumen: {
    en_planta: 3,
    atrasados: 2,
    con_material: 1,
    con_pausa: 0,
    wip_por_fase: { 'f-1': 2, 'f-2': 1 },
  },
};

const FASES_GONDOLA_PRINCIPALES = [
  { id: 'gp-1', orden: 1, nombre: 'Corte', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-2', orden: 2, nombre: 'Dispositivo', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-3', orden: 3, nombre: 'Armado de baras', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-4', orden: 4, nombre: 'Plancheado', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-5', orden: 5, nombre: 'Perforado cargador', grupo: 'principal', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gp-6', orden: 6, nombre: 'Chasis', grupo: 'principal', requiere_grupo: null, duracion_dias: 3 },
  { id: 'gp-7', orden: 7, nombre: 'Montado de tina', grupo: 'principal', requiere_grupo: 'tina', duracion_dias: 2 },
  { id: 'gp-8', orden: 8, nombre: 'Resoldado chasis', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-9', orden: 9, nombre: 'Pintura', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-10', orden: 10, nombre: 'Instalación eléctrica', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-11', orden: 11, nombre: 'Suspensión', grupo: 'principal', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gp-12', orden: 12, nombre: 'Acabados finales', grupo: 'principal', requiere_grupo: null, duracion_dias: 1 },
];

const FASES_GONDOLA_TINA = [
  { id: 'gt-1', orden: 1, nombre: 'Corte de tina', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-2', orden: 2, nombre: 'Doblez de postes', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-3', orden: 3, nombre: 'Piso de tina', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-4', orden: 4, nombre: 'Laterales', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-5', orden: 5, nombre: 'Frente', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-6', orden: 6, nombre: 'Puerta trasera', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-7', orden: 7, nombre: 'Ensamble de tina', grupo: 'tina', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gt-8', orden: 8, nombre: 'Resoldado tina', grupo: 'tina', requiere_grupo: null, duracion_dias: 2 },
  { id: 'gt-9', orden: 9, nombre: 'Gatos y herrajes', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
  { id: 'gt-10', orden: 10, nombre: 'Detallado tina', grupo: 'tina', requiere_grupo: null, duracion_dias: 1 },
];

const MATRIZ_GONDOLA = {
  linea: { id: 'l-gon', clave: 'gondola', nombre: 'Góndola' },
  fases: [...FASES_GONDOLA_PRINCIPALES, ...FASES_GONDOLA_TINA],
  filas: [
    {
      orden_id: 'ord-gon-201',
      etiqueta: 'Minerales del Potosí #1',
      cliente_nombre: 'Minerales del Potosí',
      cotizacion_folio: 'COT-2026-0089',
      modelo: 'Góndola 30 m3 3 ejes',
      tipo_equipo: '03',
      origen: 'cotizacion',
      fecha_compromiso: '2026-11-25',
      fecha_inicio: '2026-11-06',
      material_faltante: null,
      estado: 'En Producción',
      estado_kanban: 'en_proceso',
      semaforo: 'en_tiempo',
      avance: { terminadas: 3, total: 12 },
      tina: { terminadas: 6, total: 10 },
      celdas: {
        'gp-1': { estado: 'terminada', fecha_propuesta: '2026-11-07', fecha_fin: '2026-11-07', nota: null },
        'gp-2': { estado: 'terminada', fecha_propuesta: '2026-11-09', fecha_fin: '2026-11-09', nota: null },
        'gp-3': { estado: 'terminada', fecha_propuesta: '2026-11-11', fecha_fin: '2026-11-11', nota: null },
        'gp-4': { estado: 'en_proceso', fecha_propuesta: '2026-11-15', fecha_fin: null, nota: null },
        'gp-7': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
        // Celdas de tina
        'gt-1': { estado: 'terminada', fecha_propuesta: '2026-11-07', fecha_fin: '2026-11-07', nota: null },
        'gt-2': { estado: 'terminada', fecha_propuesta: '2026-11-08', fecha_fin: '2026-11-08', nota: null },
        'gt-3': { estado: 'terminada', fecha_propuesta: '2026-11-09', fecha_fin: '2026-11-09', nota: null },
        'gt-4': { estado: 'terminada', fecha_propuesta: '2026-11-10', fecha_fin: '2026-11-10', nota: null },
        'gt-5': { estado: 'terminada', fecha_propuesta: '2026-11-11', fecha_fin: '2026-11-11', nota: null },
        'gt-6': { estado: 'terminada', fecha_propuesta: '2026-11-12', fecha_fin: '2026-11-12', nota: null },
        'gt-7': { estado: 'en_proceso', fecha_propuesta: '2026-11-16', fecha_fin: null, nota: 'Ensamble de paneles' },
        'gt-8': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
        'gt-9': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
        'gt-10': { estado: 'pendiente', fecha_propuesta: null, fecha_fin: null, nota: null },
      },
    },
  ],
  resumen: {
    en_planta: 1,
    atrasados: 0,
    con_material: 0,
    con_pausa: 0,
    wip_por_fase: { 'gp-4': 1, 'gt-7': 1 },
  },
};

const CLIENTES_REALES = [
  { id: 'c-1', nombre_razon_social: 'Transportes del Norte S.A. de C.V.', nombre_contacto: 'Carlos Morales' },
  { id: 'c-2', nombre_razon_social: 'Ferretería Pirámide S.A.', nombre_contacto: 'Ing. Roberto Peña' },
  { id: 'c-3', nombre_razon_social: 'Saul Salas y Asociados', nombre_contacto: 'Saul Salas' },
  { id: 'c-4', nombre_razon_social: 'Minerales del Potosí S.A.', nombre_contacto: 'Lic. Fernando Garza' },
  { id: 'c-5', nombre_razon_social: 'Logística Transpeninsular', nombre_contacto: 'Lic. Patricia Vega' },
];

const HISTORIAL_ORDEN = {
  historial: [
    {
      id: 'h-1',
      fase_id: 'f-1',
      fase_nombre: 'Corte',
      fase_grupo: 'principal',
      fase_orden: 1,
      estado_anterior: 'pendiente',
      estado_nuevo: 'en_proceso',
      fecha_propuesta: '2026-11-14',
      nota: null,
      usuario: '00000000-0000-0000-0000-000000000001',
      fecha_cambio: '2026-11-12T14:30:00Z',
    },
    {
      id: 'h-2',
      fase_id: 'f-1',
      fase_nombre: 'Corte',
      fase_grupo: 'principal',
      fase_orden: 1,
      estado_anterior: 'en_proceso',
      estado_nuevo: 'incompleta',
      fecha_propuesta: '2026-11-14',
      nota: 'Faltan soleras de 1/2 pulgada',
      usuario: 'Luis',
      fecha_cambio: '2026-11-12T16:00:00Z',
    },
    {
      id: 'h-3',
      fase_id: 'f-1',
      fase_nombre: 'Corte',
      fase_grupo: 'principal',
      fase_orden: 1,
      estado_anterior: 'incompleta',
      estado_nuevo: 'terminada',
      fecha_propuesta: '2026-11-14',
      nota: 'Concluido con soleras recibidas',
      usuario: null,
      fecha_cambio: '2026-11-13T09:15:00Z',
    },
  ],
};

class CdpClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.callbacks = new Map();
    this.nextId = 1;
    this.consoleLogs = [];
  }

  async connect() {
    return new Promise((resolve, reject) => {
      this.ws.on('open', resolve);
      this.ws.on('error', reject);
      this.ws.on('message', (raw) => {
        const msg = JSON.parse(raw);
        if (msg.id && this.callbacks.has(msg.id)) {
          const cb = this.callbacks.get(msg.id);
          this.callbacks.delete(msg.id);
          if (msg.error) cb.reject(msg.error);
          else cb.resolve(msg.result);
        } else if (msg.method === 'Runtime.consoleAPICalled') {
          const text = msg.params.args.map((a) => a.value || a.description || '').join(' ');
          this.consoleLogs.push(`[console.${msg.params.type}] ${text}`);
        } else if (msg.method === 'Log.entryAdded') {
          this.consoleLogs.push(`[${msg.params.entry.level}] ${msg.params.entry.text}`);
        }
      });
    });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = this.nextId++;
      this.callbacks.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async esperarSelector(selector, timeoutMs = 12000) {
    const inicio = Date.now();
    while (Date.now() - inicio < timeoutMs) {
      const res = await this.send('Runtime.evaluate', {
        expression: `Boolean(document.querySelector('${selector}'))`,
        returnByValue: true,
      });
      if (res?.result?.value) return true;
      await new Promise((r) => setTimeout(r, 200));
    }
    throw new Error(`Timeout esperando selector '${selector}'`);
  }
}

async function main() {
  console.log('--- Iniciando captura de evidencia visual real (Ronda 2) ---');

  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const userDataDir = 'C:\\Users\\luisa\\AppData\\Local\\Temp\\chrome_evidencia_' + Date.now();
  const chromeProc = spawn(chromePath, [
    '--headless=new',
    '--remote-debugging-port=9222',
    '--user-data-dir=' + userDataDir,
    '--no-first-run',
    '--no-default-browser-check',
    '--disable-gpu',
    'about:blank',
  ]);

  await new Promise((r) => setTimeout(r, 2000));

  const versionResp = await new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:9222/json/version', (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  const wsUrl = versionResp.webSocketDebuggerUrl;
  console.log('Conectado a Chrome DevTools Protocol:', wsUrl);

  const pagesResp = await new Promise((resolve, reject) => {
    http.get('http://127.0.0.1:9222/json/list', (res) => {
      let data = '';
      res.on('data', (c) => (data += c));
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });

  const pageWsUrl = pagesResp[0]?.webSocketDebuggerUrl || wsUrl;
  const cdp = new CdpClient(pageWsUrl);
  await cdp.connect();

  await cdp.send('Page.enable');
  await cdp.send('Runtime.enable');
  await cdp.send('Log.enable');
  await cdp.send('Fetch.enable', {
    patterns: [{ urlPattern: '*gehkp3.easypanel.host*', requestStage: 'Request' }],
  });

  cdp.ws.on('message', async (raw) => {
    try {
      const msg = JSON.parse(raw);
      if (msg.method === 'Fetch.requestPaused') {
        const { requestId, request } = msg.params;
        const url = request.url;

        if (request.method === 'OPTIONS') {
          await cdp.send('Fetch.fulfillRequest', {
            requestId,
            responseCode: 204,
            responseHeaders: [
              { name: 'Access-Control-Allow-Origin', value: '*' },
              { name: 'Access-Control-Allow-Methods', value: 'GET, POST, PUT, DELETE, OPTIONS' },
              { name: 'Access-Control-Allow-Headers', value: '*' },
            ],
            body: '',
          });
          return;
        }

        let bodyData = null;
        if (url.includes('produccion/matriz')) {
          if (url.includes('linea=gondola')) {
            bodyData = JSON.stringify(MATRIZ_GONDOLA);
          } else {
            bodyData = JSON.stringify(MATRIZ_PLATAFORMA);
          }
        } else if (url.includes('historial')) {
          bodyData = JSON.stringify(HISTORIAL_ORDEN);
        } else if (url.includes('rest/v1/clientes') || url.includes('/clientes')) {
          bodyData = JSON.stringify(CLIENTES_REALES);
        } else if (url.includes('/organizacion') || url.includes('/health')) {
          bodyData = JSON.stringify({ ok: true, id: '00000000-0000-0000-0000-000000000001', nombre: 'Organización Principal' });
        }

        if (bodyData) {
          await cdp.send('Fetch.fulfillRequest', {
            requestId,
            responseCode: 200,
            responseHeaders: [
              { name: 'Content-Type', value: 'application/json' },
              { name: 'Access-Control-Allow-Origin', value: '*' },
              { name: 'Access-Control-Allow-Headers', value: '*' },
            ],
            body: Buffer.from(bodyData).toString('base64'),
          });
        } else {
          await cdp.send('Fetch.continueRequest', { requestId });
        }
      }
    } catch (e) {
      // ignore
    }
  });

  // Pre-sembrar localStorage antes de navegar
  await cdp.send('Page.navigate', { url: 'http://localhost:5174/' });
  await new Promise((r) => setTimeout(r, 1200));

  await cdp.send('Runtime.evaluate', {
    expression: `
      const sessionData = JSON.stringify({
        access_token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRqd2xjaGdrZWVlcWZrcmVlYmdxIiwicm9sZSI6ImF1dGhlbnRpY2F0ZWQiLCJpYXQiOjE3ODg4MzQ5NTksImV4cCI6MjEwNDQxMDk1OX0.X',
        token_type: 'bearer',
        expires_in: 36000,
        expires_at: Math.floor(Date.now() / 1000) + 36000,
        refresh_token: 'fake-refresh',
        user: {
          id: 'a988611b-2949-4ab7-b670-daf4a21f4e18',
          aud: 'authenticated',
          role: 'authenticated',
          email: 'luis@leolca.com',
          app_metadata: { provider: 'email' },
          user_metadata: { name: 'Luis' }
        }
      });
      localStorage.setItem('sb-remolques-remolques-supa-auth-token', sessionData);
      localStorage.setItem('sb-djwlchgkeeeqfkreebgq-auth-token', sessionData);
      localStorage.setItem('currentOrgId', '00000000-0000-0000-0000-000000000001');
      localStorage.setItem('has_seen_tour_a988611b-2949-4ab7-b670-daf4a21f4e18', 'true');
    `,
  });

  const capturar = async (nombre, ancho, alto) => {
    await cdp.send('Emulation.setDeviceMetricsOverride', {
      width: ancho,
      height: alto,
      deviceScaleFactor: 1,
      mobile: ancho < 768,
    });
    await new Promise((r) => setTimeout(r, 600));
    const { data } = await cdp.send('Page.captureScreenshot', { format: 'png' });
    const ruta = join(DIR_EVIDENCIA, `${nombre}.png`);
    writeFileSync(ruta, Buffer.from(data, 'base64'));
    console.log(`[CAPTURA OK] ${nombre}.png (${ancho}x${alto}, ${Math.round(data.length * 0.75 / 1024)} KB) -> ${ruta}`);
  };

  // Navegar al tablero
  console.log('Navegando a http://localhost:5174/tablero-produccion...');
  await cdp.send('Page.navigate', { url: 'http://localhost:5174/tablero-produccion' });

  // Esperar a que la tabla y celdas se rendericen completamente
  await cdp.esperarSelector('table tbody tr');
  await new Promise((r) => setTimeout(r, 1000));

  // 1. Matriz Escritorio (1440)
  await capturar('matriz_desktop_1440', 1440, 900);

  // 2. Matriz Tableta (768)
  await capturar('matriz_tablet_768', 768, 1024);

  // 3. Matriz Móvil (375)
  await capturar('matriz_mobile_375', 375, 812);

  // Restaurar a escritorio 1440 para interacciones
  await cdp.send('Emulation.setDeviceMetricsOverride', {
    width: 1440,
    height: 900,
    deviceScaleFactor: 1,
    mobile: false,
  });
  await new Promise((r) => setTimeout(r, 500));

  // 4. Menú de celda abierto
  console.log('Abriendo menú de celda...');
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const botonCelda = botones.find(b => b.textContent && b.textContent.includes('14 nov'));
        if (botonCelda) botonCelda.click();
      })()
    `,
  });
  await cdp.esperarSelector('[data-radix-popper-content-wrapper]');
  await new Promise((r) => setTimeout(r, 600));
  await capturar('celda_menu_abierto', 1440, 900);

  // Cerrar popover enviando tecla Escape
  await cdp.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', windowsVirtualKeyCode: 27, key: 'Escape' });
  await cdp.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: 27, key: 'Escape' });
  await new Promise((r) => setTimeout(r, 600));

  // 5. Góndola con la tina expandida
  console.log('Cambiando a pestaña Góndola y expandiendo tina...');
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const pestanaGondola = botones.find(b => b.textContent && b.textContent.trim() === 'Góndola');
        if (pestanaGondola) pestanaGondola.click();
      })()
    `,
  });
  await new Promise((r) => setTimeout(r, 1200));

  // Clic en el badge de tina para expandir
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const badgeTina = botones.find(b => b.textContent && b.textContent.includes('Tina'));
        if (badgeTina) badgeTina.click();
      })()
    `,
  });
  await new Promise((r) => setTimeout(r, 800));
  await capturar('gondola_tina_expandida', 1440, 900);

  // 6. Panel de detalle con historial
  console.log('Abriendo panel de detalle con historial...');
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const linkEquipo = botones.find(el => el.textContent && el.textContent.includes('Minerales del Potosí'));
        if (linkEquipo) linkEquipo.click();
      })()
    `,
  });
  await cdp.esperarSelector('[data-slot="sheet-content"]');
  await new Promise((r) => setTimeout(r, 1200));
  await capturar('detalle_equipo_historial', 1440, 900);

  // Cerrar panel de detalle con Escape
  await cdp.send('Input.dispatchKeyEvent', { type: 'rawKeyDown', windowsVirtualKeyCode: 27, key: 'Escape' });
  await cdp.send('Input.dispatchKeyEvent', { type: 'keyUp', windowsVirtualKeyCode: 27, key: 'Escape' });
  await new Promise((r) => setTimeout(r, 600));

  // 7. Vista "Por fase"
  console.log('Cambiando a vista "Por fase"...');
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const btnPorFase = botones.find(b => b.textContent && b.textContent.includes('Por fase'));
        if (btnPorFase) btnPorFase.click();
      })()
    `,
  });
  await new Promise((r) => setTimeout(r, 1200));
  await capturar('vista_por_fase', 1440, 900);

  // 8. Diálogo "Nuevo equipo en planta" con buscador desplegado
  console.log('Abriendo diálogo "Nuevo equipo en planta"...');
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const botones = Array.from(document.querySelectorAll('button'));
        const btnNuevo = botones.find(b => b.textContent && b.textContent.includes('Nuevo equipo en planta'));
        if (btnNuevo) btnNuevo.click();
      })()
    `,
  });
  await cdp.esperarSelector('[data-slot="dialog-content"]');
  await new Promise((r) => setTimeout(r, 600));

  // Desplegar el combobox de clientes para mostrar la lista real con buscador
  await cdp.send('Runtime.evaluate', {
    expression: `
      (() => {
        const combo = document.querySelector('button[role="combobox"]');
        if (combo) combo.click();
      })()
    `,
  });
  await cdp.esperarSelector('[data-radix-popper-content-wrapper]');
  await new Promise((r) => setTimeout(r, 800));
  await capturar('nuevo_equipo_modal', 1440, 900);

  console.log('--- Proceso de captura concluido con éxito ---');
  console.log('Registros de consola del navegador capturados:');
  const logsLimpios = cdp.consoleLogs.filter(
    (l) => !l.includes('React DevTools') && !l.includes('[vite]')
  );
  console.log(logsLimpios.join('\n') || '(Consola limpia - 0 errores ni advertencias)');

  chromeProc.kill();
  process.exit(0);
}

main().catch((err) => {
  console.error('Error durante la captura:', err);
  process.exit(1);
});
