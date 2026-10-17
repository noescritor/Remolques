import type {
  Modelo,
  Configuracion,
  DatosCosteo,
  AjusteManual,
  ResultadoCosteo,
  LineaCosteo,
  PendienteCosteo
} from "./tipos.ts";
import { fusionarFilasConfig } from "./reglas_compatibilidad.ts";

function calcularCantidad(cantidadBase: number, escala: string, modelo: Modelo): number {
  if (escala === "por_eje") {
    return cantidadBase * modelo.num_ejes;
  } else if (escala === "por_largo") {
    return cantidadBase * (modelo.largo_ft / 40.0);
  }
  return cantidadBase; // fija
}

export function validarAjustes(ajustes: any): { valido: boolean; error?: string } {
  if (ajustes === undefined || ajustes === null) {
    return { valido: true };
  }
  if (!Array.isArray(ajustes)) {
    return { valido: false, error: "Ajustes debe ser un arreglo" };
  }
  for (const a of ajustes) {
    if (
      !a ||
      typeof a !== "object" ||
      typeof a.concepto !== "string" ||
      typeof a.cantidad !== "number" ||
      !Number.isFinite(a.cantidad) ||
      a.cantidad <= 0 ||
      typeof a.costo_unitario !== "number" ||
      !Number.isFinite(a.costo_unitario)
    ) {
      return {
        valido: false,
        error: "Ajustes inválidos: cada ajuste requiere concepto (string), cantidad (número > 0) y costo_unitario (número finito)"
      };
    }
  }
  return { valido: true };
}

