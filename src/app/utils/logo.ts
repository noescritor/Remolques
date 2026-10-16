/**
 * Utilidades puras para el manejo y validación de logos de la empresa (Sub-bloque 2R-9)
 * Sin dependencias de React ni de canvas del navegador para ejecución portable.
 */

export interface ArchivoValidable {
  name: string;
  size: number;
  type?: string;
}

export const TAMANO_MAX_ARCHIVO_BYTES = 2 * 1024 * 1024; // 2 MB
export const ANCHO_MAX_NORMALIZADO = 1200; // px
export const ANCHO_REDUCIDO_NORMALIZADO = 800; // px
export const TAMANO_MAX_PNG_BYTES = 400 * 1024; // 400 KB

const EXTENSIONES_PERMITIDAS = ['.svg', '.png', '.jpg', '.jpeg', '.webp'];
const MIMES_PERMITIDOS = [
  'image/svg+xml',
  'image/png',
  'image/jpeg',
  'image/pjpeg',
  'image/webp'
];

/**
 * Valida el tipo y tamaño del archivo original antes de procesarlo.
 */
export function validarArchivoLogo(file: ArchivoValidable): { valido: boolean; error?: string } {
  if (!file) {
    return { valido: false, error: 'No se proporcionó ningún archivo.' };
  }

  if (file.size <= 0) {
    return { valido: false, error: 'El archivo está vacío.' };
  }

  if (file.size > TAMANO_MAX_ARCHIVO_BYTES) {
    return { valido: false, error: 'El archivo excede el tamaño máximo permitido de 2 MB.' };
  }

  const name = (file.name || '').toLowerCase();
  const ext = name.slice(name.lastIndexOf('.'));
  const type = (file.type || '').toLowerCase();

  const extValida = EXTENSIONES_PERMITIDAS.includes(ext);
  const mimeValido = type === '' || MIMES_PERMITIDOS.includes(type);

  if (!extValida && !mimeValido) {
    return { valido: false, error: 'Formato no compatible. Usa SVG, PNG, JPG o WebP.' };
  }

  return { valido: true };
}

/**
 * Valida la seguridad de un contenido SVG antes de rasterizarlo.
 * Descarta etiquetas script, foreignObject, atributos on* y referencias externas.
 */
export function sanearSvg(svgString: string): { valido: boolean; error?: string } {
  if (!svgString || typeof svgString !== 'string') {
    return { valido: false, error: 'El contenido SVG está vacío o no es válido.' };
  }

  // Comprobar que contenga estructura mínima <svg y </svg>
  if (!/<svg[\s>]/i.test(svgString) || !/<\/svg>/i.test(svgString)) {
    return { valido: false, error: 'El archivo no tiene una estructura SVG válida.' };
  }

  // 1. Prohibir <script>
  if (/<script[\s>]/i.test(svgString)) {
    return { valido: false, error: 'El SVG contiene elementos <script> no permitidos por seguridad.' };
  }

  // 2. Prohibir <foreignObject>
  if (/<foreignObject[\s>]/i.test(svgString)) {
    return { valido: false, error: 'El SVG contiene elementos <foreignObject> no permitidos por seguridad.' };
  }

  // 3. Prohibir controladores de eventos inline (onload=, onerror=, onclick=, etc.)
  if (/\bon[a-z]+\s*=/i.test(svgString)) {
    return { valido: false, error: 'El SVG contiene atributos de eventos (on*) no permitidos por seguridad.' };
  }

  // 4. Prohibir referencias externas en href o xlink:href (excepto anclas internas #...)
  // Rechaza href="http://...", href="//...", href="javascript:...", href="data:..."
  const hrefRegex = /(?:xlink:)?href\s*=\s*["']\s*(?!#)([^"']+)["']/gi;
  let match: RegExpExecArray | null;
  while ((match = hrefRegex.exec(svgString)) !== null) {
    const target = match[1].trim();
    if (target !== '' && !target.startsWith('#')) {
      return { valido: false, error: 'El SVG contiene referencias externas no permitidas por seguridad.' };
    }
  }

  return { valido: true };
}

/**
 * Calcula dimensiones de salida respetando proporción y tope máximo de ancho sin agrandar.
 */
export function calcularDimensionesLogo(
  origWidth: number,
  origHeight: number,
  maxAncho: number = ANCHO_MAX_NORMALIZADO
): { width: number; height: number } {
  if (origWidth <= 0 || origHeight <= 0 || !Number.isFinite(origWidth) || !Number.isFinite(origHeight)) {
    return { width: maxAncho, height: Math.round(maxAncho / 4) };
  }

  if (origWidth <= maxAncho) {
    return {
      width: Math.round(origWidth),
      height: Math.round(origHeight)
    };
  }

  const factor = maxAncho / origWidth;
  return {
    width: maxAncho,
    height: Math.round(origHeight * factor)
  };
}

/**
 * Calcula el tamaño en bytes de un data URL base64.
 */
export function calcularTamanoDataUrl(dataUrl: string): number {
  if (!dataUrl || typeof dataUrl !== 'string') return 0;
  const commaIdx = dataUrl.indexOf(',');
  if (commaIdx === -1) return 0;
  const b64 = dataUrl.slice(commaIdx + 1);
  return Math.round((b64.length * 3) / 4);
}

export interface DecisionLogo {
  url?: string;
  usarContenedorNegro: boolean;
  mostrarNombre: boolean;
}

/**
 * Decide qué logo usar según el fondo del encabezado (oscuro o claro),
 * si requiere contenedor oscuro y si se debe mostrar el nombre de la empresa.
 */
export function decidirLogoEncabezado(
  ajustes: {
    logo?: string;
    logo_claro?: string;
    logo_mostrar_nombre?: boolean;
    nombre_empresa?: string;
  } | null | undefined,
  fondo: 'oscuro' | 'claro'
): DecisionLogo {
  const logoOscuro = ajustes?.logo && ajustes.logo.trim() !== '' ? ajustes.logo : undefined;
  const logoClaro = ajustes?.logo_claro && ajustes.logo_claro.trim() !== '' ? ajustes.logo_claro : undefined;

  if (fondo === 'oscuro') {
    const url = logoOscuro || logoClaro;
    return {
      url,
      usarContenedorNegro: false,
      mostrarNombre: url ? Boolean(ajustes?.logo_mostrar_nombre) : true
    };
  }

  // Fondo claro
  if (logoClaro) {
    return {
      url: logoClaro,
      usarContenedorNegro: false,
      mostrarNombre: Boolean(ajustes?.logo_mostrar_nombre)
    };
  }

  if (logoOscuro) {
    // Si solo hay logo para fondo oscuro (ej. logo blanco), se coloca dentro de un contenedor negro redondeado
    return {
      url: logoOscuro,
      usarContenedorNegro: true,
      mostrarNombre: Boolean(ajustes?.logo_mostrar_nombre)
    };
  }

  return {
    url: undefined,
    usarContenedorNegro: false,
    mostrarNombre: true
  };
}
