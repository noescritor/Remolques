# Propuesta de Integración: Normas Oficiales Mexicanas y Cartas Factura en Sistema Remolques

- **Documento:** Propuesta de arquitectura, modelo de datos y flujo operativo para la emisión de documentación vehicular y cumplimiento normativo (SCT / SICT).
- **Elaborado por:** Antigravity (Pair Programming / Arquitectura)
- **Fecha:** 2 de noviembre de 2026 (Ronda 2 — Revisión y Anonimización Integral)
- **Contexto:** Análisis técnico de los 10 archivos `.docx` localizados en `Normas/`, correspondientes a tres unidades fabricadas: Volteo 9.20 m (Folio 044/27), Plataforma 40 ft (Folio 064/27) y Dolly (Folio 066/27).
- **Alcance:** Análisis técnico y propuesta formal de diseño (**sin código**), conforme a los requerimientos de la tarea T5. Todos los datos personales y de clientes han sido rigurosamente anonimizados conforme a la directiva de confidencialidad.

---

## 1. Mapeo de Datos Fijos y Variables por Tipo de Documento

A partir de la inspección técnica de los documentos originales en `Normas/`, se identificaron 4 tipos documentales emitidos por la armadora para amparar cada unidad:

1. **Carta Factura:** Documento de propiedad provisional y traslado vehicular (con vigencia habitual de 30 días naturales: **supuesto por confirmar / no especificado en los 10 archivos .docx**).
2. **Constancia de Pesos y Dimensiones (NOM-012):** Acredita cumplimiento ante SCT/SICT (con vigencia habitual de 60 días naturales: **supuesto por confirmar / no especificado en los 10 archivos .docx**).
3. **Constancia de Cumplimiento de Especificaciones de Seguridad y Métodos de Prueba (NOM-035):** Incluye expediente técnico gráfico de pruebas físico-mecánicas (46 imágenes únicas de componentes y calibración).
4. **Manifiesto de Condiciones Físico-Mecánicas (NOM-068):** Manifiesto solemne bajo protesta de decir verdad que exime de verificación físico-mecánica por 2 años según el DOF del 15 de mayo de 2015.

A continuación se detalla el mapeo entre los datos requeridos, un ejemplo anonimizado, su origen propuesto y si la columna **existe actualmente en el esquema de base de datos o debe crearse**:

