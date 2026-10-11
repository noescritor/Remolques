#!/usr/bin/env node
// Verificación única antes de reportar "listo". Uso:
//   npm run verificar            -> revisa el árbol de trabajo
//   npm run verificar -- --limpio -> además exporta HEAD a una carpeta limpia y repite pruebas y arranque
//   npm run verificar -- --rapido -> omite build de Vite y arranque del API (solo para iterar)
//
// Qué comprueba (cada paso imprime OK / FALLO y el script termina con código 1 si algo falla):
//  1. Sin archivos de parche nuevos en la raíz (patch_*, fix_*, rewrite_*, update_changelog*, temp_*).
//  2. Archivos modificados vs main: UTF-8 válido, sin BOM, sin mojibake ("Ã³", "â€¢"...), sin marcas de conflicto.
//  3. Sintaxis de cada .ts/.tsx modificado (esbuild).
//  4. tsc: 0 errores de nombres sin definir/duplicados y el total no sube del baseline (scripts/verificar-baseline.json).
//  5. npm run build (Vite).
//  6. Pruebas Deno (motor y utilidades).
//  7. Arranque real del API (debe escribir "Listening on").
//  8. Con --limpio: HEAD exportado con git archive, pruebas y arranque ahí (detecta archivos sin versionar).

import { spawnSync, spawn } from 'node:child_process';
import { readFileSync, existsSync, mkdtempSync, rmSync, readdirSync, symlinkSync, cpSync } from 'node:fs';
import { tmpdir, homedir } from 'node:os';
import { join, resolve, extname } from 'node:path';
import { createRequire } from 'node:module';

const raiz = resolve(import.meta.dirname ?? process.cwd(), '..');
process.chdir(raiz);
const args = new Set(process.argv.slice(2));
const rapido = args.has('--rapido');
const limpio = args.has('--limpio');
const require = createRequire(import.meta.url);

const resultados = [];
const ok = (n, d = '') => { resultados.push({ n, ok: true }); console.log(`  OK     ${n}${d ? ' — ' + d : ''}`); };
const fallo = (n, d = '') => { resultados.push({ n, ok: false }); console.log(`  FALLO  ${n}${d ? ' — ' + d : ''}`); };
const titulo = (t) => console.log(`\n== ${t}`);

const sh = (cmd, argv, opts = {}) =>
  spawnSync(cmd, argv, { encoding: 'utf8', shell: process.platform === 'win32', maxBuffer: 64 * 1024 * 1024, ...opts });

function buscarDeno() {
  const candidatos = [process.env.DENO_BIN, 'deno',
    join(homedir(), '.deno', 'bin', process.platform === 'win32' ? 'deno.exe' : 'deno')].filter(Boolean);
  for (const c of candidatos) {
    const r = sh(c, ['--version']);
    if (r.status === 0) return c;
  }
  return null;
}
const deno = buscarDeno();

function archivosCambiados() {
  const a = sh('git', ['diff', '--name-only', '--diff-filter=ACMR', 'main']).stdout.split('\n');
  const b = sh('git', ['ls-files', '--others', '--exclude-standard']).stdout.split('\n');
  const c = sh('git', ['diff', '--name-only', '--diff-filter=ACMR']).stdout.split('\n');
  return [...new Set([...a, ...b, ...c].map((s) => s.trim()).filter(Boolean))].filter((f) => existsSync(f));
}

// ---------- 1. Archivos de parche ----------
titulo('1. Archivos de parche o temporales nuevos');
{
  const nuevosEnRaiz = sh('git', ['ls-files', '--others', '--exclude-standard']).stdout.split('\n').map((s) => s.trim()).filter(Boolean);
  const agregados = sh('git', ['diff', '--name-only', '--diff-filter=A', 'main']).stdout.split('\n').map((s) => s.trim()).filter(Boolean);
  const malos = [...new Set([...nuevosEnRaiz, ...agregados])].filter((f) => /^(patch|fix|rewrite|update_changelog|temp)[^/]*$/i.test(f) || /^temp_/i.test(f));
  malos.length ? fallo('Sin parches ni temporales', malos.join(', ')) : ok('Sin parches ni temporales');
}

