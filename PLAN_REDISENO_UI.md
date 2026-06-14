# Plan de Rediseño UI/UX — Cotización App Admin

**Fecha:** Junio 2026
**Fase:** 4 — Rediseño visual y de experiencia (post Fase 3 / Portal+Firma)
**Implementación:** Antigravity (este documento es la guía de planeación/spec)
**Decisión de alcance:** Migración completa a Moodboard Kit 3.0 (dark theme)

---

## 0. Alcance general

Se migra **toda la interfaz interna de la app** (Dashboard, Cotizaciones, Clientes, Productos,
Inventario, Plantillas, Proyectos, Ajustes, Auth) al design system **Moodboard Kit 3.0**:
dark mode por defecto, paleta violeta `#A191FF`, tipografía DM Sans / DM Mono, componentes
Radix UI con los patrones ya definidos (modales `h-[92vh]`, tabs, badges, stat cards, tablas).

**Fuera de alcance por ahora** (no se tocan en esta fase, mantienen su estilo actual):
- `PDFTemplate*` / `PDFFullPage*` — plantillas de PDF para el cliente final (documentos formales, mantienen diseño propio).
- `PortalCliente.tsx` — se revisa en una fase posterior si el prospecto lo pide; no es parte de las 4 mejoras solicitadas.

**Orden de ejecución** (de mayor a menor impacto en demo):
1. Setup global del design system (tokens, fuentes, tema base)
2. Dashboard
3. Productos (vista cards + categorías)
4. Calculadora (módulo de sidebar)
5. Clientes + capas de personalización
6. Onboarding (Login/Registro + Tour)

Cada bloque abajo es una unidad que se puede entregar y probar por separado.

---

## 1. Setup global del Design System

**Objetivo:** preparar la base para que todos los módulos siguientes se construyan sobre el
mismo sistema, sin retrabajo.

### Tareas
- [ ] Agregar fuentes **DM Sans** (sans) y **DM Mono** (mono) — vía `next/font` no aplica (es Vite);
      usar `@fontsource/dm-sans` y `@fontsource/dm-mono`, o `<link>` a Google Fonts en `index.html`.
- [ ] Definir tokens de color en `tailwind.config` (o CSS vars en `styles/globals.css`):
  ```
  --bg-base: #000000
  --bg-card: #0d0d0d
  --bg-elevated: #1a1a1a
  --accent-violet: #A191FF
  --accent-blue: #91CAFF
  --accent-green: #91FFB0
  --accent-yellow: #FFD391
  --accent-pink: #FF919F
  --accent-purple: #DC91FF
  --text-primary: rgba(255,255,255,1)
  --text-secondary: rgba(255,255,255,0.60)
  --text-tertiary: rgba(255,255,255,0.40)
  --text-muted: rgba(255,255,255,0.25)
  --border-default: rgba(255,255,255,0.08)
  --border-soft: rgba(255,255,255,0.06)
  --border-hover: rgba(255,255,255,0.20)
  ```
- [ ] Crear clase utilitaria `text-label` (DM Mono, uppercase, `text-[11px]`, `tracking-wide`).
- [ ] Aplicar `bg-black text-white` en el layout raíz (`App.tsx` / shell principal).
- [ ] Revisar componentes base en `components/ui/*` (button, input, card, badge, dialog, tabs,
      select, table) — son shadcn; ajustar sus variantes default para que hereden los colores
      del Moodboard Kit en lugar de los grises de Tailwind por defecto. Esto evita tener que
      sobreescribir clases en cada módulo.
- [ ] Sidebar / navegación principal: aplicar patrón de "Navegación principal (tabs de módulo)"
      del design system (borde activo violeta).

**Entregable:** la app carga en negro, con tipografía correcta, y los componentes base
(`Button`, `Card`, `Badge`, `Input`, `Dialog`, `Tabs`) ya respetan la paleta — listo para
que los módulos siguientes solo necesiten layout, no recoloreo.

---

## 2. Dashboard — Panel operativo

**Componentes afectados:** `components/Dashboard/DashboardMain.tsx`, `QuickStats.tsx`, `QuickActions.tsx`

### Objetivo
Pasar de un dashboard estático de métricas a un **panel de acción diaria**: qué necesita
atención del usuario hoy.

### Estructura propuesta

**A. Header**
- Saludo + fecha, botón primario "Nueva Cotización" (estilo CTA del design system).

**B. Stat cards (fila superior)** — usar patrón "Stat card" del design system (`bg-white/[0.02]`,
   `border-white/[0.06]`, label en `text-label text-white/25`, valor en DM Mono):
   - Total cotizaciones (+ tasa de aprobación como sub)
   - Ingresos reales (pagos recibidos)
   - Ventas generadas (aprobadas/pagadas)
   - Clientes activos
   - Productos en catálogo

   *(Mantener el cálculo actual de `estadisticas` en `DashboardMain.tsx` — solo cambia
   presentación visual, usando los colores accent del kit en vez de blue/green/purple/orange.)*

**C. Sección "Pendientes" (NUEVA — núcleo del rediseño)**
Tres bloques tipo lista, cada uno con badge de color del kit según urgencia:

1. **Por fabricar / entregar**
   - Cotizaciones con `estado = 'Aprobada'` o `'Pagada'` que aún no se marcan como completadas
     (requiere revisar si existe un campo de "entregado" — si no existe, **flag para Antigravity**:
     posible necesidad de un campo nuevo `completado: boolean` o reutilizar estado del Inventario).
   - Vista: lista compacta, folio + cliente + fecha + badge `PENDIENTE` (`#FFD391`).

2. **Cotizaciones perdidas de vista**
   - Regla: `estado = 'Borrador'` con más de N días desde `created_at` sin enviar, **o**
     `estado = 'Enviada'` con más de N días sin respuesta del cliente (sin cambio de estado).
   - N configurable (sugerido: 3 días borrador, 5 días enviada — definir constante en config).
   - Badge `SIN RESPUESTA` (`#FF919F`) o `SIN ENVIAR` (`#FFD391`).

3. **Fechas críticas / próximas entregas**
   - Si existe campo de fecha de entrega en `Cotizacion` o `ItemCotizacion` → listar las próximas 5,
     ordenadas por fecha. **Flag para Antigravity:** el tipo actual (`types/index.ts`) no tiene
     campo de fecha de entrega — definir si se agrega `fecha_entrega?: string` a `Cotizacion`
     (más simple) o a nivel item (más preciso, pero más trabajo). Recomendación: a nivel
     `Cotizacion` por ahora.
   - Vista: mini-calendario o lista ordenada por fecha con folio + cliente + días restantes
     (badge rojo si vencido, amarillo si ≤2 días, verde si ok).

**D. Gráficos** (mantener, pero re-skinnear con paleta dark):
   - Pie de distribución por estado (colores del kit: borrador=`white/25`, enviada=`#91CAFF`,
     aprobada=`#91FFB0`, pagada=`#A191FF`, rechazada/cancelada=`#FF919F`, vencida=`#FFD391`)
   - Línea de tendencia mensual (cotizaciones + ingresos) — usar `#A191FF` y `#91FFB0` como líneas.
   - Recharts soporta estilos via props, no Tailwind directo — pasar colores como hex.

**E. Cotizaciones recientes**
   - Mantener, pero como tabla con el patrón "Tabla estándar" del kit (hover `bg-white/[0.02]`,
     badges de estado con los colores correctos).

### Preguntas abiertas (resolver antes de implementar en Antigravity)
- ¿Qué define "pendiente de fabricar/entregar"? ¿Hay ya algo en Inventario que lo indique,
  o se necesita un campo nuevo de estado de producción?
- ¿Umbral de días para "perdida de vista" — el prospecto mencionó algo específico?
- ¿Fecha de entrega: a nivel cotización o por item? (afecta si se necesita migración SQL)

---

## 3. Productos — Vista de tarjetas + categorías

**Componentes afectados:** `components/Productos/ProductosList.tsx`, `CalculadoraMaterial.tsx`,
`types/index.ts` (nuevo campo de categoría)

### Cambios de datos (requiere migración Supabase)
- [ ] Nueva tabla `categorias_producto`:
  ```sql
  CREATE TABLE categorias_producto (
    id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id uuid NOT NULL,
    nombre text NOT NULL,
    color text, -- uno de los accents del kit, ej '#A191FF'
    icono text, -- nombre de ícono Lucide (opcional)
    orden int DEFAULT 0,
    created_at timestamptz DEFAULT now()
  );
  ```
- [ ] `Producto` (types/index.ts): agregar `categoria_id?: string` y opcionalmente
  `imagen_url?: string` / `color?: string` para la tarjeta.
- [ ] Categorías por defecto sugeridas (editable por el usuario, no hardcoded):
  `Grabado`, `Sublimación`, `DTF UV`, `Impresión` — como **seed data** al primer load,
  igual que los demás módulos (`localStorage` / seed en Supabase al crear organización).

### UI — Vista de tarjetas
- Grid responsivo (`grid-cols-2 sm:grid-cols-3 lg:grid-cols-4`), cada card:
  - Imagen/color de categoría como header de la card (si no hay imagen, bloque de color sólido
    con ícono Lucide centrado).
  - Nombre, tipo (Bien/Servicio) como badge pequeño.
  - Precio (usar lógica `renderPrecioInfo` ya existente).
  - Margen como badge de color (verde si saludable, amarillo si bajo, rojo si negativo —
    definir umbrales).
  - Acciones (editar/eliminar) en hover, esquina superior derecha.
- **Filtro por categoría**: chips horizontales arriba del grid (`Todas | Grabado | Sublimación | ...`),
  estilo tab del design system.
- Mantener buscador existente.
- Toggle vista tabla/cards (opcional) — para catálogos grandes la tabla sigue siendo útil;
  se puede usar `Tabs` o un simple ícono toggle en el header.

### Modal de producto
- Agregar selector de categoría (Select, con opción "Gestionar categorías" que abre un
  mini-CRUD de categorías — nombre + color de la paleta del kit).
- Resto del formulario (bien/servicio) se mantiene funcionalmente igual, solo re-skin
  con inputs/selects del Moodboard Kit.

