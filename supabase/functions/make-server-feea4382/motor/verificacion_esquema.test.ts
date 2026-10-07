import { assert } from "https://deno.land/std@0.192.0/testing/asserts.ts";
import * as path from "https://deno.land/std@0.192.0/path/mod.ts";

Deno.test("Prueba de Contrato: Columnas en migraciones extraídas del código real", async () => {
  const rootDir = Deno.cwd();
  const migrationsDir = path.join(rootDir, "supabase/migrations");
  
  let migrationContent = "";
  try {
    for await (const dirEntry of Deno.readDir(migrationsDir)) {
      if (dirEntry.name.endsWith(".sql")) {
        migrationContent += await Deno.readTextFile(path.join(migrationsDir, dirEntry.name));
      }
    }
  } catch (e: any) {
    console.log("No se pudieron leer las migraciones:", e.message);
  }

  if (!migrationContent) {
    throw new Error("No se encontró el contenido de las migraciones");
  }

  const parseSelects = async (filePath: string) => {
    let content = "";
    try {
      content = await Deno.readTextFile(filePath);
    } catch {
      throw new Error(`No se pudo leer el archivo: ${filePath}`);
    }
    
    // Buscar .from("tabla").select("columnas")
    const regex = /\.from\(\s*["']([^"']+)["']\s*\)(?:\s*\.[\w]+\([^)]*\))*\s*\.select\(\s*[`"']([^`"']+)[`"']\s*\)/g;
    const results = [];
    let match;
    while ((match = regex.exec(content)) !== null) {
      results.push({
        table: match[1],
        select: match[2].replace(/\s+/g, ' ')
      });
    }
    return results;
  };

  const queriesIndex = await parseSelects(path.join(rootDir, "supabase/functions/make-server-feea4382/index.ts"));
  const queriesMotor = await parseSelects(path.join(rootDir, "supabase/functions/make-server-feea4382/motor/cargar_datos.ts"));
  
  const cpqTables = ["modelos", "grupos_configuracion", "opciones_configuracion", "receta_base", "opcion_componentes"];
  const allQueries = [...queriesIndex.filter(q => cpqTables.includes(q.table)), ...queriesMotor.filter(q => cpqTables.includes(q.table))];
  
  if (allQueries.length === 0) {
    throw new Error("No se encontraron consultas en index.ts ni cargar_datos.ts");
  }

  console.log("\n--- PRUEBA DE CONTRATO (Consulta -> Columna -> Migración) ---");
  for (const q of allQueries) {
    // Buscar la declaración de la tabla principal
    const tableRegex = new RegExp(`CREATE TABLE (IF NOT EXISTS )?(public\\.)?"?${q.table}"?\\s*\\(([\\s\\S]*?)\\);`, "i");
    const match = tableRegex.exec(migrationContent);
    
    if (!match) {
      throw new Error(`Tabla ${q.table} no encontrada en las migraciones para validar.`);
    }
    const columnsBlock = match[3];

    // Limpiar select (manejar inner selects como "productos(nombre)")
    const items = q.select.split(/,(?![^(]*\))/).map(c => c.trim());
    
    for (const item of items) {
      // Si es un embed (fk), la tabla padre debe existir y tener la columna principal o simplemente validamos la relación si es posible.
      // Por ahora, extraemos la parte antes del paréntesis si es un embed, o validamos el embed
      const embedMatch = item.match(/^(?:\w+:)?(\w+)\s*\((.*?)\)$/);
      if (embedMatch) {
        const relation = embedMatch[1];
        const innerCols = embedMatch[2].split(",").map(c => c.trim());
        
        // Verificamos tabla hija
        const innerTableRegex = new RegExp(`CREATE TABLE (IF NOT EXISTS )?(public\\.)?"?${relation}"?\\s*\\(([\\s\\S]*?)\\);`, "i");
        const innerMatch = innerTableRegex.exec(migrationContent);
        if (!innerMatch) {
          throw new Error(`Tabla relacional ${relation} (de ${item}) no encontrada en migraciones.`);
        }
        
        const innerColumnsBlock = innerMatch[3];
        for (const iCol of innerCols) {
            const colName = iCol.split(" ")[0]; // remove AS alias if any
            const colRegex = new RegExp(`\\b${colName}\\b`, "i");
            if (!colRegex.test(innerColumnsBlock)) {
                throw new Error(`La columna ${colName} no existe en la tabla relacionada ${relation} según la migración.`);
            }
            console.log(`${q.table} -> ${relation}(${colName}) -> OK`);
        }
      } else {
        const colName = item.split(" ")[0]; // remove AS alias
        const colRegex = new RegExp(`\\b${colName}\\b`, "i");
        if (!colRegex.test(columnsBlock)) {
            throw new Error(`La columna ${colName} no existe en la tabla ${q.table} según la migración.`);
        }
        console.log(`${q.table} -> ${colName} -> OK`);
      }
    }
  }
  console.log("--------------------------------------------------------------\n");
});