| Campo | Tipo | Ejemplo anonimizado | Origen propuesto en el sistema | Estado en BD (Existe / Hay que crear) |
|---|---|---|---|---|
| **Razón Social Emisor** | Fijo | `ARMADORA LEOLCA S.A. DE C.V.` / `REMOLQUES LEOLCA SA DE CV` | Configuración de la organización (`organizaciones.nombre` o `organizaciones.razon_social`). | **Existe** `nombre`; `razon_social` **hay que crear** (o usar `nombre`). |
| **RFC Emisor** | Fijo | `RFC EMISOR XAXX010101000` | Configuración de la organización (`organizaciones.rfc`). | **Hay que crear** en `organizaciones` (actualmente solo tiene `id, nombre, created_at, modulos`). |
| **Domicilio Planta Emisor** | Fijo | `Domicilio de Planta / Ahuazotepec, Puebla` | Configuración de la organización (`organizaciones.direccion`). | **Hay que crear** en `organizaciones`. |
| **Teléfono y Correo Emisor** | Fijo | `Tel: 55-XXXX-XXXX`, `contacto@armadora.com` | Configuración de la organización (`organizaciones.contacto`). | **Hay que crear** en `organizaciones`. |
| **Representante Legal** | Fijo | `Representante Legal A` | Configuración / catálogo de apoderados legales de la empresa. | **Hay que crear** (en tabla de configuración de empresa). |
| **Folio Anual Consecutivo** | Variable | `044/27`, `064/27`, `066/27` | Secuenciador anual en base de datos (`lpad(consecutivo, 3, '0') \|\| '/' \|\| right(anio, 2)`). | **Hay que crear** (tabla o contador por organización y año). |
| **Fecha de Emisión** | Variable | `02 de septiembre de 2026`, `19 de octubre del 2026` | Capturada al generar/emitir el expediente de la unidad. | **Hay que crear** en tabla de expediente. |
| **Cliente — Nombre / Razón Social** | Variable | `CLIENTE A`, `CLIENTE B` | Módulo de Clientes (`clientes.nombre`). | **Existe** `clientes.nombre`. |
| **Cliente — Domicilio Fiscal** | Variable | `DOMICILIO FISCAL DEL CLIENTE, C.P. XXXXX` | Módulo de Clientes (`clientes.direccion`). | **Hay que crear** en `clientes`. |
| **Cliente — RFC** | Variable | `XAXX010101000`, `XEXX010101000` | Módulo de Clientes (`clientes.rfc`). | **Hay que crear** en `clientes`. |
| **Tipo de Unidad** | Variable | `VOLTEO`, `PLATAFORMA`, `DOLLY` | Orden de Trabajo / Presupuesto (`modelos.tipo`). | **Existe** `modelos.tipo`. |
| **Año Modelo Vehicular** | Variable | `2027` | Especificación de la unidad / OT (`unidades_fabricadas.anio_modelo`). | **Hay que crear** (`ordenes_trabajo` no tiene `anio_modelo`). |
| **NIV (Número de Identificación Vehicular)** | Variable | `3A9A...(17 caracteres, terminación 044, 064, 066)` | Asignado al troquelar la unidad fabricada (`unidades_fabricadas.niv`). | **Existe** `ordenes_trabajo.niv` (para OT individual); para multiequipo **hay que crear** `unidades_fabricadas.niv`. |
| **Deletreo Fonético del NIV** | Variable | `TRES-A-NUEVE-A...` | Función helper del sistema generada automáticamente a partir del NIV. | **Función en backend** (no requiere columna persistida). |
| **Longitud** | Variable | `9.20 m` (Volteo), `12.19 M` / `40 ft` (Plataforma), `3.5M` (Dolly) | Configuración del modelo (`modelos.largo_ft`). | **Existe** `modelos.largo_ft` (conversión a metros requerida). |
| **Ancho y Altura** | Variable | Ancho: `2.60 m`. Alto: `3.30 m` (Volteo), `2.77 m` (Plataforma), `1.30 m` (Dolly) | Configuración técnica de la receta o ficha del modelo. | **Hay que crear** en especificaciones de modelo. |
| **Número de Ejes** | Variable | `2` (o `3` en modelos de 3 ejes) | Configuración del modelo / OT (`modelos.num_ejes`). | **Existe** `modelos.num_ejes`. |
| **Tipo de Suspensión** | Variable | `Neumática` (o `Mecánica`) | Receta / selección de componentes en la Orden de Trabajo. | **Existe** en receta / opciones compatibles. |
| **Peso Tara (Unidad Vacía)** | Variable | `6,800 kg` (Volteo), `6,500 kg` (Plataforma), `2,500 kg` (Dolly NOM-035) | Báscula final registrada en taller o peso nominal calculado. | **Hay que crear** en expediente de unidad. |
| **P.B.V.D. (Peso Bruto Vehicular de Diseño)**| Variable | `34,000 kg` (Semirremolques y Dolly NOM-035) | Ficha técnica de homologación por tipo de unidad. | **Hay que crear** en especificaciones de modelo. |
| **Capacidad de Carga** | Variable | `30,000 Lb` | Ficha técnica de homologación. | **Hay que crear** en especificaciones de modelo. |
| **Llantas (Cantidad y Medida)** | Variable | `8` llantas (2 ejes), medida `11 R 24.5`, presión `830 kpa` | Configuración de rodado en la receta de ensamble. | **Existe** en opciones / receta base. |
| **Sistema y Modelo ABS** | Variable | `Bendix`, `2 sensores, 1 módulo` | Configuración de frenos en la receta de ensamble. | **Existe** en receta base. |
| **Desglose CDE (Ejes traseros)** | Variable | Suspensión `13,607.70 Kg`, Rines `14,152.01 Kg`, Llantas `11,996.55 Kg`, Ejes `17,000 Kg` | Parámetros de resistencia de componentes por proveedor. | **Hay que crear** en catálogo de componentes/ficha. |
| **Importes (Subtotal, IVA, Total)** | Variable | Subtotal `$ XXX,XXX.XX`, IVA `$ XX,XXX.XX`, Total `$ XXX,XXX.XX MXN` | Presupuesto comercial de venta asociado a la Orden de Trabajo. | **Existe** en `presupuestos.subtotal`, `presupuestos.iva`, `presupuestos.total`. |
| **Importe con Letra** | Variable | `(Monto en pesos 00/100 M.N.)` | Helper de conversión numérica a texto en backend. | **Función en backend**. |

