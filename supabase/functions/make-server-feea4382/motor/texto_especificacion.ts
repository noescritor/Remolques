import { Modelo, Configuracion, GrupoOpcion, Opcion } from './tipos.ts';
import { fusionarFilasConfig } from './reglas_compatibilidad.ts';

const ORDEN_TEXTO = [
  'suspension',
  'eje',
  'patin',
  'retractil',
  'gancho',
  'abs',
  'plafones',
  'frente',
  'redilas',
  'piso',
  'matracas',
  'pintura',
  'rines',
  'llantas'
];

const ORDEN_RESUMEN = [
  'Estructura (modelo)',
  'Ejes',
  'Suspensión',
  'Patines',
  'Frenos (ABS)',
  'Instalación eléctrica',
  'Frente',
  'Redilas',
  'Piso',
  'Matracas / winches',
  'Pintura',
  'Rines',
  'Llantas'
];

interface PlantillaGrupo {
  etiqueta: string;
  plantilla: (o: Opcion, v: any, m: Modelo) => string;
}

const limpiarNombre = (nombre: string, grupoNombre?: string) => {
  let limpio = nombre.replace(/\s*\(.*?\)\s*/g, '').trim().toUpperCase();
  if (grupoNombre) {
    const prefijo = grupoNombre.toUpperCase().trim();
    if (limpio.startsWith(prefijo)) {
      limpio = limpio.substring(prefijo.length).trim();
    }
  }
  return limpio;
};

function unirConY(frases: string[]): string {
  if (frases.length === 0) return '';
  if (frases.length === 1) return frases[0];
  if (frases.length === 2) return `${frases[0]} Y ${frases[1]}`;
  const ult = frases[frases.length - 1];
  const anteriores = frases.slice(0, -1).join(', ');
  return `${anteriores} Y ${ult}`;
}

const TABLA_PLANTILLAS: Record<string, PlantillaGrupo> = {
  'eje': {
    etiqueta: 'Ejes',
    plantilla: (o) => `EJES ${limpiarNombre(o.nombre)}`
  },
  'suspension': {
    etiqueta: 'Suspensión',
    plantilla: (o) => `CON SUSPENSIÓN ${limpiarNombre(o.nombre)}`
  },
  'patin': {
    etiqueta: 'Patines',
    plantilla: (o) => `2 PAR DE PATÍN ${limpiarNombre(o.nombre)}`
  },
  'retractil': {
    etiqueta: 'Retráctil',
    plantilla: (o) => `SISTEMA RETRÁCTIL ${limpiarNombre(o.nombre, 'Retráctil')}`
  },
  'gancho': {
    etiqueta: 'Gancho',
    plantilla: (o) => `GANCHO DE ARRASTRE ${limpiarNombre(o.nombre, 'Gancho de arrastre')}`
  },
  'abs': {
    etiqueta: 'Frenos (ABS)',
    plantilla: (o) => `FRENOS ${limpiarNombre(o.nombre)}`
  },
  'plafones': {
    etiqueta: 'Instalación eléctrica',
    plantilla: (o) => `INSTALACIÓN ELÉCTRICA ${limpiarNombre(o.nombre)}`
  },
  'frente': {
    etiqueta: 'Frente',
    plantilla: (o) => `FRENTE ${limpiarNombre(o.nombre)}`
  },
  'redilas': {
    etiqueta: 'Redilas',
    plantilla: (o) => `REDILAS ${limpiarNombre(o.nombre, 'Redilas')}`
  },
  'piso': {
    etiqueta: 'Piso',
    plantilla: (o) => `PISO ${limpiarNombre(o.nombre)}`
  },
  'matracas': {
    etiqueta: 'Matracas / winches',
    plantilla: (o, v) => {
      const qty = typeof v === 'object' && v?.cantidad ? v.cantidad : 12;
      const desc = o.clave === 'corrediza' ? 'CORREDIZAS' : o.clave === 'soldable' ? 'SOLDABLES' : limpiarNombre(o.nombre, 'Matraca');
      return `${qty} MATRACAS ${desc}`;
    }
  },
  'pintura': {
    etiqueta: 'Pintura',
    plantilla: (o) => `PINTURA ${limpiarNombre(o.nombre)}`
  },
  'rines': {
    etiqueta: 'Rines',
    plantilla: (o, v, m) => {
      const qty = typeof v === 'object' && v?.cantidad ? v.cantidad : (m.num_ejes * 4);
      const marca = v?.marca ? ` MARCA ${v.marca.toUpperCase()}` : '';
      if (o.clave === 'cliente') {
        return `${qty} RINES PROPORCIONADOS POR EL CLIENTE`;
      }
      return `${qty} RINES DE ${limpiarNombre(o.nombre, 'Rines de')}${marca}`;
    }
  },
  'llantas': {
    etiqueta: 'Llantas',
    plantilla: (o, v, m) => {
      const qty = typeof v === 'object' && v?.cantidad ? v.cantidad : (m.num_ejes * 4);
      return `${qty} LLANTAS ${limpiarNombre(o.nombre)}`;
    }
  }
};

