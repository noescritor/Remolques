// @ts-nocheck
import { assertEquals, assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import { BASE_URL } from "./api.ts";

Deno.test("urls_api: BASE_URL está configurada hacia el backend vigente de EasyPanel", () => {
  assert(BASE_URL.startsWith("https://"), "BASE_URL debe iniciar con https://");
  assert(BASE_URL.includes("easypanel.host"), "BASE_URL debe apuntar a easypanel.host");
  assert(!BASE_URL.endsWith("/"), "BASE_URL no debe terminar con diagonal");
});

Deno.test("urls_api: Cero referencias a funciones viejas de Supabase en todo el código fuente de src/", async () => {
  const patronProhibido = ["functions", "v1"].join("/");
  const archivosConCoincidencia: string[] = [];

  async function revisarDirectorio(dir: string) {
    for await (const entry of Deno.readDir(dir)) {
      const fullPath = `${dir}/${entry.name}`;
      if (entry.isDirectory) {
        if (entry.name !== "node_modules" && !entry.name.startsWith(".")) {
          await revisarDirectorio(fullPath);
        }
      } else if (entry.isFile && (entry.name.endsWith(".ts") || entry.name.endsWith(".tsx") || entry.name.endsWith(".js") || entry.name.endsWith(".jsx"))) {
        // Ignorar este archivo de prueba para evitar falsos positivos por introspección
        if (entry.name.includes(".test.")) continue;

        const contenido = await Deno.readTextFile(fullPath);
        if (contenido.includes(patronProhibido)) {
          archivosConCoincidencia.push(fullPath);
        }
      }
    }
  }

  // Ubicar src/ a partir de la ruta del módulo de prueba
  const srcDir = new URL("../../", import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, "$1");
  await revisarDirectorio(srcDir);

  assertEquals(
    archivosConCoincidencia,
    [],
    `Se encontraron referencias prohibidas a '${patronProhibido}' en: ${archivosConCoincidencia.join(", ")}`
  );
});