> [!NOTE]
> **Regla de Autoridad de Datos y Sincronización del NIV (`unidades_fabricadas.niv` vs `ordenes_trabajo.niv`):**  
> Para evitar ambigüedades en la fuente canónica de verdad:  
> 1. `unidades_fabricadas.niv` es la **fuente de verdad única (Single Source of Truth)** del número de serie troquelado en la unidad física.  
> 2. `ordenes_trabajo.niv` actúa únicamente como campo de referencia operacional para la orden de taller. Solo se llena cuando la OT corresponde a un único equipo (`equipos_total = 1`) y su valor se actualiza exclusivamente desde el RPC de emisión del expediente (`unidades_fabricadas -> ordenes_trabajo`), **nunca a la inversa**.  
> 3. Cuando una sola OT ampara múltiples equipos (ej. 2 plataformas y 1 dolly), `ordenes_trabajo.niv` permanece en `NULL` (o refleja la unidad principal) y cada remolque individual posee su propio registro con su NIV único e inmutable en `unidades_fabricadas`.

---

## 2. Comparativa de Ubicación en el Sistema y Recomendación

### Alternativa A: Pestaña "Documentos / Normas" dentro de la Orden de Trabajo (`/ordenes-trabajo/:id?tab=normas`)
- **Cómo funcionaría:** Dentro del detalle de la OT, se agrega una pestaña "Expediente Vehicular y Normas". Al finalizar la manufactura, el usuario selecciona el equipo correspondiente, confirma el NIV y genera los documentos.
- **Ventajas:** Flujo centralizado en la vista operativa de manufactura; asociación directa con presupuesto y receta.
- **Desventajas:**
  - **Múltiples equipos por OT:** Agrupar 4 documentos oficiales por cada remolque dentro de una sola pestaña de OT satura la interfaz.
  - **Ciclo de vida post-OT:** Las Cartas Factura y Constancias tienen un período de validez para trámites (supuesto operativo por confirmar de 30 y 60 días, no estipulado en los .docx) y son solicitadas por clientes meses o años después para trámites de placas, extravíos o peritajes. Localizar una unidad por su NIV de 17 caracteres obligaría a escarbar entre OTs cerradas.

### Alternativa B: Módulo Dedicado "Expedientes de Unidad" (`/expedientes-unidad`) con Acceso Cruzado desde la OT
- **Cómo funcionaría:** Módulo dedicado donde cada registro representa un **remolque físico individual con su NIV, folio anual y paquete documental**. Desde la OT existe un botón directo *"Generar Expediente de Unidad"* por cada equipo, precargando automáticamente cliente, dimensiones, recetas e importes.
- **Ventajas:**
  - **Representación fiel del activo físico:** Un remolque es un bien individualizado con NIV de 17 caracteres que circula por décadas en carreteras nacionales.
  - **Búsqueda inmediata:** Búsqueda rápida por `NIV` (ej. terminación `...064`), por `Folio` (`064/27`), por `Cliente` o por `Año Modelo`.
  - **Trazabilidad a largo plazo:** Permite gestionar reexpediciones, registrar inspecciones a los 2 años (vencimiento de la exención de la NOM-068) y archivar fotos de salida de patio.
  - **Soporte limpio multiequipo:** Generación transparente de N expedientes para OTs con múltiples remolques.

### Recomendación Arquitectónica Definitiva
Se recomienda enfáticamente la **Alternativa B (Módulo Dedicado de Expedientes de Unidad con enlace bidireccional desde la OT)**. La Orden de Trabajo es un proceso transitorio de taller que concluye con la entrega física; el expediente normativo y vehicular es un instrumento legal permanente ante la SCT/SICT.

---

## 3. Modelo de Datos Propuesto (Ajustado con Lecciones de 2R-16)

