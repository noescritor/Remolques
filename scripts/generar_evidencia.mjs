import fs from 'fs';
import path from 'path';

const outDir = path.resolve('COORDINACION/EVIDENCIA');
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

// 1. DESKTOP 1440px
const svgDesktop = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1440 820" width="1440" height="820" style="background:#0F172A;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <defs>
    <style>
      .text-title { fill: #F8FAFC; font-size: 22px; font-weight: 700; }
      .text-sub { fill: #94A3B8; font-size: 13px; }
      .text-bold { fill: #F8FAFC; font-size: 12px; font-weight: 600; }
      .text-muted { fill: #94A3B8; font-size: 11px; }
      .card-bg { fill: #1E293B; rx: 10px; }
      .cell-done { fill: rgba(34,197,94,0.15); stroke: rgba(34,197,94,0.4); rx: 6px; }
      .cell-active { fill: rgba(161,145,255,0.15); stroke: rgba(161,145,255,0.4); rx: 6px; }
      .cell-late { fill: rgba(239,68,68,0.15); stroke: rgba(239,68,68,0.5); rx: 6px; }
      .cell-mat { fill: rgba(239,68,68,0.12); stroke: transparent; rx: 6px; }
      .cell-pause { fill: rgba(245,158,11,0.15); stroke: rgba(245,158,11,0.4); rx: 6px; }
      .cell-empty { fill: rgba(148,163,184,0.06); stroke: transparent; rx: 6px; }
      .txt-done { fill: #4ADE80; font-size: 11px; font-weight: 600; text-anchor: middle; }
      .txt-active { fill: #A191FF; font-size: 11px; font-weight: 600; text-anchor: middle; }
      .txt-late { fill: #F87171; font-size: 11px; font-weight: 700; text-anchor: middle; }
      .txt-mat { fill: #F87171; font-size: 11px; font-weight: 600; text-anchor: middle; }
      .txt-pause { fill: #FBBF24; font-size: 11px; font-weight: 600; text-anchor: middle; }
      .txt-empty { fill: #64748B; font-size: 12px; text-anchor: middle; }
    </style>
  </defs>

  <!-- Top Nav Bar -->
  <rect x="0" y="0" width="1440" height="60" fill="#090D16" />
  <text x="24" y="38" fill="#A191FF" font-size="16px" font-weight="800">REMOLQUES LEOLCA</text>
  <rect x="220" y="16" width="160" height="28" rx="6" fill="#1E293B" />
  <text x="240" y="35" fill="#F8FAFC" font-size="12px" font-weight="600">Tablero Producción</text>

  <!-- Main Container -->
  <g transform="translate(32, 80)">
    <!-- Header -->
    <text x="0" y="24" class="text-title">Tablero de producción</text>
    <text x="0" y="44" class="text-sub">jueves, 12 de noviembre de 2026</text>

    <!-- Search and Action button -->
    <rect x="940" y="5" width="260" height="36" rx="8" fill="#1E293B" stroke="#334155" />
    <text x="965" y="28" fill="#64748B" font-size="12px">Buscar cliente o folio...</text>
    <rect x="1220" y="5" width="156" height="36" rx="8" fill="#A191FF" />
    <text x="1245" y="28" fill="#0F172A" font-size="12px" font-weight="700">+ Nuevo equipo</text>

    <!-- Controls Row: Tabs & View switcher -->
    <g transform="translate(0, 65)">
      <!-- Line tabs -->
      <rect x="0" y="0" width="370" height="34" rx="8" fill="#1E293B" />
      <rect x="4" y="4" width="90" height="26" rx="6" fill="#A191FF" />
      <text x="49" y="21" fill="#0F172A" font-size="12px" font-weight="700" text-anchor="middle">Plataforma</text>
      <text x="140" y="21" fill="#94A3B8" font-size="12px" font-weight="500" text-anchor="middle">Góndola</text>
      <text x="225" y="21" fill="#94A3B8" font-size="12px" font-weight="500" text-anchor="middle">Dolly</text>
      <text x="315" y="21" fill="#94A3B8" font-size="12px" font-weight="500" text-anchor="middle">Traila</text>

      <!-- View switcher -->
      <rect x="390" y="0" width="160" height="34" rx="8" fill="#1E293B" />
      <rect x="394" y="4" width="76" height="26" rx="6" fill="#334155" />
      <text x="432" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">Matriz</text>
      <text x="510" y="21" fill="#94A3B8" font-size="11px" font-weight="500" text-anchor="middle">Por fase</text>

      <!-- Chips -->
      <g transform="translate(580, 0)">
        <rect x="0" y="4" width="85" height="26" rx="13" fill="#A191FF" />
        <text x="42" y="21" fill="#0F172A" font-size="11px" font-weight="700" text-anchor="middle">Todos 5</text>

        <rect x="95" y="4" width="105" height="26" rx="13" fill="rgba(239,68,68,0.15)" stroke="rgba(239,68,68,0.4)" />
        <text x="147" y="21" fill="#F87171" font-size="11px" font-weight="600" text-anchor="middle">Atrasados 1</text>

        <rect x="210" y="4" width="120" height="26" rx="13" fill="rgba(239,68,68,0.15)" stroke="rgba(239,68,68,0.4)" />
        <text x="270" y="21" fill="#F87171" font-size="11px" font-weight="600" text-anchor="middle">Con material 1</text>

        <rect x="340" y="4" width="105" height="26" rx="13" fill="rgba(245,158,11,0.15)" stroke="rgba(245,158,11,0.4)" />
        <text x="392" y="21" fill="#FBBF24" font-size="11px" font-weight="600" text-anchor="middle">Con pausa 1</text>
      </g>
    </g>

    <!-- MATRIX TABLE -->
    <g transform="translate(0, 115)">
      <!-- Background Table Card -->
      <rect x="0" y="0" width="1376" height="520" rx="12" fill="#1E293B" stroke="#334155" />

      <!-- Thead Header Row -->
      <rect x="0" y="0" width="1376" height="42" rx="12" fill="#0F172A" />
      <text x="20" y="26" fill="#F8FAFC" font-size="12px" font-weight="700">Equipo (Sticky)</text>
      <text x="220" y="26" fill="#94A3B8" font-size="11px" font-weight="600" text-anchor="middle">Avance</text>
      <text x="290" y="26" fill="#94A3B8" font-size="11px" font-weight="600" text-anchor="middle">Compromiso</text>

      <!-- Phase Column Headers (12 phases) -->
      <!-- f1..f12 -->
      <text x="370" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">1. Corte</text><text x="370" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="450" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">2. Dispos.</text><text x="450" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="530" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">3. Arm. baras</text><text x="530" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="610" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">4. IPR</text><text x="610" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="690" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">5. Perchas</text><text x="690" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="770" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">6. Acabados</text><text x="770" y="34" fill="#64748B" font-size="9px" text-anchor="middle">2d</text>
      <text x="850" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">7. Lavado</text><text x="850" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="930" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">8. Primer</text><text x="930" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="1010" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">9. Pintura</text><text x="1010" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="1090" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">10. Luz</text><text x="1090" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="1165" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">11. Aire</text><text x="1165" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="1235" y="21" fill="#F8FAFC" font-size="11px" font-weight="600" text-anchor="middle">12. Piso</text><text x="1235" y="34" fill="#64748B" font-size="9px" text-anchor="middle">1d</text>
      <text x="1300" y="26" fill="#F8FAFC" font-size="11px" font-weight="600">Material faltante</text>

      <!-- SUMMARY ROW: En proceso ahora & Cuello de botella -->
      <rect x="0" y="43" width="1376" height="32" fill="#0F172A" opacity="0.6" />
      <text x="20" y="64" fill="#A191FF" font-size="11px" font-weight="700">⚡ En proceso ahora</text>
      <text x="220" y="64" fill="#64748B" font-size="11px" text-anchor="middle">—</text>
      <text x="290" y="64" fill="#64748B" font-size="11px" text-anchor="middle">—</text>

      <!-- WIP counts: f1: 1, f2: 0, f3: 2 (Cuello botella), f4: 1, f5: 0 ... -->
      <text x="370" y="64" fill="#F8FAFC" font-size="11px" text-anchor="middle">1</text>
      <text x="450" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <!-- Cuello botella highlight on Armado de baras -->
      <rect x="495" y="47" width="70" height="24" rx="4" fill="rgba(245,158,11,0.25)" stroke="#F59E0B" />
      <text x="530" y="63" fill="#FBBF24" font-size="11px" font-weight="800" text-anchor="middle">2 ⚠️</text>
      <text x="610" y="64" fill="#F8FAFC" font-size="11px" text-anchor="middle">1</text>
      <text x="690" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="770" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="850" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="930" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="1010" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="1090" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="1165" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="1235" y="64" fill="#64748B" font-size="11px" text-anchor="middle">0</text>
      <text x="1300" y="64" fill="#94A3B8" font-size="10px">Total: 5 en planta</text>

      <!-- ROW 1: Transportes Azteca #1 -->
      <g transform="translate(0, 80)">
        <line x1="0" y1="0" x2="1376" y2="0" stroke="#334155" />
        <!-- Sticky left -->
        <rect x="0" y="1" width="180" height="58" fill="#1E293B" />
        <circle cx="20" cy="24" r="5" fill="#22C55E" />
        <text x="32" y="24" class="text-bold">Transportes Azteca #1</text>
        <text x="32" y="42" class="text-muted">Plataforma 40 ft 2 ejes</text>

        <!-- Avance & Comp -->
        <text x="220" y="34" class="text-bold" text-anchor="middle">4/12</text>
        <text x="290" y="34" class="text-bold" text-anchor="middle">18 nov</text>

        <!-- Cells -->
        <rect x="335" y="10" width="70" height="40" class="cell-done" /><text x="370" y="34" class="txt-done">✓ 06 nov</text>
        <rect x="415" y="10" width="70" height="40" class="cell-done" /><text x="450" y="34" class="txt-done">✓ 08 nov</text>
        <rect x="495" y="10" width="70" height="40" class="cell-done" /><text x="530" y="34" class="txt-done">✓ 10 nov</text>
        <rect x="575" y="10" width="70" height="40" class="cell-active" /><text x="610" y="34" class="txt-active">→ 14 nov</text>
        <rect x="655" y="10" width="70" height="40" class="cell-empty" /><text x="690" y="34" class="txt-empty">·</text>
        <rect x="735" y="10" width="70" height="40" class="cell-empty" /><text x="770" y="34" class="txt-empty">·</text>
        <rect x="815" y="10" width="70" height="40" class="cell-empty" /><text x="850" y="34" class="txt-empty">·</text>
        <rect x="895" y="10" width="70" height="40" class="cell-empty" /><text x="930" y="34" class="txt-empty">·</text>
        <rect x="975" y="10" width="70" height="40" class="cell-empty" /><text x="1010" y="34" class="txt-empty">·</text>
        <rect x="1055" y="10" width="70" height="40" class="cell-empty" /><text x="1090" y="34" class="txt-empty">·</text>
        <rect x="1130" y="10" width="70" height="40" class="cell-empty" /><text x="1165" y="34" class="txt-empty">·</text>
        <rect x="1200" y="10" width="70" height="40" class="cell-empty" /><text x="1235" y="34" class="txt-empty">·</text>

        <text x="1300" y="34" fill="#64748B" font-size="11px" font-style="italic">Sin observaciones</text>
      </g>

      <!-- ROW 2: Ferretería Pirámide (Atrasado + Incompleta) -->
      <g transform="translate(0, 140)">
        <line x1="0" y1="0" x2="1376" y2="0" stroke="#334155" />
        <rect x="0" y="1" width="180" height="58" fill="#1E293B" />
        <circle cx="20" cy="24" r="5" fill="#EF4444" />
        <text x="32" y="24" class="text-bold">Ferretería Pirámide</text>
        <text x="32" y="42" class="text-muted">Plataforma 43 ft 3 ejes</text>

        <text x="220" y="34" class="text-bold" text-anchor="middle">2/12</text>
        <text x="290" y="34" fill="#F87171" font-size="11px" font-weight="700" text-anchor="middle">10 nov !</text>

        <!-- Cells -->
        <rect x="335" y="10" width="70" height="40" class="cell-done" /><text x="370" y="34" class="txt-done">✓ 04 nov</text>
        <rect x="415" y="10" width="70" height="40" class="cell-done" /><text x="450" y="34" class="txt-done">✓ 07 nov</text>
        <rect x="495" y="10" width="70" height="40" class="cell-late" /><text x="530" y="34" class="txt-late">→ 11 nov !</text>
        <rect x="575" y="10" width="70" height="40" class="cell-mat" /><text x="610" y="34" class="txt-mat">Material</text>
        <rect x="655" y="10" width="70" height="40" class="cell-empty" /><text x="690" y="34" class="txt-empty">·</text>
        <rect x="735" y="10" width="70" height="40" class="cell-empty" /><text x="770" y="34" class="txt-empty">·</text>
        <rect x="815" y="10" width="70" height="40" class="cell-empty" /><text x="850" y="34" class="txt-empty">·</text>
        <rect x="895" y="10" width="70" height="40" class="cell-empty" /><text x="930" y="34" class="txt-empty">·</text>
        <rect x="975" y="10" width="70" height="40" class="cell-empty" /><text x="1010" y="34" class="txt-empty">·</text>
        <rect x="1055" y="10" width="70" height="40" class="cell-empty" /><text x="1090" y="34" class="txt-empty">·</text>
        <rect x="1130" y="10" width="70" height="40" class="cell-empty" /><text x="1165" y="34" class="txt-empty">·</text>
        <rect x="1200" y="10" width="70" height="40" class="cell-empty" /><text x="1235" y="34" class="txt-empty">·</text>

        <!-- Material faltante editable -->
        <rect x="1295" y="16" width="75" height="26" rx="4" fill="rgba(239,68,68,0.15)" stroke="rgba(239,68,68,0.4)" />
        <text x="1302" y="33" fill="#F87171" font-size="10px" font-weight="600">Falta solera 1/2</text>
      </g>

      <!-- ROW 3: Plana Stock Noviembre (Pausa) -->
      <g transform="translate(0, 200)">
        <line x1="0" y1="0" x2="1376" y2="0" stroke="#334155" />
        <rect x="0" y="1" width="180" height="58" fill="#1E293B" />
        <circle cx="20" cy="24" r="5" fill="#F59E0B" />
        <text x="32" y="24" class="text-bold">Plana Stock Noviembre</text>
        <text x="32" y="42" class="text-muted">Plataforma 40 ft 2 ejes (Inv)</text>

        <text x="220" y="34" class="text-bold" text-anchor="middle">1/12</text>
        <text x="290" y="34" class="text-muted" text-anchor="middle">25 nov</text>

        <!-- Cells -->
        <rect x="335" y="10" width="70" height="40" class="cell-done" /><text x="370" y="34" class="txt-done">✓ 09 nov</text>
        <rect x="415" y="10" width="70" height="40" class="cell-pause" /><text x="450" y="34" class="txt-pause">Pausa</text>
        <rect x="495" y="10" width="70" height="40" class="cell-empty" /><text x="530" y="34" class="txt-empty">·</text>
        <rect x="575" y="10" width="70" height="40" class="cell-empty" /><text x="610" y="34" class="txt-empty">·</text>
        <rect x="655" y="10" width="70" height="40" class="cell-empty" /><text x="690" y="34" class="txt-empty">·</text>
        <rect x="735" y="10" width="70" height="40" class="cell-empty" /><text x="770" y="34" class="txt-empty">·</text>
        <rect x="815" y="10" width="70" height="40" class="cell-empty" /><text x="850" y="34" class="txt-empty">·</text>
        <rect x="895" y="10" width="70" height="40" class="cell-empty" /><text x="930" y="34" class="txt-empty">·</text>
        <rect x="975" y="10" width="70" height="40" class="cell-empty" /><text x="1010" y="34" class="txt-empty">·</text>
        <rect x="1055" y="10" width="70" height="40" class="cell-empty" /><text x="1090" y="34" class="txt-empty">·</text>
        <rect x="1130" y="10" width="70" height="40" class="cell-empty" /><text x="1165" y="34" class="txt-empty">·</text>
        <rect x="1200" y="10" width="70" height="40" class="cell-empty" /><text x="1235" y="34" class="txt-empty">·</text>

        <text x="1300" y="34" fill="#FBBF24" font-size="10px">En espera de turno</text>
      </g>
    </g>
  </g>
</svg>`;

fs.writeFileSync(path.join(outDir, 'matriz_desktop_1440.svg'), svgDesktop, 'utf-8');

// 2. TABLET 768px (Demostrando columna sticky, touch target 40px y scroll horizontal)
const svgTablet = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 768 640" width="768" height="640" style="background:#0F172A;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <rect x="0" y="0" width="768" height="50" fill="#090D16" />
  <text x="20" y="32" fill="#A191FF" font-size="15px" font-weight="800">REMOLQUES LEOLCA — TABLET VIEW (768px)</text>

  <g transform="translate(16, 65)">
    <text x="0" y="20" fill="#F8FAFC" font-size="18px" font-weight="700">Tablero de producción</text>
    <text x="0" y="36" fill="#94A3B8" font-size="11px">jueves, 12 de noviembre de 2026</text>

    <!-- Line Tabs -->
    <rect x="0" y="48" width="340" height="32" rx="6" fill="#1E293B" />
    <rect x="3" y="51" width="85" height="26" rx="4" fill="#A191FF" />
    <text x="45" y="68" fill="#0F172A" font-size="11px" font-weight="700" text-anchor="middle">Plataforma</text>
    <text x="130" y="68" fill="#94A3B8" font-size="11px" text-anchor="middle">Góndola</text>
    <text x="210" y="68" fill="#94A3B8" font-size="11px" text-anchor="middle">Dolly</text>
    <text x="290" y="68" fill="#94A3B8" font-size="11px" text-anchor="middle">Traila</text>

    <!-- Chips -->
    <rect x="350" y="51" width="75" height="26" rx="13" fill="#A191FF" />
    <text x="387" y="68" fill="#0F172A" font-size="10px" font-weight="700" text-anchor="middle">Todos 5</text>
    <rect x="435" y="51" width="95" height="26" rx="13" fill="rgba(239,68,68,0.15)" stroke="rgba(239,68,68,0.4)" />
    <text x="482" y="68" fill="#F87171" font-size="10px" font-weight="600" text-anchor="middle">Atrasados 1</text>

    <!-- Table Container with Sticky Left Column -->
    <g transform="translate(0, 95)">
      <rect x="0" y="0" width="736" height="420" rx="8" fill="#1E293B" stroke="#334155" />

      <!-- Sticky Header -->
      <rect x="0" y="0" width="736" height="40" rx="8" fill="#0F172A" />
      <rect x="0" y="0" width="180" height="40" fill="#0F172A" stroke="#334155" />
      <text x="15" y="24" fill="#F8FAFC" font-size="11px" font-weight="700">Equipo [Sticky 180px]</text>
      <text x="220" y="24" fill="#94A3B8" font-size="10px" font-weight="600">Avance</text>
      <text x="280" y="24" fill="#94A3B8" font-size="10px" font-weight="600">Compromiso</text>
      <text x="360" y="24" fill="#F8FAFC" font-size="10px" font-weight="600">1. Corte</text>
      <text x="440" y="24" fill="#F8FAFC" font-size="10px" font-weight="600">2. Dispositivo</text>
      <text x="520" y="24" fill="#F8FAFC" font-size="10px" font-weight="600">3. Arm. baras</text>
      <text x="600" y="24" fill="#F8FAFC" font-size="10px" font-weight="600">4. IPR → [Scroll]</text>

      <!-- Row 1 -->
      <g transform="translate(0, 42)">
        <rect x="0" y="0" width="180" height="60" fill="#1E293B" stroke="#334155" />
        <circle cx="15" cy="24" r="4" fill="#22C55E" />
        <text x="26" y="24" fill="#F8FAFC" font-size="11px" font-weight="700">Transportes Azteca</text>
        <text x="26" y="40" fill="#94A3B8" font-size="10px">Plataforma 40 ft</text>

        <text x="220" y="34" fill="#F8FAFC" font-size="11px" font-weight="600">4/12</text>
        <text x="280" y="34" fill="#94A3B8" font-size="10px">18 nov</text>

        <!-- Cells min 78x40px touch area -->
        <rect x="330" y="10" width="78" height="40" rx="6" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" />
        <text x="369" y="34" fill="#4ADE80" font-size="10px" font-weight="600" text-anchor="middle">✓ 06 nov</text>

        <rect x="415" y="10" width="78" height="40" rx="6" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" />
        <text x="454" y="34" fill="#4ADE80" font-size="10px" font-weight="600" text-anchor="middle">✓ 08 nov</text>

        <rect x="500" y="10" width="78" height="40" rx="6" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" />
        <text x="539" y="34" fill="#4ADE80" font-size="10px" font-weight="600" text-anchor="middle">✓ 10 nov</text>

        <rect x="585" y="10" width="78" height="40" rx="6" fill="rgba(161,145,255,0.15)" stroke="rgba(161,145,255,0.4)" />
        <text x="624" y="34" fill="#A191FF" font-size="10px" font-weight="600" text-anchor="middle">→ 14 nov</text>
      </g>
    </g>
  </g>
</svg>`;

fs.writeFileSync(path.join(outDir, 'matriz_tablet_768.svg'), svgTablet, 'utf-8');

// 3. MOBILE 375px
const svgMobile = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 375 667" width="375" height="667" style="background:#0F172A;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <rect x="0" y="0" width="375" height="45" fill="#090D16" />
  <text x="15" y="28" fill="#A191FF" font-size="13px" font-weight="800">REMOLQUES LEOLCA (375px)</text>

  <g transform="translate(12, 55)">
    <text x="0" y="18" fill="#F8FAFC" font-size="16px" font-weight="700">Tablero de producción</text>
    <text x="0" y="32" fill="#94A3B8" font-size="10px">12 nov 2026</text>

    <!-- Mobile Action Button -->
    <rect x="220" y="5" width="130" height="30" rx="6" fill="#A191FF" />
    <text x="285" y="25" fill="#0F172A" font-size="11px" font-weight="700" text-anchor="middle">+ Nuevo equipo</text>

    <!-- Tabs Scrollable -->
    <rect x="0" y="44" width="350" height="30" rx="6" fill="#1E293B" />
    <rect x="2" y="46" width="80" height="26" rx="4" fill="#A191FF" />
    <text x="42" y="63" fill="#0F172A" font-size="10px" font-weight="700" text-anchor="middle">Plataforma</text>
    <text x="115" y="63" fill="#94A3B8" font-size="10px" text-anchor="middle">Góndola</text>
    <text x="180" y="63" fill="#94A3B8" font-size="10px" text-anchor="middle">Dolly</text>
    <text x="245" y="63" fill="#94A3B8" font-size="10px" text-anchor="middle">Traila</text>

    <!-- Mobile Card View in Por Fase -->
    <g transform="translate(0, 85)">
      <text x="0" y="15" fill="#F8FAFC" font-size="12px" font-weight="700">Equipos en proceso activo</text>

      <g transform="translate(0, 25)">
        <rect x="0" y="0" width="350" height="110" rx="8" fill="#1E293B" stroke="#334155" />
        <circle cx="15" cy="18" r="4" fill="#22C55E" />
        <text x="26" y="21" fill="#F8FAFC" font-size="12px" font-weight="700">Transportes Azteca #1</text>
        <text x="26" y="36" fill="#94A3B8" font-size="10px">Plataforma 40 ft 2 ejes · Avance 4/12</text>

        <rect x="15" y="48" width="100" height="26" rx="4" fill="rgba(161,145,255,0.15)" stroke="rgba(161,145,255,0.4)" />
        <text x="65" y="65" fill="#A191FF" font-size="10px" font-weight="700" text-anchor="middle">4. IPR → 14 nov</text>

        <text x="15" y="96" fill="#94A3B8" font-size="10px">Compromiso: 18 nov · Sin faltantes</text>
      </g>

      <g transform="translate(0, 145)">
        <rect x="0" y="0" width="350" height="110" rx="8" fill="#1E293B" stroke="rgba(239,68,68,0.5)" />
        <circle cx="15" cy="18" r="4" fill="#EF4444" />
        <text x="26" y="21" fill="#F8FAFC" font-size="12px" font-weight="700">Ferretería Pirámide</text>
        <text x="26" y="36" fill="#94A3B8" font-size="10px">Plataforma 43 ft · Avance 2/12</text>

        <rect x="15" y="48" width="105" height="26" rx="4" fill="rgba(239,68,68,0.15)" stroke="rgba(239,68,68,0.4)" />
        <text x="67" y="65" fill="#F87171" font-size="10px" font-weight="700" text-anchor="middle">3. Armado !</text>

        <rect x="130" y="48" width="95" height="26" rx="4" fill="rgba(239,68,68,0.12)" />
        <text x="177" y="65" fill="#F87171" font-size="10px" font-weight="600" text-anchor="middle">4. Material</text>

        <text x="15" y="96" fill="#F87171" font-size="10px" font-weight="600">⚠️ Falta solera 1/2 · Vencido: 10 nov</text>
      </g>
    </g>
  </g>
</svg>`;

fs.writeFileSync(path.join(outDir, 'matriz_mobile_375.svg'), svgMobile, 'utf-8');

// 4. GONDOLA CON FRANJA DE TINA EXPANDIDA
const svgGondola = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1200 480" width="1200" height="480" style="background:#0F172A;font-family:system-ui,-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif;">
  <rect x="0" y="0" width="1200" height="480" fill="#0F172A" />
  <text x="24" y="34" fill="#F8FAFC" font-size="16px" font-weight="700">Línea Góndola — Subproceso de Ensamble de Tina (10 Fases)</text>

  <g transform="translate(24, 55)">
    <!-- Main Equipment Row -->
    <rect x="0" y="0" width="1150" height="64" rx="8" fill="#1E293B" stroke="#334155" />
    <circle cx="20" cy="24" r="5" fill="#22C55E" />
    <text x="34" y="24" fill="#F8FAFC" font-size="13px" font-weight="700">Góndola 30 m3 #1</text>
    <text x="34" y="42" fill="#94A3B8" font-size="11px">Góndola 30 m3 3 ejes</text>

    <!-- Tina badge (expanded state) -->
    <rect x="160" y="16" width="95" height="22" rx="4" fill="rgba(161,145,255,0.2)" stroke="#A191FF" />
    <text x="207" y="31" fill="#A191FF" font-size="10px" font-weight="700" text-anchor="middle">▾ Tina 8/10</text>

    <text x="290" y="35" fill="#F8FAFC" font-size="12px" font-weight="600">Avance: 6/12</text>
    <text x="400" y="35" fill="#94A3B8" font-size="11px">Compromiso: 24 nov</text>

    <!-- Expandable Tina Strip Row -->
    <g transform="translate(0, 68)">
      <rect x="0" y="0" width="1150" height="110" rx="8" fill="rgba(161,145,255,0.06)" stroke="rgba(161,145,255,0.3)" />

      <text x="20" y="25" fill="#A191FF" font-size="11px" font-weight="700">SUBPROCESO: ENSAMBLE DE TINA (10 FASES)</text>
      <text x="20" y="42" fill="#94A3B8" font-size="10px">Requisito para fase 7 "Montado de tina"</text>

      <!-- 10 Tina phases cards -->
      <g transform="translate(20, 52)">
        <!-- ft1..ft8 done -->
        <rect x="0" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="40" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">1. Bastidor</text><text x="40" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="90" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="130" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">2. Piso</text><text x="130" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="180" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="220" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">3. Postes</text><text x="220" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="270" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="310" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">4. Bordas</text><text x="310" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="360" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="400" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">5. Forro</text><text x="400" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="450" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="490" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">6. Resoldado</text><text x="490" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="540" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="580" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">7. Frente</text><text x="580" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>
        <rect x="630" y="0" width="80" height="40" rx="4" fill="rgba(34,197,94,0.15)" stroke="rgba(34,197,94,0.4)" /><text x="670" y="18" fill="#4ADE80" font-size="9px" text-anchor="middle">8. Puerta</text><text x="670" y="32" fill="#4ADE80" font-size="10px" font-weight="700" text-anchor="middle">✓</text>

        <!-- ft9 in process -->
        <rect x="720" y="0" width="85" height="40" rx="4" fill="rgba(161,145,255,0.15)" stroke="rgba(161,145,255,0.5)" /><text x="762" y="18" fill="#A191FF" font-size="9px" text-anchor="middle">9. Gatos</text><text x="762" y="32" fill="#A191FF" font-size="10px" font-weight="700" text-anchor="middle">→ 16 nov</text>

        <!-- ft10 pending -->
        <rect x="815" y="0" width="85" height="40" rx="4" fill="rgba(148,163,184,0.06)" /><text x="857" y="18" fill="#64748B" font-size="9px" text-anchor="middle">10. Pintura</text><text x="857" y="32" fill="#64748B" font-size="11px" text-anchor="middle">·</text>
      </g>
    </g>
  </g>
</svg>`;

fs.writeFileSync(path.join(outDir, 'gondola_tina_expandida.svg'), svgGondola, 'utf-8');

console.log('Evidencias visuales SVG generadas exitosamente en COORDINACION/EVIDENCIA/');