export function generarEspecificacion(
  modelo: Modelo,
  configuracion: Configuracion,
  grupos: GrupoOpcion[],
  opciones: Opcion[]
) {
  const resumen_lineas: { etiqueta: string; valor: string }[] = [];
  const frases: string[] = [];

  let modeloTexto: string;
  if (modelo.tipo === 'plataforma') {
    modeloTexto = `PLATAFORMA ${modelo.largo_ft} FT ${modelo.num_ejes} EJES`;
  } else if (modelo.tipo === 'dolly') {
    modeloTexto = `DOLLY ${modelo.num_ejes} EJES`;
  } else if (modelo.tipo === 'gondola') {
    modeloTexto = `GONDOLA ${modelo.num_ejes} EJES`;
  } else {
    modeloTexto = (modelo.tipo || '').toUpperCase();
  }
  frases.push(`SEMIREMOLQUE TIPO: ${modeloTexto}`);
  resumen_lineas.push({ etiqueta: 'Estructura (modelo)', valor: modeloTexto });

  const confGrupos = configuracion?.grupos || {};
  const procesados = new Set<string>();

  const procesarGrupo = (claveGrupo: string) => {
    if (procesados.has(claveGrupo)) return;
    procesados.add(claveGrupo);

    const configValue = confGrupos[claveGrupo];
    if (!configValue) return;
    
    // Arrays para grupos múltiples
    const rawValues = Array.isArray(configValue) ? configValue : [configValue];
    const values = fusionarFilasConfig(rawValues);

    const frasesGrupo: string[] = [];
    const resumenGrupo: string[] = [];
    let etiquetaGrupo = '';

    for (const val of values) {
      const opcionClave = typeof val === 'string' ? val : val.opcion;
      if (!opcionClave || opcionClave.startsWith('sin_')) continue;

      const grupo = grupos.find(g => g.clave === claveGrupo);
      const opcion = opciones.find(o => o.grupo_id === grupo?.id && o.clave === opcionClave);

      if (grupo && opcion) {
        etiquetaGrupo = grupo.nombre;
        const plantillaDef = TABLA_PLANTILLAS[claveGrupo];
        let frase = '';
        let valorResumen = limpiarNombre(opcion.nombre);

        if (plantillaDef) {
          frase = plantillaDef.plantilla(opcion, val, modelo);
          etiquetaGrupo = plantillaDef.etiqueta;
          
          if (claveGrupo === 'rines') {
            const qty = typeof val === 'object' && val.cantidad ? val.cantidad : (modelo.num_ejes * 4);
            const marca = typeof val === 'object' && val.marca ? ` ${val.marca.toUpperCase()}` : '';
            const baseObj = opcion.clave === 'cliente' ? 'PROPORCIONADOS POR CLIENTE' : limpiarNombre(opcion.nombre, 'Rines de');
            valorResumen = `${qty} ${baseObj}${marca}`.trim();
          } else if (claveGrupo === 'llantas') {
            const qty = typeof val === 'object' && val.cantidad ? val.cantidad : (modelo.num_ejes * 4);
            valorResumen = `${qty} ${limpiarNombre(opcion.nombre)}`.trim();
          } else if (claveGrupo === 'matracas') {
            const qty = typeof val === 'object' && val.cantidad ? val.cantidad : 12;
            const plural = qty > 1;
            const baseObj = opcion.clave === 'corrediza' 
              ? (plural ? 'CORREDIZAS' : 'CORREDIZA') 
              : opcion.clave === 'soldable' 
              ? (plural ? 'SOLDABLES' : 'SOLDABLE') 
              : limpiarNombre(opcion.nombre, 'Matraca');
            valorResumen = `${qty} ${baseObj}`.trim();
          }
        } else {
          frase = `${grupo.nombre.toUpperCase()} ${limpiarNombre(opcion.nombre, grupo.nombre)}`;
        }

        frasesGrupo.push(frase);
        resumenGrupo.push(valorResumen);
      }
    }

    if (frasesGrupo.length > 0) {
      frases.push(unirConY(frasesGrupo));
      resumen_lineas.push({ etiqueta: etiquetaGrupo, valor: resumenGrupo.join(', ') });
    }
  };

  for (const clave of ORDEN_TEXTO) {
    procesarGrupo(clave);
  }
  for (const clave of Object.keys(confGrupos)) {
    procesarGrupo(clave);
  }

  // Ordenar el resumen
  resumen_lineas.sort((a, b) => {
    let idxA = ORDEN_RESUMEN.indexOf(a.etiqueta);
    let idxB = ORDEN_RESUMEN.indexOf(b.etiqueta);
    if (idxA === -1) idxA = 999;
    if (idxB === -1) idxB = 999;
    return idxA - idxB;
  });

  return { texto: frases.join(', '), resumen_lineas };
}