A continuación se presenta el DDL relacional con aislamiento multi-inquilino estricto (`get_current_org_id()`), restricciones `CHECK` para estados, fechas con zona horaria de México y estrategia de concurrencia:

```sql
-- 1. Contador de Folios Consecutivos por Organización y Año (Evita colisiones de concurrencia)
CREATE TABLE IF NOT EXISTS public.folios_consecutivos_normas (
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    anio_folio INT NOT NULL, -- e.g. 2027 (año modelo)
    ultimo_consecutivo INT NOT NULL DEFAULT 0,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (organizacion_id, anio_folio)
);

ALTER TABLE public.folios_consecutivos_normas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "folios_normas_org_select" ON public.folios_consecutivos_normas
    FOR SELECT TO authenticated USING (organizacion_id = get_current_org_id());

-- 2. Tabla de Unidades Fabricadas (Expediente Vehicular)
CREATE TABLE IF NOT EXISTS public.unidades_fabricadas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    orden_trabajo_id UUID REFERENCES public.ordenes_trabajo(id) ON DELETE SET NULL,
    equipo_indice INT NOT NULL DEFAULT 1,
    presupuesto_id UUID REFERENCES public.presupuestos(id) ON DELETE SET NULL,
    cliente_id UUID NOT NULL REFERENCES public.clientes(id),
    
    -- Folio Anual Consecutivo (ej. 044/27)
    folio_consecutivo INT NOT NULL,
    folio_anio INT NOT NULL, -- Año modelo base del folio (ej. 2027)
    folio_formateado TEXT GENERATED ALWAYS AS (
        lpad(folio_consecutivo::text, 3, '0') || '/' || right(folio_anio::text, 2)
    ) STORED,
    
    -- Identificación Vehicular Única
    niv VARCHAR(17) NOT NULL,
    niv_deletreo TEXT NOT NULL,
    
    -- Especificaciones de la Unidad (Heredadas de receta, presupuesto o modelo; sin DEFAULTs rígidos)
    tipo_unidad TEXT NOT NULL, -- 'PLATAFORMA', 'VOLTEO', 'DOLLY', etc.
    marca TEXT NOT NULL,
    anio_modelo INT NOT NULL,
    numero_ejes INT NOT NULL,
    tipo_suspension TEXT NOT NULL, -- 'Neumática', 'Mecánica', etc.
    
    -- Dimensiones
    longitud_valor NUMERIC(6, 2) NOT NULL,
    longitud_unidad VARCHAR(4) NOT NULL DEFAULT 'm',
    ancho_m NUMERIC(4, 2) NOT NULL, -- e.g. 2.60 según ficha técnica
    alto_m NUMERIC(4, 2) NOT NULL,
    
    -- Pesos y Capacidades
    peso_tara_kg NUMERIC(8, 2) NOT NULL,
    pbvd_kg NUMERIC(8, 2) NOT NULL,
    capacidad_carga_lb NUMERIC(8, 2),
    
    -- Componentes de Seguridad y Rodado (heredados dinámicamente de receta, sin DEFAULT hardcodeado)
    numero_llantas INT NOT NULL,
    medida_llantas VARCHAR(20) NOT NULL,
    presion_inflado_kpa NUMERIC(6, 2) NOT NULL,
    sistema_abs_marca VARCHAR(50) NOT NULL,
    sistema_abs_modelo VARCHAR(50) NOT NULL,
    
    -- Desglose CDE (Ejes traseros)
    cde_ejes_traseros_kg NUMERIC(8, 2),
    cde_suspension_kg NUMERIC(8, 2),
    cde_rines_kg NUMERIC(8, 2),
    cde_llantas_kg NUMERIC(8, 2),
    cde_eje_montaje_kg NUMERIC(8, 2),
    cde_espigas_kg NUMERIC(8, 2),
    
    -- Importes Comerciales (Carta Factura)
    subtotal NUMERIC(12, 2) NOT NULL,
    iva NUMERIC(12, 2) NOT NULL,
    total NUMERIC(12, 2) NOT NULL,
    moneda VARCHAR(3) NOT NULL DEFAULT 'MXN',
    importe_con_letra TEXT NOT NULL,
    
    -- Fechas y Control (Zona Horaria México evaluada con now() at time zone)
    fecha_fabricacion VARCHAR(30) NOT NULL, -- ej. 'OCTUBRE 2026'
    fecha_emision DATE NOT NULL DEFAULT ((now() AT TIME ZONE 'America/Mexico_City')::date),
    estado_expediente VARCHAR(20) NOT NULL DEFAULT 'borrador',
    
    creado_por UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    
    CONSTRAINT uq_unidad_niv UNIQUE (organizacion_id, niv),
    CONSTRAINT uq_unidad_folio UNIQUE (organizacion_id, folio_anio, folio_consecutivo),
    CONSTRAINT chk_estado_expediente CHECK (estado_expediente IN ('borrador', 'en_revision', 'aprobado', 'emitido', 'anulado')),
    CONSTRAINT chk_niv_longitud CHECK (length(niv) = 17)
);

CREATE INDEX IF NOT EXISTS idx_unidades_org_niv ON public.unidades_fabricadas (organizacion_id, niv);
CREATE INDEX IF NOT EXISTS idx_unidades_ot ON public.unidades_fabricadas (orden_trabajo_id);

ALTER TABLE public.unidades_fabricadas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "unidades_org_select" ON public.unidades_fabricadas
    FOR SELECT TO authenticated USING (organizacion_id = get_current_org_id());

-- 3. Tabla de Documentos Normativos por Unidad
CREATE TABLE IF NOT EXISTS public.documentos_unidad_normas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organizacion_id UUID NOT NULL REFERENCES public.organizaciones(id) ON DELETE CASCADE,
    unidad_id UUID NOT NULL REFERENCES public.unidades_fabricadas(id) ON DELETE CASCADE,
    tipo_documento VARCHAR(30) NOT NULL,
    norma_version VARCHAR(50) NOT NULL,
    version_int INT NOT NULL DEFAULT 1,
    
    -- Snapshot inmutable de las variables utilizadas para emitir
    datos_snapshot JSONB NOT NULL,
    
    -- Archivos generados
    archivo_docx_path TEXT,
    archivo_pdf_path TEXT,
    
    -- Estado de Aprobación Humana Obligatoria
    estado VARCHAR(20) NOT NULL DEFAULT 'borrador',
    revisado_por UUID REFERENCES auth.users(id),
    fecha_revision TIMESTAMPTZ,
    notas_revision TEXT,
    
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CONSTRAINT uq_doc_unidad_tipo UNIQUE (unidad_id, tipo_documento, version_int),
    CONSTRAINT chk_tipo_documento CHECK (tipo_documento IN ('carta_factura', 'nom_012', 'nom_035', 'nom_068')),
    CONSTRAINT chk_doc_estado CHECK (estado IN ('borrador', 'revisado', 'emitido', 'anulado'))
);

-- Regla de Integridad de Inquilino: El RPC de emisión o un trigger de validación verificará
-- que documentos_unidad_normas.organizacion_id coincida exactamente con unidades_fabricadas.organizacion_id.

CREATE INDEX IF NOT EXISTS idx_documentos_unidad ON public.documentos_unidad_normas (unidad_id);

ALTER TABLE public.documentos_unidad_normas ENABLE ROW LEVEL SECURITY;
CREATE POLICY "doc_normas_org_select" ON public.documentos_unidad_normas
    FOR SELECT TO authenticated USING (organizacion_id = get_current_org_id());
```

