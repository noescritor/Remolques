import { Modelo, Configuracion, GrupoOpcion, Opcion } from './tipos.ts';

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
  'pintura': {
    etiqueta: 'Pintura',
    plantilla: (o) => `PINTURA ${limpiarNombre(o.nombre)}`
  },
  'rines': {
    etiqueta: 'Rines',
    plantilla: (o, v, m) => {
      const qty = v?.cantidad || (m.num_ejes * 4);
      const marca = v?.marca ? ` MARCA ${v.marca.toUpperCase()}` : '';
      return `${qty} RINES DE ${limpiarNombre(o.nombre, 'Rines de')}${marca}`;
    }
  },
  'llantas': {
    etiqueta: 'Llantas',
    plantilla: (o, v, m) => {
      const qty = v?.cantidad || (m.num_ejes * 4);
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

  const modeloTexto = `PLATAFORMA ${modelo.largo_ft} FT ${modelo.num_ejes} EJES`;
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
    const values = Array.isArray(configValue) ? configValue : [configValue];

    for (const val of values) {
      const opcionClave = typeof val === 'string' ? val : val.opcion;
      if (!opcionClave || opcionClave.startsWith('sin_')) continue;

      const grupo = grupos.find(g => g.clave === claveGrupo);
      const opcion = opciones.find(o => o.grupo_id === grupo?.id && o.clave === opcionClave);

      if (grupo && opcion) {
        const plantillaDef = TABLA_PLANTILLAS[claveGrupo];
        let frase = '';
        let etiqueta = grupo.nombre;
        let valorResumen = limpiarNombre(opcion.nombre);

        if (plantillaDef) {
          frase = plantillaDef.plantilla(opcion, val, modelo);
          etiqueta = plantillaDef.etiqueta;
          
          if (claveGrupo === 'rines' || claveGrupo === 'llantas') {
             const qty = typeof val === 'object' && val.cantidad ? val.cantidad : (modelo.num_ejes * 4);
             const marca = typeof val === 'object' && val.marca ? ` ${val.marca.toUpperCase()}` : '';
             const baseObj = limpiarNombre(opcion.nombre, claveGrupo === 'rines' ? 'Rines de' : '');
             valorResumen = `${qty} ${baseObj}${marca}`.trim();
          }
        } else {
          frase = `${grupo.nombre.toUpperCase()} ${limpiarNombre(opcion.nombre, grupo.nombre)}`;
        }

        frases.push(frase);
        resumen_lineas.push({ etiqueta, valor: valorResumen });
      }
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
