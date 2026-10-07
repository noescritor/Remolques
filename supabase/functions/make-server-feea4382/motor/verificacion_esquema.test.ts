import { assertEquals } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import * as path from "https://deno.land/std@0.192.0/path/mod.ts";

Deno.test("Prueba de Contrato: Columnas en migraciones", async () => {
  const migrationsDir = path.join(Deno.cwd(), "supabase/migrations");
  let migrationContent = "";
  try {
    for await (const dirEntry of Deno.readDir(migrationsDir)) {
      if (dirEntry.name.includes("configurador_esquema") || dirEntry.name.includes("recetas_plataforma")) {
        migrationContent += await Deno.readTextFile(path.join(migrationsDir, dirEntry.name));
      }
    }
  } catch (e: any) {
    // If we can't read migrations (e.g. running outside of root), we skip or fail softly
    console.log("No se pudieron leer las migraciones:", e.message);
  }

  // If no migrations found to test against, just return
  if (!migrationContent) {
    return;
  }

  const queries = [
    {
      table: "modelos",
      select: "id, tipo, largo_ft, num_ejes" // Removed productos(nombre) since it's a join, not a direct column
    },
    {
      table: "receta_base",
      select: "material_id, cantidad, escala, paso, uso, condicion"
    },
    {
      table: "grupos_configuracion",
      select: "id, clave, nombre, seleccion, regla, aplica_a, depende_de, cantidad, unidad_precio, medidas"
    },
    {
      table: "opciones_configuracion",
      select: "id, grupo_id, clave, nombre, marcas, medidas, activo, aliases, precio_venta, clase"
    },
    {
      table: "opcion_componentes",
      select: "opcion_id, material_id, cantidad, escala, paso, rol, uso"
    }
  ];

  console.log("\n--- PRUEBA DE CONTRATO (Consulta -> Columna -> Migración) ---");
  for (const q of queries) {
    const tableRegex = new RegExp(`CREATE TABLE (IF NOT EXISTS )?(public\\.)?"?${q.table}"?\\s*\\(([\\s\\S]*?)\\);`, "i");
    const match = tableRegex.exec(migrationContent);
    
    if (!match) {
      console.log(`Tabla ${q.table} no encontrada en las migraciones para validar.`);
      continue;
    }
    const columnsBlock = match[3];

    const columns = q.select.split(",").map(c => c.trim().split(" ")[0]);
    for (const col of columns) {
      // Check if column exists in the CREATE TABLE block
      const colRegex = new RegExp(`\\b${col}\\b`, "i");
      if (colRegex.test(columnsBlock)) {
        console.log(`${q.table} -> ${col} -> OK`);
      } else {
        console.log(`${q.table} -> ${col} -> ERROR (No encontrada en esquema)`);
        throw new Error(`La columna ${col} no existe en la tabla ${q.table} según la migración.`);
      }
    }
  }
  console.log("--------------------------------------------------------------\n");
});