> [!TIP]
> **Estrategia de Concurrencia de Folios (Primer Folio del Año y Siguientes):**  
> Para evitar colisiones de clave primaria cuando el año modelo no existe previamente en `folios_consecutivos_normas` (donde un simple `SELECT ... FOR UPDATE` no bloquearía filas al no encontrar registros), la asignación atómica del folio se realizará mediante un `INSERT ... ON CONFLICT DO UPDATE`:
> ```sql
> INSERT INTO public.folios_consecutivos_normas (organizacion_id, anio_folio, ultimo_consecutivo)
> VALUES (p_org_id, p_anio, 1)
> ON CONFLICT (organizacion_id, anio_folio)
> DO UPDATE SET ultimo_consecutivo = folios_consecutivos_normas.ultimo_consecutivo + 1,
>               updated_at = now()
> RETURNING ultimo_consecutivo;
> ```
> Esta instrucción dentro del RPC transaccional garantiza exclusión mutua, maneja con elegancia la inicialización del primer folio de un nuevo año modelo y previene cualquier hueco o condición de carrera entre usuarios concurrentes.

---

## 4. Flujo de Generación y Revisión Humana Obligatoria

> [!CAUTION]
> **Principio Legal Inquebrantable:** Los documentos de la NOM-035 y NOM-068 contienen declaraciones solemnes: *"MANIFIESTO BAJO PROTESTA DE DECIR VERDAD QUE EL SEMIRREMOLQUE... CUMPLE CON LAS CONDICIONES FÍSICO-MECÁNICAS Y DE SEGURIDAD"*. Su emisión no puede ser completamente desatendida.

