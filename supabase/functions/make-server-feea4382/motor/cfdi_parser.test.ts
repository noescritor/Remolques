import { assertEquals, assertThrows } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { parsearCFDI, validarSeguridadXML, cfdiAPartidasFactura } from "./cfdi_parser.ts";

const CFDI_33_SYNTHETIC = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/3" xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" Version="3.3" Serie="A" Folio="1001" Fecha="2026-10-15T14:30:00" FormaPago="03" MetodoPago="PPD" SubTotal="1000.00" Moneda="MXN" Total="1160.00" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="PROVEEDOR ACEROS DE CORDOBA SA DE CV" RegimenFiscal="601" />
  <cfdi:Receptor Rfc="LEO120524ABC" Nombre="REMOLQUES LEOLCA SA DE CV" UsoCFDI="G03" />
  <cfdi:Conceptos>
    <cfdi:Concepto ClaveProdServ="30101804" Cantidad="10" ClaveUnidad="H87" Unidad="Pieza" Descripcion="Viga IPR 4x102" ValorUnitario="100.00" Importe="1000.00" />
  </cfdi:Conceptos>
  <cfdi:Impuestos TotalImpuestosTrasladados="160.00">
    <cfdi:Traslados>
      <cfdi:Traslado Impuesto="002" TipoFactor="Tasa" TasaOCuota="0.160000" Importe="160.00" />
    </cfdi:Traslados>
  </cfdi:Impuestos>
  <cfdi:Complemento>
    <tfd:TimbreFiscalDigital Version="1.1" UUID="3B9F2A61-4B7C-4C8D-9E01-123456789ABC" FechaTimbrado="2026-10-15T14:31:00" />
  </cfdi:Complemento>
</cfdi:Comprobante>`;

const CFDI_40_USD_SYNTHETIC = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante xmlns:cfdi="http://www.sat.gob.mx/cfd/4" xmlns:tfd="http://www.sat.gob.mx/TimbreFiscalDigital" Version="4.0" Serie="EXP" Folio="5020" Fecha="2026-10-20T10:00:00" FormaPago="99" MetodoPago="PPD" SubTotal="5000.00" Descuento="200.00" Moneda="USD" TipoCambio="19.8500" Total="5568.00" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="AXI900101AAA" Nombre="AXLE &amp; SUSPENSIONS INTERNATIONAL INC" RegimenFiscal="601" />
  <cfdi:Receptor Rfc="LEO120524ABC" Nombre="REMOLQUES LEOLCA SA DE CV" DomicilioFiscalReceptor="94500" RegimenFiscalReceptor="601" UsoCFDI="G01" />
  <cfdi:Conceptos>
    <cfdi:Concepto ClaveProdServ="25171700" Cantidad="2" ClaveUnidad="H87" Descripcion="Ejes de 30000 lbs con frenos ABS" ValorUnitario="2500.00" Importe="5000.00" Descuento="200.00" />
  </cfdi:Conceptos>
  <cfdi:Impuestos TotalImpuestosTrasladados="768.00">
    <cfdi:Traslados>
      <cfdi:Traslado Base="4800.00" Impuesto="002" TipoFactor="Tasa" TasaOCuota="0.160000" Importe="768.00" />
    </cfdi:Traslados>
  </cfdi:Impuestos>
  <cfdi:Complemento>
    <tfd:TimbreFiscalDigital Version="1.1" UUID="99887766-5544-3322-1100-AABBCCDDEEFF" FechaTimbrado="2026-10-20T10:05:00" />
  </cfdi:Complemento>
</cfdi:Comprobante>`;

const CFDI_NOTA_CREDITO = `<?xml version="1.0" encoding="utf-8"?>
<cfdi:Comprobante Version="4.0" Serie="NC" Folio="12" Fecha="2026-10-22T09:00:00" SubTotal="500.00" Moneda="MXN" Total="580.00" TipoDeComprobante="E">
  <cfdi:Emisor Rfc="PAC010203XYZ" Nombre="PROVEEDOR ACEROS" />
  <cfdi:Receptor Rfc="LEO120524ABC" Nombre="REMOLQUES LEOLCA" />
  <cfdi:Complemento>
    <tfd:TimbreFiscalDigital UUID="AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE" />
  </cfdi:Complemento>
</cfdi:Comprobante>`;

