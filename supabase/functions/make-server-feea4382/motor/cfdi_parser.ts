// Motor parser de CFDI 3.3 y 4.0 (Sub-bloque T4)
// Procesamiento seguro de comprobantes fiscales digitales mexicanos
// Sin dependencias de red, seguro contra XXE/DTD, ejecutable en Deno, Node y navegador.

export interface ConceptoCFDI {
  clave_prod_serv?: string;
  no_identificacion?: string;
  cantidad: number;
  clave_unidad?: string;
  unidad?: string;
  descripcion: string;
  valor_unitario: number;
  importe: number;
  descuento?: number;
}

export interface ImpuestoCFDI {
  tipo: 'traslado' | 'retencion';
  impuesto: string; // '002' (IVA), '001' (ISR), etc.
  tipo_factor?: string;
  tasa_o_cuota?: number;
  importe: number;
}

export interface CFDIParseado {
  ok: boolean;
  version: '3.3' | '4.0';
  tipo_comprobante: string; // 'I', 'E', 'P', etc.
  uuid_fiscal: string;
  fecha_timbrado?: string;
  serie?: string;
  folio?: string;
  fecha_emision: string;
  moneda: 'MXN' | 'USD';
  tipo_cambio: number;
  subtotal: number;
  descuento: number;
  impuestos_trasladados: number;
  impuestos_retenidos: number;
  total: number;
  metodo_pago?: string;
  forma_pago?: string;
  emisor: {
    rfc: string;
    nombre: string;
    regimen_fiscal?: string;
  };
  receptor: {
    rfc: string;
    nombre: string;
    uso_cfdi?: string;
  };
  conceptos: ConceptoCFDI[];
  impuestos: ImpuestoCFDI[];
  advertencias?: string[];
  error?: string;
}

// ── SEGURIDAD XXE / DTD / TAMAÑO ──
export function validarSeguridadXML(xml: string): void {
  if (typeof xml !== 'string' || !xml.trim()) {
    throw new Error('El contenido XML es obligatorio');
  }
  if (xml.length > 2 * 1024 * 1024) {
    throw new Error('El archivo XML excede el límite máximo de 2 MB');
  }
  if (/<!DOCTYPE/i.test(xml) || /<!ENTITY/i.test(xml)) {
    throw new Error('XML rechazado por contener declaraciones DTD o entidades externas (XXE prevention)');
  }
}

// ── AUXILIARES DE EXTRACCIÓN DE ATRIBUTOS ──
function getAttr(tagSnippet: string, attrName: string): string | null {
  const regex = new RegExp(`\\b${attrName}\\s*=\\s*["']([^"']*)["']`, 'i');
  const match = tagSnippet.match(regex);
  return match ? match[1].trim() : null;
}

function parseNumero(val: string | null, def = 0): number {
  if (!val) return def;
  const num = parseFloat(val);
  return Number.isFinite(num) ? Math.round((num + Number.EPSILON) * 100) / 100 : def;
}