```
[ Orden de Trabajo Completa ]
              │
              ▼
1. "Generar Expediente" (Extracción de OT, Modelo y Presupuesto)
              │
              ▼
2. Asignación Atómica del Folio (NNN/YY) y Validación del NIV (17 caracteres)
              │
              ▼
3. Generación de BORRADORES (.docx con plantilla + marcas de agua "BORRADOR")
              │
              ▼
4. BANDEJA DE REVISIÓN TÉCNICA (Cotejo de NIV físico, báscula y datos fiscales)
   ├── Rechazo / Corrección ──> Modificar datos en formulario y regenerar borrador
   └── Aprobación Humana Conforme (ID del revisor + timestamp + observaciones)
              │
              ▼
5. Emisión Definitiva (Retiro de marca de agua, generación de PDF oficial y bloqueo inmutable)
              │
              ▼
6. Descarga e Impresión para Firma Autógrafa del Representante Legal
```

---

## 5. Inconsistencias Críticas Identificadas entre los Documentos Analizados

Durante el examen detallado de los 10 archivos `.docx` originales en `Normas/`, se identificaron las siguientes inconsistencias y anomalías reales:

### 5.1. Discrepancias en Años y Versiones de las Normas Oficiales
- **NOM-012 (Pesos y Dimensiones):**
  - En la unidad Folio 044 se cita formalmente: **`NOM-012-SCT-2-2017`**.
  - En la unidad Folio 064 se cita: **`NOM-012-SCT-2-2014`** (versión superada por la de 2017).
- **NOM-035 (Seguridad y Métodos de Prueba):**
  - En la unidad Folio 044 se cita: **`NOM-035-SCT2-2022`** (versión vigente publicada en el DOF).
  - En las unidades Folio 064 y Folio 066 (Dolly) se cita: **`NOM-035-SCT2-2010`** (versión de hace más de una década).
- **NOM-068:** En ambos expedientes se cita **`NOM-068-SCT-2-2014`**.

### 5.2. Inconsistencia en la Razón Social del Emisor y Marca
- En el cuerpo de la NOM-012 se cita: *"REMOLQUES LEOLCA S.A. DE C.V."*.
- En el bloque de firma y responsivas se cita: *"ARMADORA LEOLCA S.A. DE C.V."*.
- En el campo de marca del vehículo se cita: *"REMOLQUES LEOLCA SA DE CV"*.  
En un documento legal con fe de juramento debe existir uniformidad estricta entre la denominación de la armadora y su razón social fiscal.

### 5.3. Desalineación entre Nombres de Archivo y Contenido Real
- El archivo `NOM 012-40FT 3 EJES.docx` **no describe una plataforma de 40 ft ni 3 ejes**: describe un **Volteo de 9.20 m con 2 ejes** (Folio `044/27`).
- El archivo `NOM 035 40FT 3 EJES.docx` (Folio `044/27`) dice en el cuerpo del texto: `Tipo: PLATAFORMA.`, pero anota dimensiones de `Longitud: 9.20 M.` y `Alto: 3.30 M.` (medidas de un volteo, no de una plataforma).
- El archivo `NOM 068-40FT 3 EJES.docx` describe un **Volteo** de 9.20 m.
- Typos en nombres de archivo: `NOM 068-4OFT...docx` tiene una letra **`O`** mayúscula en vez de cero (`4OFT`); y `NOM 035 D0LLY...docx` tiene un cero **`0`** en lugar de `O` (`D0LLY`) y doble espacio.

