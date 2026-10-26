import type { DatosModelo, Configuracion, Resultado, LineaResultado } from "./tipos.ts";
import { validarCompatibilidad, fusionarFilasConfig, normalizarClaveOpcion } from "./reglas_compatibilidad.ts";

export function resolverReceta(datos: DatosModelo, configuracion: Configuracion): Resultado {
  const lineasMap = new Map<string, LineaResultado>();
  const omitidas: { descripcion: string; texto: string }[] = [];
  const alternativas: { reemplaza: string | null; posibles_reemplazos: string[]; sustituto: string; grupo: string }[] = [];
  const advertencias: string[] = [];
  const errores: string[] = [];
  const sin_precio: string[] = [];
  let costo_parcial = 0;
  let completo = true;

  const tieneAcero = (datos.receta_base || []).some(rb => rb.seccion === 'acero');
  const secciones_pendientes: string[] = tieneAcero ? [] : ["acero"];

  // Helper to add lines
  const agregarLinea = (
    matId: string,
    nombre: string,
    unidad: string,
    cantidad: number,
    paso: string | null,
    uso: string | null,
    origen: string,
    costo: number | null,
    descripcion: string | null,
    seccion: string = "ensamble"
  ) => {
    if (cantidad <= 0) return;
    const key = `${matId}_${unidad}_${seccion}`;
    let linea = lineasMap.get(key);
    if (!linea) {
      linea = {
        material_id: matId,
        nombre,
        cantidad: 0,
        unidad,
        paso: [],
        uso: [],
        seccion,
        origen: []
      };
      lineasMap.set(key, linea);
    }
    linea.cantidad += cantidad;
    if (paso && !linea.paso.includes(paso)) linea.paso.push(paso);
    if (uso && !linea.uso.includes(uso)) linea.uso.push(uso);
    if (!linea.origen.includes(origen)) linea.origen.push(origen);

    // Track cost
    if (costo === null || costo === 0 || descripcion === 'SIN PRECIO') {
      if (!sin_precio.includes(nombre)) sin_precio.push(nombre);
    } else {
      costo_parcial += costo * cantidad;
    }
  };

  // Helper to evaluate conditions
  const evaluarCondicion = (condicion: any, lineaNombre: string, lineaCantidad: number, lineaUso: string | null): boolean => {
    if (!condicion) return true;
    if (condicion.sin_mapear) {
      omitidas.push({ descripcion: `Condición sin mapear: ${condicion.sin_mapear}`, texto: `${lineaNombre} (x${lineaCantidad}) - Uso: ${lineaUso || ''}` });
      return false;
    }
    if (condicion.todas) {
      for (const cond of condicion.todas) {
        let valConfig: any = null;
        if (cond.campo === 'ejes') {
          valConfig = datos.modelo.num_ejes;
        } else if (cond.campo === 'largo_ft') {
          valConfig = datos.modelo.largo_ft;
        } else {
          const valConfigRaw = configuracion.grupos[cond.campo];
          valConfig = typeof valConfigRaw === 'string' ? valConfigRaw : ((valConfigRaw as any)?.opcion || '');
        }
        
        if (cond.op === '!=') {
          if (valConfig === cond.valor) return false;
        } else if (cond.op === 'in') {
          if (!cond.valor.includes(valConfig)) return false;
        } else if (cond.op === '==' || cond.op === '=') {
          if (valConfig !== cond.valor) return false;
        } else {
          errores.push(`Operador desconocido en condición: ${cond.op}`);
          return false;
        }
      }
    }
    return true;
  };

  // Resolve scale
  const calcularCantidad = (cantidadBase: number, escala: string): number => {
    if (escala === 'por_eje') {
      return cantidadBase * datos.modelo.num_ejes;
    } else if (escala === 'por_largo') {
      return cantidadBase * (datos.modelo.largo_ft / 40.0);
    }
    return cantidadBase; // fija
  };

  // 1. Process base recipe
  for (const rb of datos.receta_base) {
    if (!evaluarCondicion(rb.condicion, rb.nombre, rb.cantidad, rb.uso)) continue;
    
    const qty = calcularCantidad(rb.cantidad, rb.escala);
    const seccion = rb.seccion || "ensamble";
    agregarLinea(rb.material_id, rb.nombre, rb.unidad, qty, rb.paso, rb.uso, "base", rb.costo, rb.descripcion, seccion);
  }

  // 2. Validate options and configuration
  validarCompatibilidad(configuracion, datos, errores, advertencias);

  // Group config logic
  const modelType = datos.modelo.tipo;

  // Validate missing mandatory groups and unknown groups
  for (const [key, _] of Object.entries(configuracion.grupos || {})) {
    if (!datos.grupos.find(g => g.clave === key)) {
      errores.push(`Grupo desconocido en la configuración: ${key}`);
    }
  }

  for (const grupo of datos.grupos) {
    if (grupo.aplica_a && !grupo.aplica_a.includes(modelType)) continue;
    
    if (grupo.depende_de) {
      const parentValRaw = configuracion.grupos[grupo.depende_de.grupo];
      const parentVal = typeof parentValRaw === 'string' ? parentValRaw : ((parentValRaw as any)?.opcion || '');
      if (parentVal !== grupo.depende_de.opcion) continue;
    }

    const valConfigRaw = configuracion.grupos[grupo.clave];
    if (!valConfigRaw) {
      if (grupo.seleccion === 'unica' || grupo.seleccion === 'unica_con_cantidad') {
        errores.push(`Falta elegir una opción para el grupo obligatorio: ${grupo.nombre}`);
      }
      continue;
    }

    const rawVals = Array.isArray(valConfigRaw) ? valConfigRaw : [valConfigRaw];
    const configVals = fusionarFilasConfig(rawVals);

    for (const valConfig of configVals) {
      const oClave = typeof valConfig === 'string' ? valConfig : valConfig.opcion;
      const oClaveNorm = normalizarClaveOpcion(grupo.clave, oClave);
      const opcion = datos.opciones.find(o => o.grupo_id === grupo.id && o.clave === oClaveNorm)
        || datos.opciones.find(o => o.grupo_id === grupo.id && o.clave === oClave);
      
      if (!opcion) {
        errores.push(`Opción no válida para el grupo ${grupo.nombre}: ${oClave}`);
        continue;
      }
      if (opcion.activo === false && oClave === oClaveNorm) {
        errores.push(`La opción ${opcion.nombre} del grupo ${grupo.nombre} está inactiva.`);
        continue;
      }

      const componentes = datos.opcion_componentes.filter(c => c.opcion_id === opcion.id);
      
      if (componentes.length === 0) {
        if (!opcion.clave.startsWith('sin_') && opcion.clave !== 'paleta' && opcion.clave !== 'grande' && opcion.clave !== 'cliente' && opcion.clave !== 'personalizado') {
          advertencias.push(`La opción ${opcion.nombre} no tiene receta configurada.`);
          completo = false;
        }
      } else {
        let confMarca = typeof valConfig === 'object' ? valConfig.marca : undefined;
        let confCant = typeof valConfig === 'object' ? valConfig.cantidad : undefined;

        const requiereMarca = (grupo.clave === 'rines' && opcion.clave !== 'sin_rines' && opcion.clave !== 'cliente') || confMarca !== undefined;
        let marcaNormalizada = confMarca ? confMarca.toUpperCase().trim() : null;
        
        if (marcaNormalizada) {
          if (marcaNormalizada === 'FLET MASTER') marcaNormalizada = 'FLEET MASTER';
          if (marcaNormalizada === 'AMPRO TRAPEZOIDAL') marcaNormalizada = 'AMPRO MASTER TRAPEZOIDAL';
        }

        let matchedRims = 0;

        for (const comp of componentes) {
          if (comp.rol === 'sustituto') {
            const primerasPalabras = comp.nombre.split(' ')[0];
            const posibles = componentes.filter(c => c.rol !== 'sustituto' && c.nombre.startsWith(primerasPalabras)).map(c => c.nombre);
            alternativas.push({ 
              reemplaza: null, 
              posibles_reemplazos: posibles, 
              sustituto: comp.nombre, 
              grupo: grupo.clave 
            });
            continue; 
          }

          let qty = calcularCantidad(comp.cantidad, comp.escala);
          if ((grupo.seleccion === 'unica_con_cantidad' || grupo.seleccion === 'multiple_con_cantidad' || grupo.seleccion === 'cantidad') && confCant !== undefined) {
            qty = confCant;
          }

          if (requiereMarca) {
            if (!marcaNormalizada) {
              // Evaluated later
            } else {
              const posiblesMarcas = (opcion.marcas || []).map((m: string) => m.toUpperCase().trim());
              const aliasesMarcas = (opcion.aliases || []).map((m: string) => m.toUpperCase().trim());
              const esMarcaValida = posiblesMarcas.includes(marcaNormalizada) || aliasesMarcas.includes(marcaNormalizada) || (marcaNormalizada === 'AMPRO MASTER TRAPEZOIDAL' && posiblesMarcas.includes('AMPRO TRAPEZOIDAL')); 
              
              if (esMarcaValida) {
                  const nombreEsperado = `RIN DE ${opcion.clave.toUpperCase()} ${marcaNormalizada}`;
                  if (comp.nombre === nombreEsperado) {
                    agregarLinea(comp.material_id, comp.nombre, comp.unidad, qty, comp.paso, comp.uso, `opcion:${grupo.clave}/${opcion.clave}`, comp.costo, comp.descripcion);
                    matchedRims++;
                  }
              }
            }
          } else {
            agregarLinea(comp.material_id, comp.nombre, comp.unidad, qty, comp.paso, comp.uso, `opcion:${grupo.clave}/${opcion.clave}`, comp.costo, comp.descripcion);
          }
        }

        if (requiereMarca) {
          if (!marcaNormalizada) {
              errores.push(`El grupo ${grupo.nombre} requiere especificar una marca.`);
          } else if (matchedRims !== 1) {
              errores.push(`No se encontró exactamente un componente con la marca ${marcaNormalizada} para la opción ${opcion.nombre} (se encontraron ${matchedRims}).`);
          }
        }
      }
    }
  }

  // Completeness check
  if (errores.length > 0 || sin_precio.length > 0 || secciones_pendientes.length > 0) {
    completo = false;
  }

  return {
    lineas: Array.from(lineasMap.values()),
    omitidas,
    alternativas,
    advertencias,
    errores,
    sin_precio,
    costo_parcial,
    completo,
    secciones_pendientes
  };
}
