// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import {
  validarArchivoLogo,
  sanearSvg,
  calcularDimensionesLogo,
  calcularTamanoDataUrl,
  decidirLogoEncabezado
} from "./logo.ts";

Deno.test("logo utils - validarArchivoLogo: acepta formatos válidos y rechaza inválidos o mayores a 2 MB", () => {
  // Acepta extensiones permitidas
  assertEquals(validarArchivoLogo({ name: "logo.svg", size: 1024, type: "image/svg+xml" }).valido, true);
  assertEquals(validarArchivoLogo({ name: "logo.png", size: 50000, type: "image/png" }).valido, true);
  assertEquals(validarArchivoLogo({ name: "logo.jpg", size: 80000, type: "image/jpeg" }).valido, true);
  assertEquals(validarArchivoLogo({ name: "logo.webp", size: 30000, type: "image/webp" }).valido, true);

  // Rechaza formato no permitido
  const resPdf = validarArchivoLogo({ name: "documento.pdf", size: 10000, type: "application/pdf" });
  assertEquals(resPdf.valido, false);
  assert(resPdf.error?.includes("Formato no compatible"));

  const resGif = validarArchivoLogo({ name: "animacion.gif", size: 20000, type: "image/gif" });
  assertEquals(resGif.valido, false);

  // Rechaza > 2 MB (2,097,152 bytes)
  const resGrande = validarArchivoLogo({ name: "foto.png", size: 2097153, type: "image/png" });
  assertEquals(resGrande.valido, false);
  assert(resGrande.error?.includes("2 MB"));

  // Rechaza archivo vacío
  const resVacio = validarArchivoLogo({ name: "vacio.png", size: 0, type: "image/png" });
  assertEquals(resVacio.valido, false);
  assert(resVacio.error?.includes("vacío"));
});

Deno.test("logo utils - sanearSvg: acepta estructura válida estilo Leolca y rechaza contenido inseguro", () => {
  // Fragmento SVG seguro mínimo (mismo esquema de Leolca.svg)
  const svgSeguro = `<?xml version="1.0" encoding="UTF-8"?>
  <svg width="443mm" height="110mm" viewBox="0 0 443 110" xmlns="http://www.w3.org/2000/svg">
    <g transform="translate(10, 20)">
      <path style="fill:#ffffff" d="M 10 10 L 50 10 L 50 50 Z" />
      <use href="#defs-internas" />
    </g>
  </svg>`;
  assertEquals(sanearSvg(svgSeguro).valido, true);

  // Rechaza <script>
  const svgScript = `<svg xmlns="http://www.w3.org/2000/svg"><script>alert('xss')</script></svg>`;
  const resScript = sanearSvg(svgScript);
  assertEquals(resScript.valido, false);
  assert(resScript.error?.includes("<script>"));

  // Rechaza <foreignObject>
  const svgForeign = `<svg xmlns="http://www.w3.org/2000/svg"><foreignObject width="100" height="100"><iframe src="evil.com"></iframe></foreignObject></svg>`;
  const resForeign = sanearSvg(svgForeign);
  assertEquals(resForeign.valido, false);
  assert(resForeign.error?.includes("<foreignObject>"));

  // Rechaza atributos on* (onload, onerror, onclick)
  const svgOnload = `<svg xmlns="http://www.w3.org/2000/svg" onload="fetch('evil.com')"><rect width="10" height="10"/></svg>`;
  const resOnload = sanearSvg(svgOnload);
  assertEquals(resOnload.valido, false);
  assert(resOnload.error?.includes("on*"));

  // Rechaza href externo (http/https)
  const svgHrefExt = `<svg xmlns="http://www.w3.org/2000/svg"><image href="https://malicious.com/tracker.png" /></svg>`;
  const resHrefExt = sanearSvg(svgHrefExt);
  assertEquals(resHrefExt.valido, false);
  assert(resHrefExt.error?.includes("referencias externas"));

  // Rechaza estructura que no es SVG
  const noSvg = `<div>Hola mundo</div>`;
  assertEquals(sanearSvg(noSvg).valido, false);
});

Deno.test("logo utils - calcularDimensionesLogo: no agranda y escala a ancho máximo respetando proporción", () => {
  // Proporción 4:1 (ej. 1600 × 400) -> a máx 1200 px da exactamente 1200 × 300
  const dimGrande = calcularDimensionesLogo(1600, 400, 1200);
  assertEquals(dimGrande.width, 1200);
  assertEquals(dimGrande.height, 300);

  // Proporción de Leolca (~443 × 110) a máx 1200: no se agranda
  const dimLeolca = calcularDimensionesLogo(443, 110, 1200);
  assertEquals(dimLeolca.width, 443);
  assertEquals(dimLeolca.height, 110);

  // Imagen angosta (800 × 200) con tope 1200: se mantiene
  const dimMenor = calcularDimensionesLogo(800, 200, 1200);
  assertEquals(dimMenor.width, 800);
  assertEquals(dimMenor.height, 200);

  // Imagen grande con tope 800 (paso de reducción): 1600 × 400 -> 800 × 200
  const dimReducido = calcularDimensionesLogo(1600, 400, 800);
  assertEquals(dimReducido.width, 800);
  assertEquals(dimReducido.height, 200);
});

Deno.test("logo utils - decidirLogoEncabezado: selecciona logo y contenedor según fondo y preferencias", () => {
  const ajustesCompletos = {
    logo: "data:image/png;base64,logoOscuro",
    logo_claro: "data:image/png;base64,logoClaro",
    logo_mostrar_nombre: false,
    nombre_empresa: "LEOLCA"
  };

  // Fondo oscuro con ambos logos: toma logo
  const decOscuro = decidirLogoEncabezado(ajustesCompletos, "oscuro");
  assertEquals(decOscuro.url, "data:image/png;base64,logoOscuro");
  assertEquals(decOscuro.usarContenedorNegro, false);
  assertEquals(decOscuro.mostrarNombre, false);

  // Fondo claro con ambos logos: toma logo_claro sin contenedor negro
  const decClaro = decidirLogoEncabezado(ajustesCompletos, "claro");
  assertEquals(decClaro.url, "data:image/png;base64,logoClaro");
  assertEquals(decClaro.usarContenedorNegro, false);
  assertEquals(decClaro.mostrarNombre, false);

  // Solo logo oscuro (ej. logo blanco) en fondo claro: usa logo oscuro dentro de contenedor negro
  const ajustesSoloOscuro = {
    logo: "data:image/png;base64,soloBlanco",
    logo_mostrar_nombre: true
  };
  const decSoloOscuroEnClaro = decidirLogoEncabezado(ajustesSoloOscuro, "claro");
  assertEquals(decSoloOscuroEnClaro.url, "data:image/png;base64,soloBlanco");
  assertEquals(decSoloOscuroEnClaro.usarContenedorNegro, true);
  assertEquals(decSoloOscuroEnClaro.mostrarNombre, true);

  // Sin ningún logo configurado: url undefined y mostrarNombre true (comportamiento actual)
  const decSinLogo = decidirLogoEncabezado({ nombre_empresa: "IDEALLY" }, "oscuro");
  assertEquals(decSinLogo.url, undefined);
  assertEquals(decSinLogo.usarContenedorNegro, false);
  assertEquals(decSinLogo.mostrarNombre, true);
});