### 5.4. Erratas Ortográficas y Defectos de Redacción Jurídica
- **Typo en tipo de unidad:** En la NOM-012 del Folio 044 se escribió textualmente: *"SEMIRREMOLQUE TIPO VOLETO DE 9.20 (M)"* (en lugar de *"VOLTEO"*).
- **Error grave en declaración solemne:** En la NOM-035 de los Folios 064 y 066 la declaración solemne dice textualmente:
  > *"Bajo propuesta de decir verdad..."* (en lugar de la fórmula jurídica obligatoria *"Bajo protesta de decir verdad"*). En el Folio 044 sí se utilizó *"protesta"*.
- **Paréntesis incompleto en deletreo del NIV:** En la NOM-068 del Folio 064, el deletreo fonético del NIV abre con paréntesis pero no lo cierra:
  > `(TRES-A-NUEVE-A-N...CERO-SEIS-CUATRO.` (falta `)`).

### 5.5. Criterio de Folio Anual (`NNN/YY`) respecto al Año
- Los folios observados son `044/27`, `064/27` y `066/27`.
- El sufijo `/YY` corresponde formalmente al **año modelo vehicular** (confirmado por Luis en `PREGUNTAS_LUIS.md`: `/27` para año modelo 2027). Esto confirma que el secuenciador consecutivo anual debe regirse por el año modelo asignado al remolque, no por el año de emisión.

### 5.6. Especificaciones Técnicas del Dolly y Denominación Errónea
- En la NOM-035 del Dolly (Folio 066/27), se registra un **peso vehicular de 2,500 kg** (escrito como `2.500 Kg`) y un **PBVD de 34,000 kg** (escrito como `34.000 Kg`), asignándole un PBVD idéntico al de un semirremolque de carga completa.
- **Aclaración documental estricta:** Ninguna de las 3 Cartas Factura analizadas contiene campos ni datos de peso vehicular o PBVD (cero menciones en los archivos originales). Estos pesajes provienen exclusivamente de la NOM-035 del Dolly.
- En cuanto a la denominación del equipo: la Carta Factura dice textualmente *"Un semi- remolque nuevo tipo: DOLLY"*, mientras que la NOM-035 dice *"SEMIRREMOLQUE TIPO: DOLLY"*. Legalmente bajo la NOM-012 un dolly es un convertidor de acoplamiento (`convertidor`), no un semirremolque.

### 5.7. Incongruencias en la Sumatoria del Desglose CDE (Ejes Traseros)
- En los 3 expedientes se reporta exactamente el mismo desglose de componentes de resistencia:
  - Suspensión: `13,607.70 Kg`
  - Rines: `14,152.01 Kg`
  - Llantas: `11,996.55 Kg`
  - Ejes: `17,000.00 Kg`
- Sin embargo, la sumatoria total de CDE reportada difiere arbitrariamente en cada documento:
  - Folio 044 reporta total CDE: `22,353 kg`.
  - Folio 064 reporta total CDE: `13,607.70 kg` (tomó solo el valor de la suspensión como total).
  - Folio 066 (Dolly) reporta total CDE: `20,000 kg`.

### 5.8. Mezcla de Separadores de Miles y Decimales
- En unos documentos se emplea coma para miles y punto para decimal (`6,800 kg`, `34,000 kg`), mientras que en otros se emplea punto como separador de miles (`6.800 Kg`, `34.000 kg`, `2.500 kg`), generando ambigüedad en la lectura de pesajes.

### 5.9. Autoridad Oficial Citada (SCT vs SICT)
- De los 10 archivos `.docx` analizados, exactamente **5 citan textualmente a la *"Secretaría de Comunicaciones y Transportes (SCT)"*** (las 3 Cartas Factura y las 2 constancias NOM-012). En las constancias NOM-035 y NOM-068 no aparece ninguna mención a la SCT. Tras las reformas del marco federal de la Administración Pública, la denominación oficial vigente es *"Secretaría de Infraestructura, Comunicaciones y Transportes (SICT)"*.