export function parsearCFDI(xmlStr: string, rfcOrganizacionEsperado?: string): CFDIParseado {
  validarSeguridadXML(xmlStr);

  // 1. Extraer etiqueta Comprobante
  const compMatch = xmlStr.match(/<(?:\w+:)?Comprobante\b([^>]*)/i);
  if (!compMatch) {
    return {
      ok: false,
      version: '4.0',
      tipo_comprobante: '',
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: 'El archivo XML no contiene una etiqueta válida de Comprobante CFDI',
    };
  }

  const compAttrs = compMatch[1];
  const versionRaw = getAttr(compAttrs, 'Version') || getAttr(compAttrs, 'version') || '';
  if (versionRaw !== '3.3' && versionRaw !== '4.0') {
    return {
      ok: false,
      version: '4.0',
      tipo_comprobante: getAttr(compAttrs, 'TipoDeComprobante') || '',
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: `Versión de CFDI no soportada (${versionRaw || 'desconocida'}). Se requiere 3.3 o 4.0`,
    };
  }

  const version = versionRaw as '3.3' | '4.0';
  const tipoComprobante = (getAttr(compAttrs, 'TipoDeComprobante') || 'I').toUpperCase();

  // Filtrado por tipo de comprobante
  if (tipoComprobante === 'E') {
    return {
      ok: false,
      version,
      tipo_comprobante: 'E',
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: 'Nota de crédito (egreso), no importada como factura de proveedor',
    };
  }

  if (tipoComprobante === 'P') {
    return {
      ok: false,
      version,
      tipo_comprobante: 'P',
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: 'Complemento para recepción de pagos, no importado como factura de proveedor',
    };
  }

  if (tipoComprobante !== 'I') {
    return {
      ok: false,
      version,
      tipo_comprobante: tipoComprobante,
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: `Tipo de comprobante no soportado (${tipoComprobante}). Solo se admiten facturas de ingreso (I)`,
    };
  }

  // 2. Extraer Timbre Fiscal Digital
  const tfdMatch = xmlStr.match(/<(?:\w+:)?TimbreFiscalDigital\b([^>]*)/i);
  const uuidFiscal = tfdMatch ? (getAttr(tfdMatch[1], 'UUID') || '').toUpperCase() : '';
  const fechaTimbrado = tfdMatch ? getAttr(tfdMatch[1], 'FechaTimbrado') || undefined : undefined;

  if (!uuidFiscal) {
    return {
      ok: false,
      version,
      tipo_comprobante: tipoComprobante,
      uuid_fiscal: '',
      fecha_emision: '',
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: '', nombre: '' },
      receptor: { rfc: '', nombre: '' },
      conceptos: [],
      impuestos: [],
      error: 'No se encontró el UUID fiscal (Timbre Fiscal Digital)',
    };
  }

  // 3. Extraer Emisor
  const emisorMatch = xmlStr.match(/<(?:\w+:)?Emisor\b([^>]*)/i);
  const emisorAttrs = emisorMatch ? emisorMatch[1] : '';
  const rfcEmisor = (getAttr(emisorAttrs, 'Rfc') || '').toUpperCase();
  const nombreEmisor = getAttr(emisorAttrs, 'Nombre') || 'PROVEEDOR SIN NOMBRE';
  const regimenFiscal = getAttr(emisorAttrs, 'RegimenFiscal') || undefined;

  // 4. Extraer Receptor
  const receptorMatch = xmlStr.match(/<(?:\w+:)?Receptor\b([^>]*)/i);
  const receptorAttrs = receptorMatch ? receptorMatch[1] : '';
  const rfcReceptor = (getAttr(receptorAttrs, 'Rfc') || '').toUpperCase();
  const nombreReceptor = getAttr(receptorAttrs, 'Nombre') || '';
  const usoCFDI = getAttr(receptorAttrs, 'UsoCFDI') || undefined;

  // 5. Datos Generales de la Factura y Validación de Moneda
  const advertencias: string[] = [];

  const serie = getAttr(compAttrs, 'Serie') || undefined;
  const folio = getAttr(compAttrs, 'Folio') || undefined;
  const fechaEmision = getAttr(compAttrs, 'Fecha') || '';
  const monedaRaw = (getAttr(compAttrs, 'Moneda') || 'MXN').toUpperCase().trim();

  if (monedaRaw !== 'MXN' && monedaRaw !== 'USD' && monedaRaw !== 'PESO MEXICANO' && monedaRaw !== 'DOLARES' && monedaRaw !== 'DOLAR') {
    return {
      ok: false,
      version,
      tipo_comprobante: tipoComprobante,
      uuid_fiscal: uuidFiscal,
      fecha_emision: fechaEmision,
      moneda: 'MXN',
      tipo_cambio: 1,
      subtotal: 0,
      descuento: 0,
      impuestos_trasladados: 0,
      impuestos_retenidos: 0,
      total: 0,
      emisor: { rfc: rfcEmisor, nombre: nombreEmisor },
      receptor: { rfc: rfcReceptor, nombre: nombreReceptor },
      conceptos: [],
      impuestos: [],
      error: `Moneda no soportada (${monedaRaw}). Solo se admiten facturas en MXN o USD`,
    };
  }

  const moneda: 'MXN' | 'USD' = (monedaRaw === 'USD' || monedaRaw.includes('DOL')) ? 'USD' : 'MXN';
  const tcAttr = getAttr(compAttrs, 'TipoCambio');
  const tipoCambio = parseNumero(tcAttr, 1.0);

  if (moneda === 'USD' && (!tcAttr || tipoCambio <= 1)) {
    advertencias.push('Factura en USD sin tipo de cambio especificado en el comprobante (se requiere tipo de cambio manual)');
  }

  if (rfcOrganizacionEsperado && rfcReceptor && rfcReceptor !== rfcOrganizacionEsperado.toUpperCase().trim()) {
    advertencias.push(`El RFC del receptor (${rfcReceptor}) no coincide con el RFC de la empresa (${rfcOrganizacionEsperado.toUpperCase().trim()})`);
  }

  const subtotal = parseNumero(getAttr(compAttrs, 'SubTotal'), 0);
  const descuento = parseNumero(getAttr(compAttrs, 'Descuento'), 0);
  const total = parseNumero(getAttr(compAttrs, 'Total'), 0);
  const metodoPago = getAttr(compAttrs, 'MetodoPago') || undefined;
  const formaPago = getAttr(compAttrs, 'FormaPago') || undefined;

  // 6. Extraer Conceptos
  const conceptos: ConceptoCFDI[] = [];
  const conceptoRegex = /<(?:\w+:)?Concepto\b([^>]*?)(?:\/>|>([\s\S]*?)<\/(?:\w+:)?Concepto>)/gi;
  let matchConcepto: RegExpExecArray | null;

  while ((matchConcepto = conceptoRegex.exec(xmlStr)) !== null) {
    const cAttrs = matchConcepto[1];
    conceptos.push({
      clave_prod_serv: getAttr(cAttrs, 'ClaveProdServ') || undefined,
      no_identificacion: getAttr(cAttrs, 'NoIdentificacion') || undefined,
      cantidad: parseFloat(getAttr(cAttrs, 'Cantidad') || '1') || 1,
      clave_unidad: getAttr(cAttrs, 'ClaveUnidad') || undefined,
      unidad: getAttr(cAttrs, 'Unidad') || undefined,
      descripcion: getAttr(cAttrs, 'Descripcion') || 'Sin descripción',
      valor_unitario: parseNumero(getAttr(cAttrs, 'ValorUnitario'), 0),
      importe: parseNumero(getAttr(cAttrs, 'Importe'), 0),
      descuento: getAttr(cAttrs, 'Descuento') ? parseNumero(getAttr(cAttrs, 'Descuento'), 0) : undefined,
    });
  }

  // 7. Extraer Impuestos Globales (buscar después de </Conceptos> para no confundir con impuestos de cada concepto)
  const impuestos: ImpuestoCFDI[] = [];
  let impuestosTrasladados = 0;
  let impuestosRetenidos = 0;

  const posFinConceptos = xmlStr.search(/<\/(?:\w+:)?Conceptos>/i);
  const xmlPostConceptos = posFinConceptos !== -1 ? xmlStr.slice(posFinConceptos) : xmlStr;
  const impGlobalMatch = xmlPostConceptos.match(/<(?:\w+:)?Impuestos\b([^>]*?)(?:\/>|>([\s\S]*?)<\/(?:\w+:)?Impuestos>)/i);

  if (impGlobalMatch) {
    const impGlobalAttrs = impGlobalMatch[1] || '';
    impuestosTrasladados = parseNumero(getAttr(impGlobalAttrs, 'TotalImpuestosTrasladados'), 0);
    impuestosRetenidos = parseNumero(getAttr(impGlobalAttrs, 'TotalImpuestosRetenidos'), 0);

    const impContent = impGlobalMatch[2] || '';

    // Traslados individuales
    const trasladoRegex = /<(?:\w+:)?Traslado\b([^>]*)/gi;
    let matchTras: RegExpExecArray | null;
    let sumaTraslados = 0;
    while ((matchTras = trasladoRegex.exec(impContent)) !== null) {
      const tAttrs = matchTras[1];
      const impMonto = parseNumero(getAttr(tAttrs, 'Importe'), 0);
      sumaTraslados += impMonto;
      impuestos.push({
        tipo: 'traslado',
        impuesto: getAttr(tAttrs, 'Impuesto') || '002',
        tipo_factor: getAttr(tAttrs, 'TipoFactor') || undefined,
        tasa_o_cuota: getAttr(tAttrs, 'TasaOCuota') ? parseFloat(getAttr(tAttrs, 'TasaOCuota')!) : undefined,
        importe: impMonto,
      });
    }
    if (impuestosTrasladados === 0 && sumaTraslados > 0) {
      impuestosTrasladados = Math.round(sumaTraslados * 100) / 100;
    }

    // Retenciones individuales
    const retencionRegex = /<(?:\w+:)?Retencion\b([^>]*)/gi;
    let matchRet: RegExpExecArray | null;
    let sumaRetenciones = 0;
    while ((matchRet = retencionRegex.exec(impContent)) !== null) {
      const rAttrs = matchRet[1];
      const impMonto = parseNumero(getAttr(rAttrs, 'Importe'), 0);
      sumaRetenciones += impMonto;
      impuestos.push({
        tipo: 'retencion',
        impuesto: getAttr(rAttrs, 'Impuesto') || '002',
        importe: impMonto,
      });
    }
    if (impuestosRetenidos === 0 && sumaRetenciones > 0) {
      impuestosRetenidos = Math.round(sumaRetenciones * 100) / 100;
    }
  }

  // Validación de consistencia en el total del comprobante
  const totalCalculado = Math.round((subtotal - descuento + impuestosTrasladados - impuestosRetenidos) * 100) / 100;
  if (Math.abs(total - totalCalculado) > 0.05) {
    advertencias.push(`Inconsistencia en total: Total declarado (${total}) difiere del cálculo subtotal (${subtotal}) - descuento (${descuento}) + traslados (${impuestosTrasladados}) - retenciones (${impuestosRetenidos}) = ${totalCalculado}`);
  }

  return {
    ok: true,
    version,
    tipo_comprobante: tipoComprobante,
    uuid_fiscal: uuidFiscal,
    fecha_timbrado: fechaTimbrado,
    serie,
    folio,
    fecha_emision: fechaEmision,
    moneda,
    tipo_cambio: tipoCambio,
    subtotal,
    descuento,
    impuestos_trasladados: impuestosTrasladados,
    impuestos_retenidos: impuestosRetenidos,
    total,
    metodo_pago: metodoPago,
    forma_pago: formaPago,
    emisor: {
      rfc: rfcEmisor,
      nombre: nombreEmisor,
      regimen_fiscal: regimenFiscal,
    },
    receptor: {
      rfc: rfcReceptor,
      nombre: nombreReceptor,
      uso_cfdi: usoCFDI,
    },
    conceptos,
    impuestos,
    advertencias: advertencias.length > 0 ? advertencias : undefined,
  };
}