const CFDI_XXE_ATTACK = `<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE test [ <!ENTITY xxe SYSTEM "file:///etc/passwd"> ]>
<cfdi:Comprobante Version="4.0" TipoDeComprobante="I">
  <cfdi:Emisor Rfc="&xxe;" />
</cfdi:Comprobante>`;

Deno.test("CFDI 3.3 sintético se parsea correctamente con UUID y montos en MXN", () => {
  const parsed = parsearCFDI(CFDI_33_SYNTHETIC);
  assertEquals(parsed.ok, true);
  assertEquals(parsed.version, "3.3");
  assertEquals(parsed.tipo_comprobante, "I");
  assertEquals(parsed.uuid_fiscal, "3B9F2A61-4B7C-4C8D-9E01-123456789ABC");
  assertEquals(parsed.folio, "1001");
  assertEquals(parsed.serie, "A");
  assertEquals(parsed.moneda, "MXN");
  assertEquals(parsed.subtotal, 1000);
  assertEquals(parsed.impuestos_trasladados, 160);
  assertEquals(parsed.total, 1160);
  assertEquals(parsed.emisor.rfc, "PAC010203XYZ");
  assertEquals(parsed.emisor.nombre, "PROVEEDOR ACEROS DE CORDOBA SA DE CV");
  assertEquals(parsed.conceptos.length, 1);
  assertEquals(parsed.conceptos[0].descripcion, "Viga IPR 4x102");
});

Deno.test("CFDI 4.0 sintético en USD con tipo de cambio y descuento", () => {
  const parsed = parsearCFDI(CFDI_40_USD_SYNTHETIC);
  assertEquals(parsed.ok, true);
  assertEquals(parsed.version, "4.0");
  assertEquals(parsed.moneda, "USD");
  assertEquals(parsed.tipo_cambio, 19.85);
  assertEquals(parsed.subtotal, 5000);
  assertEquals(parsed.descuento, 200);
  assertEquals(parsed.total, 5568);
  assertEquals(parsed.uuid_fiscal, "99887766-5544-3322-1100-AABBCCDDEEFF");
  assertEquals(parsed.conceptos[0].cantidad, 2);
});

Deno.test("Prevención de XXE: rechaza XML con DOCTYPE o ENTITY", () => {
  assertThrows(
    () => {
      validarSeguridadXML(CFDI_XXE_ATTACK);
    },
    Error,
    "XXE prevention"
  );
  assertThrows(
    () => {
      parsearCFDI(CFDI_XXE_ATTACK);
    },
    Error,
    "XXE prevention"
  );
});

Deno.test("Comprobante tipo E (Nota de crédito) es identificado y no importado", () => {
  const parsed = parsearCFDI(CFDI_NOTA_CREDITO);
  assertEquals(parsed.ok, false);
  assertEquals(parsed.tipo_comprobante, "E");
  assertEquals(parsed.error?.includes("Nota de crédito"), true);
});

Deno.test("cfdiAPartidasFactura genera conceptos, impuestos y descuentos", () => {
  const parsed = parsearCFDI(CFDI_40_USD_SYNTHETIC);
  const partidas = cfdiAPartidasFactura(parsed);
  assertEquals(partidas.length, 3); // 1 concepto, 1 descuento, 1 IVA trasladado
  assertEquals(partidas[0].tipo, "concepto");
  assertEquals(partidas[0].importe, 5000);
  assertEquals(partidas[1].tipo, "descuento");
  assertEquals(partidas[1].importe, 200);
  assertEquals(partidas[2].tipo, "impuesto_trasladado");
  assertEquals(partidas[2].importe, 768);
});