export function costear(
  datos: DatosCosteo,
  configuracion: Configuracion,
  ajustes: AjusteManual[] = []
): ResultadoCosteo {
  const pendientes: PendienteCosteo[] = [];
  const modelo = datos.modelo;

  // 1. Validar si el modelo tiene costos cargados
  const tieneAcero = (datos.receta_acero || []).length > 0;
  const tieneKits = (datos.costos_modelo || []).length > 0;
  const tieneProcesos = modelo.tipo === "gondola" ? true : (datos.procesos || []).length > 0;

  if (!tieneAcero) {
    pendientes.push({
      tipo: "modelo_sin_costos",
      detalle: "Falta despiece de acero para este modelo"
    });
  }
  if (!tieneKits) {
    pendientes.push({
      tipo: "modelo_sin_costos",
      detalle: "Faltan costos fijos de modelo para este modelo"
    });
  }
  if (!tieneProcesos) {
    pendientes.push({
      tipo: "modelo_sin_costos",
      detalle: "Faltan procesos de manufactura para este modelo"
    });
  }

  if (datos.costos_derivados_de) {
    const nombreOrigen = datos.costos_derivados_de.nombre || "modelo base";
    pendientes.push({
      tipo: "variante_supuesta",
      detalle: `Costos estimados a partir de ${nombreOrigen}: no hay desglose propio de esta variante`
    });
  }

  if (modelo.tipo === "gondola") {
    pendientes.push({
      tipo: "iva_gondola",
      detalle: "El IVA de la góndola está por confirmar con el dueño: en el Excel es 16% solo sobre chasis + tina; el precio sugerido no lo incluye"
    });
  }

  // 2. Acero
  const lineasAcero: LineaCosteo[] = [];
  let sumAcero = 0;

  for (const item of datos.receta_acero || []) {
    const qty = calcularCantidad(item.cantidad, item.escala, modelo);
    const sinPrecio =
      item.costo === null ||
      item.costo === undefined ||
      item.costo === 0 ||
      item.descripcion === "SIN PRECIO";

    let cu = 0;
    let imp = 0;

    if (sinPrecio) {
      pendientes.push({
        tipo: "sin_precio",
        detalle: `Material de acero sin precio: ${item.nombre}`
      });
    } else {
      cu = item.costo!;
      imp = qty * cu;
      sumAcero += imp;
    }

    lineasAcero.push({
      concepto: item.nombre,
      cantidad: qty,
      costo_unitario: cu,
      importe: Math.round(imp * 100) / 100,
      origen: "acero"
    });
  }

  // 3. Kits fijos
  const lineasKits: LineaCosteo[] = [];
  let sumKits = 0;

  for (const kit of datos.costos_modelo || []) {
    const qty = calcularCantidad(kit.cantidad, kit.escala, modelo);
    const cu = kit.costo_unitario;
    const imp = qty * cu;
    sumKits += imp;

    lineasKits.push({
      concepto: kit.concepto,
      cantidad: qty,
      costo_unitario: cu,
      importe: Math.round(imp * 100) / 100,
      origen: "kit",
      seccion: kit.seccion
    });
  }

  // 4. Opciones
  const lineasOpciones: LineaCosteo[] = [];
  let sumOpciones = 0;
  const noFacturaPorFuente = new Map<string, string[]>();

  const gruposEntries = Object.entries(configuracion.grupos || {});
  if (configuracion.adicionales && !configuracion.grupos?.adicionales) {
    gruposEntries.push(["adicionales", configuracion.adicionales]);
  }

  for (const [grupoClave, valConfigRaw] of gruposEntries) {
    if (!valConfigRaw) continue;
    const rawVals = Array.isArray(valConfigRaw) ? valConfigRaw : [valConfigRaw];
    const configVals = fusionarFilasConfig(rawVals);

    for (const valConfig of configVals) {
      const oClave = typeof valConfig === "string" ? valConfig : valConfig.opcion;
      if (!oClave) continue;

      const optCosto = (datos.opcion_costos || []).find(
        (oc) => oc.grupo_clave === grupoClave && oc.opcion_clave === oClave
      );

      if (optCosto) {
        const esFuentePendiente =
          Boolean(optCosto.fuente) &&
          (optCosto.fuente!.startsWith("Tarifario") || optCosto.fuente!.startsWith("Supuesto"));

        if (esFuentePendiente) {
          const lista = noFacturaPorFuente.get(optCosto.fuente!) || [];
          const optStr = `${grupoClave}/${oClave}`;
          if (!lista.includes(optStr)) {
            lista.push(optStr);
          }
          noFacturaPorFuente.set(optCosto.fuente!, lista);
        }

        let qty: number;
        const confCant = typeof valConfig === "object" ? valConfig.cantidad : undefined;

        if (confCant !== undefined && confCant !== null && !isNaN(confCant)) {
          qty = confCant;
        } else {
          const factor =
            optCosto.escala === "por_eje"
              ? modelo.num_ejes
              : optCosto.escala === "por_largo"
              ? modelo.largo_ft / 40.0
              : 1;
          const cantBase = optCosto.cantidad_base || (grupoClave === "matracas" ? 12 : (grupoClave === "rines" || grupoClave === "llantas") ? 4 : 1);
          qty = cantBase * factor;
        }

        let cu = optCosto.costo_unitario;
        let sinPrecioProducto = false;

        if (optCosto.costo_desde_producto && optCosto.producto_id) {
          if (
            optCosto.producto_costo === null ||
            optCosto.producto_costo === undefined ||
            optCosto.producto_costo === 0
          ) {
            sinPrecioProducto = true;
            cu = 0;
            pendientes.push({
              tipo: "sin_precio",
              detalle: `Opción con producto sin precio: ${grupoClave}/${oClave}`
            });
          } else {
            cu = optCosto.producto_costo;
          }
        }

        const imp = sinPrecioProducto ? 0 : qty * cu;
        sumOpciones += imp;

        lineasOpciones.push({
          concepto: `${grupoClave}: ${oClave}`,
          cantidad: qty,
          costo_unitario: cu,
          importe: Math.round(imp * 100) / 100,
          origen: `opcion:${grupoClave}/${oClave}`
        });
      } else {
        const esExenta =
          oClave.startsWith("sin_") || oClave === "paleta" || oClave === "cliente";

        if (!esExenta) {
          pendientes.push({
            tipo: "opcion_sin_costo",
            detalle: `Opción sin costo configurado: ${grupoClave}/${oClave}`
          });
        }

        lineasOpciones.push({
          concepto: `${grupoClave}: ${oClave}`,
          cantidad: 1,
          costo_unitario: 0,
          importe: 0,
          origen: `opcion:${grupoClave}/${oClave}`
        });
      }
    }
  }

  for (const [fuente, items] of noFacturaPorFuente.entries()) {
    pendientes.push({
      tipo: "costo_no_factura",
      detalle: `Costos que no vienen de la Factura (por confirmar): ${fuente} → ${items.join(", ")}`
    });
  }

  // 5. Mano de obra
  const lineasManoObra: LineaCosteo[] = [];
  let sumManoObra = 0;

  for (const proc of datos.procesos || []) {
    const horas = proc.minutos / 60;
    const imp = (proc.minutos * proc.tarifa_hora) / 60;
    sumManoObra += imp;

    const concepto = proc.subproceso
      ? `${proc.proceso} - ${proc.subproceso}`
      : proc.proceso;

    lineasManoObra.push({
      concepto,
      cantidad: horas,
      costo_unitario: proc.tarifa_hora,
      importe: Math.round(imp * 100) / 100,
      origen: "mano_obra"
    });
  }

  // 6. Ajustes manuales
  const lineasAjustes: LineaCosteo[] = [];
  let sumAjustes = 0;

  for (const aj of ajustes || []) {
    const imp = aj.cantidad * aj.costo_unitario;
    sumAjustes += imp;

    lineasAjustes.push({
      concepto: aj.concepto,
      cantidad: aj.cantidad,
      costo_unitario: aj.costo_unitario,
      importe: Math.round(imp * 100) / 100,
      origen: "ajuste"
    });
  }

  // 7. Redondeo sección por sección a 2 decimales
  const totalAcero = Math.round(sumAcero * 100) / 100;
  const totalKits = Math.round(sumKits * 100) / 100;
  const totalOpciones = Math.round(sumOpciones * 100) / 100;
  const totalManoObra = Math.round(sumManoObra * 100) / 100;
  const totalAjustes = Math.round(sumAjustes * 100) / 100;

  const costo = Math.round((totalAcero + totalKits + totalOpciones + totalManoObra + totalAjustes) * 100) / 100;

  // 8. Ganancia y precio sugerido
  const ganancia =
    datos.ganancia !== null && datos.ganancia !== undefined ? datos.ganancia : null;

  if (ganancia === null) {
    pendientes.push({
      tipo: "ganancia_no_definida",
      detalle: `Ganancia no definida para el tipo de modelo: ${modelo.tipo}`
    });
  }

  // Confianza
  let confianza: "completa" | "estimada" | "incompleta";
  let precio_sugerido: number | null = null;

  if (!tieneAcero || !tieneKits || !tieneProcesos) {
    confianza = "incompleta";
    precio_sugerido = null;
  } else if (pendientes.length === 0) {
    confianza = "completa";
    precio_sugerido = ganancia !== null ? Math.round((costo + ganancia) * 100) / 100 : null;
  } else {
    confianza = "estimada";
    precio_sugerido = ganancia !== null ? Math.round((costo + ganancia) * 100) / 100 : null;
  }

  const margen_sobre_precio =
    precio_sugerido !== null && precio_sugerido > 0 && ganancia !== null
      ? ganancia / precio_sugerido
      : null;

  const margen_sobre_costo =
    costo > 0 && ganancia !== null ? ganancia / costo : null;

  return {
    moneda: "MXN",
    secciones: {
      acero: { total: totalAcero, lineas: lineasAcero },
      kits_fijos: { total: totalKits, lineas: lineasKits },
      opciones: { total: totalOpciones, lineas: lineasOpciones },
      mano_obra: { total: totalManoObra, lineas: lineasManoObra },
      ajustes: { total: totalAjustes, lineas: lineasAjustes }
    },
    costo,
    ganancia,
    precio_sugerido,
    margen_sobre_precio,
    margen_sobre_costo,
    confianza,
    pendientes
  };
}