// ── CONVERSIÓN DE CFDI A FACTURA Y PARTIDAS DEL SISTEMA ──
export function cfdiAPartidasFactura(cfdi: CFDIParseado): Array<{
  tipo: 'concepto' | 'impuesto_trasladado' | 'retencion' | 'descuento' | 'otro_cargo';
  descripcion: string;
  cantidad: number;
  precio_unitario: number;
  importe: number;
  tasa_o_cuota?: number;
  clave_sat?: string;
  clave_unidad?: string;
}> {
  const partidas: Array<any> = [];

  // 1. Conceptos
  for (const c of cfdi.conceptos) {
    partidas.push({
      tipo: 'concepto',
      descripcion: c.descripcion,
      cantidad: c.cantidad,
      precio_unitario: c.valor_unitario,
      importe: c.importe,
      clave_sat: c.clave_prod_serv,
      clave_unidad: c.clave_unidad,
    });

    if (c.descuento && c.descuento > 0) {
      partidas.push({
        tipo: 'descuento',
        descripcion: `Descuento sobre ${c.descripcion}`,
        cantidad: 1,
        precio_unitario: c.descuento,
        importe: c.descuento,
      });
    }
  }

  // Descuento global adicional si aplica
  if (cfdi.descuento > 0 && !cfdi.conceptos.some(c => c.descuento && c.descuento > 0)) {
    partidas.push({
      tipo: 'descuento',
      descripcion: 'Descuento general de factura',
      cantidad: 1,
      precio_unitario: cfdi.descuento,
      importe: cfdi.descuento,
    });
  }

  // 2. Impuestos trasladados
  for (const imp of cfdi.impuestos.filter(i => i.tipo === 'traslado')) {
    const desc = imp.impuesto === '002' ? `IVA Trasladado (${((imp.tasa_o_cuota || 0.16) * 100).toFixed(0)}%)` : `Impuesto Trasladado ${imp.impuesto}`;
    partidas.push({
      tipo: 'impuesto_trasladado',
      descripcion: desc,
      cantidad: 1,
      precio_unitario: imp.importe,
      importe: imp.importe,
      tasa_o_cuota: imp.tasa_o_cuota,
    });
  }

  // Fallback si no hubo detalle pero sí totalImpuestosTrasladados
  if (cfdi.impuestos_trasladados > 0 && !cfdi.impuestos.some(i => i.tipo === 'traslado')) {
    partidas.push({
      tipo: 'impuesto_trasladado',
      descripcion: 'IVA Trasladado (16%)',
      cantidad: 1,
      precio_unitario: cfdi.impuestos_trasladados,
      importe: cfdi.impuestos_trasladados,
      tasa_o_cuota: 0.16,
    });
  }

  // 3. Retenciones
  for (const imp of cfdi.impuestos.filter(i => i.tipo === 'retencion')) {
    const desc = imp.impuesto === '002' ? 'Retención de IVA' : imp.impuesto === '001' ? 'Retención de ISR' : `Retención ${imp.impuesto}`;
    partidas.push({
      tipo: 'retencion',
      descripcion: desc,
      cantidad: 1,
      precio_unitario: imp.importe,
      importe: imp.importe,
    });
  }

  if (cfdi.impuestos_retenidos > 0 && !cfdi.impuestos.some(i => i.tipo === 'retencion')) {
    partidas.push({
      tipo: 'retencion',
      descripcion: 'Retenciones de Impuestos',
      cantidad: 1,
      precio_unitario: cfdi.impuestos_retenidos,
      importe: cfdi.impuestos_retenidos,
    });
  }

  return partidas;
}