### 5.10. Correlación Folio-NIV (Hipótesis Operativa)
- Los NIVs de las 3 unidades observadas terminan en los mismos dígitos del folio:
  - Folio `044/27` → NIV con terminación `...044`.
  - Folio `064/27` → NIV con terminación `...064`.
  - Folio `066/27` → NIV con terminación `...066`.
- Se plantea como hipótesis que el proceso de troquelado de Leolca utiliza el mismo consecutivo del folio como sufijo del número de serie. Esto se incluye como pregunta prioritaria de validación para Luis.
- En la NOM-068 no aparece el folio en el texto ni encabezado en ninguno de los documentos revisados.

### 5.11. Búsqueda de Números Sueltos Previos al NIV
- Se realizó una búsqueda minuciosa en los nodos XML (`w:t`, `w:p`) de los 10 archivos Word para investigar si existían códigos o números sueltos previos al NIV.
- **Resultado de la búsqueda:** No se encontró ningún número de serie secundario o código huérfano. Únicamente se detectaron puntos suspensivos (`....`) inmediatamente posteriores al NIV en la NOM-035 del Folio 044, y el texto del NIV renderizado antes de su propia etiqueta descriptiva debido a la disposición interna de cajas de texto flotantes de Word (`w:txbxContent`).

### 5.12. Expediente Fotográfico de NOM-035 (46 Imágenes Únicas)
- Cada documento de la NOM-035 extrae 93 entradas de archivo en la carpeta `word/media`.
- Mediante verificación de firmas SHA-1, se constató que corresponden exactamente a **46 imágenes únicas** (duplicadas en el zip debido a los bloques flotantes de Word).
- Dichas 46 imágenes son **completamente idénticas entre las tres unidades**, lo que demuestra empíricamente que no corresponden a fotografías de cada remolque individual, sino al expediente técnico estandarizado de homologación de defensas, anclajes, torquímetros y componentes ABS de la armadora.

### 5.13. Documentación Incompleta en el Dolly (Folio 066/27)
- Para las dos primeras unidades existen los 4 documentos completos.
- Para el Dolly únicamente obran 2 archivos: Carta Factura y NOM-035 (carece de NOM-012 y de NOM-068).

---

## 6. Preguntas de Clarificación para Luis

1. **Generación y Asignación del NIV:**
   - ¿El NIV lo genera y troquela directamente Leolca calculando el dígito verificador oficial de 17 caracteres (WMI `3A9` + modelo + dígito verificador + año `V` + planta `M` + consecutivo), o se recibe asignado en lotes por la Secretaría de Economía / SICT? ¿Se confirma que el sufijo del NIV siempre coincide con el número consecutivo del folio anual?
2. **Expediente Fotográfico NOM-035:**
   - Dado que las 46 imágenes de prueba son idénticas en todas las unidades, ¿el sistema debe mantener un expediente estandarizado precargado para las constancias NOM-035, o el personal de taller debe tomar y adjuntar fotografías específicas de cada remolque al salir de patio?
3. **Documentación Oficial para Dolly:**
   - Para remolques auxiliares de enganche (Dolly), ¿se deben emitir únicamente la Carta Factura y la NOM-035 (como en el expediente observado), o también se requiere generar NOM-012 y NOM-068? ¿Qué PBVD y clasificación vehicular deben estandarizarse para este equipo?
4. **Versiones Vigentes de Normas Oficiales:**
   - ¿Confirmamos que todas las constancias generadas por el nuevo sistema deben citar las versiones vigentes (**`NOM-012-SCT-2-2017`** y **`NOM-035-SCT2-2022`**), corrigiendo las menciones obsoletas a 2014 y 2010?
5. **Vigencias Oficiales y Criterio de Reexpedición:**
   - En los 10 archivos `.docx` no se estipula ninguna vigencia temporal expresa. En el sector autotransporte es común manejar supuestos operativos de 30 días naturales para la Carta Factura de traslado y 60 días para la constancia de pesos y dimensiones NOM-012. ¿Qué vigencia formal otorga Leolca a cada documento? En caso de vencimiento o extravío por parte del cliente, ¿se reimprime conservando el folio original o debe emitirse con un folio consecutivo nuevo?