// ---------- 2. Codificación ----------
titulo('2. Codificación de los archivos modificados');
const cambiados = archivosCambiados();
const textoExt = new Set(['.ts', '.tsx', '.js', '.jsx', '.mjs', '.cjs', '.json', '.md', '.sql', '.css', '.html']);
const patronMojibake = /Ã[¡-¿©³±\u0081-\u009F]|â€[\u0090-¿\u0099\u009C\u009D¢\u0093\u0094]|Â[·¡¿°ª]/;
{
  let malos = [];
  for (const f of cambiados) {
    if (!textoExt.has(extname(f).toLowerCase())) continue;
    if (f.includes('/fixtures/') || f.startsWith('docs/importacion/clasificacion') || f === 'scripts/verificar.mjs') continue;
    const buf = readFileSync(f);
    if (buf[0] === 0xef && buf[1] === 0xbb && buf[2] === 0xbf) malos.push(`${f}: BOM`);
    let txt;
    try { txt = new TextDecoder('utf-8', { fatal: true }).decode(buf); }
    catch { malos.push(`${f}: no es UTF-8 válido`); continue; }
    if (patronMojibake.test(txt)) malos.push(`${f}: mojibake (acentos doblemente codificados)`);
    if (/^(<<<<<<<|>>>>>>>) /m.test(txt)) malos.push(`${f}: marcas de conflicto`);
  }
  malos.length ? fallo('UTF-8 sin BOM ni mojibake', '\n           ' + malos.join('\n           ')) : ok('UTF-8 sin BOM ni mojibake', `${cambiados.length} archivos revisados`);
}

// ---------- 3. Sintaxis ----------
titulo('3. Sintaxis de .ts/.tsx modificados');
{
  let esbuild;
  try { esbuild = require('esbuild'); } catch { esbuild = null; }
  if (!esbuild) fallo('Sintaxis (esbuild)', 'esbuild no está instalado (npm ci)');
  else {
    const malos = [];
    for (const f of cambiados.filter((x) => /\.(tsx?|jsx?)$/i.test(x) && !/\.test\./.test(x))) {
      try { esbuild.transformSync(readFileSync(f, 'utf8'), { loader: f.endsWith('x') ? 'tsx' : 'ts' }); }
      catch (e) { malos.push(`${f}:${e.errors?.[0]?.location?.line ?? '?'} ${e.errors?.[0]?.text ?? e.message}`); }
    }
    malos.length ? fallo('Sintaxis válida', '\n           ' + malos.join('\n           ')) : ok('Sintaxis válida');
  }
}

// ---------- 4. tsc ----------
titulo('4. TypeScript (tsc --noEmit)');
{
  const r = sh('npx', ['tsc', '--noEmit']);
  const salida = (r.stdout || '') + (r.stderr || '');
  const nombres = salida.split('\n').filter((l) => /TS2304|TS2300|TS2552|Cannot find name|Duplicate identifier/.test(l));
  const total = salida.split('\n').filter((l) => /error TS\d+/.test(l)).length;
  const baseFile = join('scripts', 'verificar-baseline.json');
  const base = existsSync(baseFile) ? JSON.parse(readFileSync(baseFile, 'utf8')).tsc_total : null;
  nombres.length ? fallo('tsc: 0 nombres sin definir/duplicados', '\n           ' + nombres.slice(0, 8).join('\n           ')) : ok('tsc: 0 nombres sin definir/duplicados');
  if (base === null) ok('tsc: total de errores', `${total} (sin baseline)`);
  else total > base ? fallo('tsc: el total de errores no sube', `${total} > baseline ${base}`) : ok('tsc: el total de errores no sube', `${total} (baseline ${base})`);
}

// ---------- 5. Build ----------
titulo('5. Build de Vite');
if (rapido) console.log('  (omitido por --rapido)');
else {
  const r = sh('npm', ['run', 'build']);
  const s = (r.stdout || '') + (r.stderr || '');
  r.status === 0 && /built in/.test(s) ? ok('npm run build') : fallo('npm run build', '\n           ' + s.split('\n').filter((l) => /rror/.test(l)).slice(0, 6).join('\n           '));
}