---

## 4. Calculadora — Módulo de sidebar

**Componentes afectados:** `CalculadoraMaterial.tsx` (mover de `Productos/` a su propio módulo
o a `components/Calculadora/`), navegación principal (sidebar), routing en `App.tsx`.

### Cambios
- [ ] Revisar `CalculadoraMaterial.tsx` actual — hoy vive embebida en `ProductosList` como
  panel colapsable con callback `onAplicarCosto`.
- [ ] Crear módulo independiente `components/Calculadora/CalculadoraPage.tsx`:
  - Misma lógica de cálculo, pero como página completa con su propia ruta (`/calculadora`).
  - Entrada en sidebar principal (ícono Lucide `Calculator`), patrón "Navegación principal".
  - Layout: panel de inputs (izquierda) + resultado/desglose (derecha), cards del kit.
- [ ] Mantener la integración actual: desde Productos, botón "Usar Calculadora" puede
  seguir abriendo un modal con la misma lógica (reutilizar componente compartido) que al
  aplicar, llene `costo` en el formulario de producto — **no duplicar lógica de cálculo**,
  extraerla a un hook/función compartida (`useCalculadoraMaterial` o `calcularCostoMaterial()`
  en `utils/calculations.ts`).
- [ ] Rediseño visual: inputs con el patrón estándar, resultado destacado como "stat card"
  grande (precio sugerido en DM Mono, `text-[22px]`).

### Preguntas abiertas
- ¿Qué variables maneja hoy la calculadora? (revisar `CalculadoraMaterial.tsx` a fondo en
  la siguiente sesión para definir el layout de inputs — no se incluyó en este análisis).

---

## 5. Clientes + capas de personalización

**Componentes afectados:** `components/Clientes/*` (no explorado en detalle aún)

### Objetivo
Agregar "capas de personalización" — interpretación: permitir que cada organización configure
campos/etiquetas/categorías propias según su giro (similar a los *presets por industria* del
proyecto `modulos`: `veterinaria`, `retail`, `estudioCreativo`, etc.)

### Propuesta inicial (a refinar con feedback del prospecto)
- Tags/categorías de cliente personalizables (igual mecanismo que categorías de producto —
  reutilizar componente de gestión de categorías genérico).
- Campos personalizados simples (ej. "Origen del lead", "Industria del cliente") —
  evaluar si vale la pena un sistema de campos dinámicos o si 2-3 campos fijos opcionales
  son suficientes para el caso de uso real.
- Re-skin de la vista de Clientes con el patrón de tabla/cards del kit.

**Nota:** este punto es el más abierto — se recomienda detallarlo después de ver el módulo
`Clientes` actual y de tener feedback más específico del prospecto.

---

## 6. Onboarding (Login, Registro, Tour)

**Componentes afectados:** `components/Auth/*`

### 6.1 Login/Registro
- Rediseño visual con el patrón de modal/card del kit, fondo negro, logo de la empresa
  (usar `LogoIdeally.tsx` o el logo configurado en Ajustes).
- Formulario centrado, inputs estándar del kit, botón CTA violeta.

### 6.2 Configuración inicial post-registro
- Tras el primer registro, mostrar un wizard corto (modal `h-[92vh]` con steps via Tabs o
  stepper simple): nombre de organización, logo, datos fiscales básicos (lo mínimo para
  generar el primer PDF correctamente).
- Guarda en `Ajustes` (tabla ya existente).

### 6.3 Tour guiado
- Implementación ligera: librería de tour (ej. `react-joyride` o `driver.js`) con pasos
  fijos apuntando a Dashboard, Cotizador, Productos, Inventario.
- Se dispara solo si `Ajustes.tour_completado` (nuevo campo) es `false`/`null`.
- Botón "Reiniciar tour" en Ajustes/Perfil.

**Prioridad:** este bloque es el de menor urgencia para la demo del prospecto — se sugiere
dejarlo al final, después de validar Dashboard/Productos/Calculadora con el cliente.

---

## 7. Resumen de decisiones pendientes (revisar antes de pasar a Antigravity)

| # | Decisión | Bloquea |
|---|----------|---------|
| 1 | Definición de "pendiente de fabricar/entregar" | Dashboard sección B.1 |
| 2 | Umbral de días para "cotización perdida de vista" | Dashboard sección B.2 |
| 3 | Campo de fecha de entrega: ¿a nivel cotización o item? | Dashboard sección B.3, migración SQL |
| 4 | Categorías de producto: ¿tabla nueva en Supabase o config local? | Productos, migración SQL |
| 5 | Alcance real de "personalización" en Clientes | Módulo Clientes |
| 6 | Librería de tour guiado (react-joyride vs driver.js vs custom) | Onboarding |

---

## 8. Siguiente paso sugerido

Resolver decisiones **1-4** (las que bloquean Dashboard y Productos, que son prioridad 1 y 2)
y, si es posible, revisar con el prospecto antes de pasar este documento a Antigravity para
implementación. Una vez resueltas, se puede generar un spec más granular (componente por
componente) para el bloque 1 (Setup global) + bloque 2 (Dashboard) como primer entregable.
