// @ts-nocheck
import { assertEquals } from "https://deno.land/std@0.208.0/assert/mod.ts";
import { obtenerConfiguracion, normalizarResumenLineas } from "./configuracionEquipo.ts";

Deno.test("obtenerConfiguracion", () => {
    // 1. Prioriza item.configuracion
    assertEquals(obtenerConfiguracion({ configuracion: "A", metadata: { configuracion: "B" } }), "A");
    // 2. Fallback a item.metadata.configuracion
    assertEquals(obtenerConfiguracion({ metadata: { configuracion: "B" } }), "B");
    // 3. Undefined si ninguno
    assertEquals(obtenerConfiguracion({}), undefined);
    assertEquals(obtenerConfiguracion(null), undefined);
});

Deno.test("normalizarResumenLineas", () => {
    // 1. Manejo de null/undefined
    assertEquals(normalizarResumenLineas(null), []);
    assertEquals(normalizarResumenLineas(undefined), []);
    assertEquals(normalizarResumenLineas("no es arreglo"), []);

    // 2. Objetos estructurados (esperado actual)
    const objetos = [
        { etiqueta: "Rines", valor: "8 Rines Aluminio" },
        { etiqueta: "Llantas", valor: "8 Llantas Firestone" }
    ];
    assertEquals(normalizarResumenLineas(objetos), objetos);

    // 3. Strings legacy (ej: "Rines: 8 Rines Aluminio")
    const strings = ["Rines: 8 Rines Aluminio", "Llantas: 8 Llantas Firestone", "SinDosPuntos"];
    assertEquals(normalizarResumenLineas(strings), [
        { etiqueta: "Rines", valor: "8 Rines Aluminio" },
        { etiqueta: "Llantas", valor: "8 Llantas Firestone" },
        { etiqueta: "SinDosPuntos", valor: "" }
    ]);

    // 4. Mixto y basuras que deben descartarse
    const mixto = [
        { etiqueta: "Valido", valor: "1" },
        "ValidoString: 2",
        123, // Invalido
        null, // Invalido
        { otra_prop: "invalido" }, // Sin etiqueta ni valor
        { etiqueta: "Valido3" } // Falta valor, pero tiene etiqueta
    ];
    assertEquals(normalizarResumenLineas(mixto), [
        { etiqueta: "Valido", valor: "1" },
        { etiqueta: "ValidoString", valor: "2" },
        { etiqueta: "Valido3", valor: "" }
    ]);
});