// ---------- 6. Pruebas Deno ----------
function pruebasDeno(dir) {
  const objetivos = [];
  const motor = join(dir, 'supabase', 'functions', 'make-server-feea4382', 'motor');
  if (existsSync(motor)) objetivos.push(motor);
  const util = join(dir, 'src', 'app', 'utils');
  if (existsSync(util)) for (const f of readdirSync(util)) if (/\.test\.ts$/.test(f)) objetivos.push(join(util, f));
  if (!objetivos.length) return { ok: true, txt: 'sin pruebas' };
  const r = sh(deno, ['test', '--allow-read', '--no-check', ...objetivos], { cwd: dir });
  const s = (r.stdout || '') + (r.stderr || '');
  const m = s.replace(/\x1b\[[0-9;]*m/g, '').match(/(ok|FAILED) \| (\d+) passed \| (\d+) failed/);
  return { ok: r.status === 0 && !!m, txt: m ? `${m[2]} pasan, ${m[3]} fallan` : s.slice(-400) };
}
titulo('6. Pruebas Deno');
if (!deno) fallo('Pruebas Deno', 'No encuentro deno (define DENO_BIN o instala Deno)');
else { const p = pruebasDeno(raiz); p.ok ? ok('Pruebas Deno', p.txt) : fallo('Pruebas Deno', p.txt); }

// ---------- 7. Arranque del API ----------
function arranque(dir) {
  return new Promise((res) => {
    const carpeta = join(dir, 'supabase', 'functions', 'make-server-feea4382');
    const hijo = spawn(deno, ['run', '--allow-net', '--allow-env', '--allow-read', 'index.ts'], {
      cwd: carpeta, shell: process.platform === 'win32',
      env: { ...process.env, SUPABASE_URL: 'http://localhost', SUPABASE_ANON_KEY: 'x', SUPABASE_SERVICE_ROLE_KEY: 'x' },
    });
    let salida = '';
    const fin = (ok, txt) => { try { if (process.platform === 'win32') spawnSync('taskkill', ['/pid', String(hijo.pid), '/T', '/F']); else hijo.kill('SIGKILL'); } catch {} res({ ok, txt }); };
    const rev = () => {
      const limpio = salida.replace(/\x1b\[[0-9;]*m/g, '');
      if (/AddrInUse|address already in use|os error 10048/i.test(limpio)) return fin(false, 'El puerto 8000 está ocupado: cierra el servidor que lo usa y repite');
      if (/Listening on/.test(limpio)) return fin(true, limpio.split('\n').find((l) => /Listening on/.test(l)));
      if (/SyntaxError|error:|Uncaught|Module not found|Could not find/.test(limpio)) return fin(false, limpio.split('\n').slice(0, 6).join('\n           '));
    };
    hijo.stdout.on('data', (d) => { salida += d; rev(); });
    hijo.stderr.on('data', (d) => { salida += d; rev(); });
    hijo.on('exit', () => rev());
    setTimeout(() => fin(false, 'Tiempo agotado sin "Listening on"\n           ' + salida.slice(0, 300)), 40000);
  });
}
titulo('7. Arranque real del API');
if (rapido || !deno) console.log('  (omitido)');
else { const a = await arranque(raiz); a.ok ? ok('El API arranca', a.txt) : fallo('El API arranca', '\n           ' + a.txt); }

// ---------- 8. Checkout limpio ----------
if (limpio) {
  titulo('8. Checkout limpio de HEAD (git archive)');
  const tmp = mkdtempSync(join(tmpdir(), 'verificar-'));
  try {
    const ar = sh('git', ['archive', 'HEAD', '-o', join(tmp, 'head.tar')]);
    const tar = sh('tar', ['-xf', 'head.tar'], { cwd: tmp });
    if (ar.status !== 0 || tar.status !== 0) fallo('Exportar HEAD', (ar.stderr || tar.stderr || '').slice(0, 200));
    else {
      // Igual que Dockerfile.backend: solo se copian src/app/types y la carpeta de la función, sin package.json.
      for (const f of ['package.json', 'package-lock.json', 'deno.json', 'deno.jsonc', 'deno.lock']) { try { rmSync(join(tmp, f)); } catch {} }
      const p = pruebasDeno(tmp); p.ok ? ok('Pruebas Deno en HEAD limpio', p.txt) : fallo('Pruebas Deno en HEAD limpio', p.txt);
      const a = await arranque(tmp); a.ok ? ok('El API arranca en HEAD limpio', a.txt) : fallo('El API arranca en HEAD limpio', '\n           ' + a.txt);
    }
  } finally { try { rmSync(tmp, { recursive: true, force: true }); } catch {} }
}

// ---------- Resumen ----------
const malos = resultados.filter((r) => !r.ok);
console.log(`\n${'='.repeat(60)}\nRESULTADO: ${malos.length === 0 ? 'TODO OK' : `${malos.length} FALLO(S)`}  (${resultados.length - malos.length}/${resultados.length} comprobaciones)`);
if (malos.length) { console.log('Fallaron:\n  - ' + malos.map((m) => m.n).join('\n  - ')); }
process.exit(malos.length ? 1 : 0);
