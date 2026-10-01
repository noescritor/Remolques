const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');

try {
    const wb = XLSX.readFile(path.join(__dirname, '..', 'PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm'));
    const sheet = wb.Sheets['BASE DAT PLANAS'];
    const json = XLSX.utils.sheet_to_json(sheet, { header: 1 });

    let sql = `-- Script de Migración de BOM (Recetas de Producción)
-- (Compatible con Supabase SQL Editor)

-- 1. CREAR LOS PRODUCTOS TERMINADOS\n`;

    const ORG_SUBQUERY = `(SELECT id FROM organizaciones LIMIT 1)`;

    // Find the header row
    let headerRowIdx = -1;
    for (let i = 0; i < json.length; i++) {
        if (json[i] && json[i][1] === 'MATERIAL / ACCESORIO') {
            headerRowIdx = i;
            break;
        }
    }

    if (headerRowIdx === -1) {
        throw new Error("No se encontró la cabecera en BASE DAT PLANAS");
    }

    const headers = json[headerRowIdx];
    // headers[2] to headers[length-1] are the Finished Goods (Products)
    const productosTerminados = [];
    for (let c = 2; c < headers.length; c++) {
        if (headers[c] && typeof headers[c] === 'string' && headers[c].trim() !== '') {
            productosTerminados.push(headers[c].trim().replace(/'/g, "''"));
        }
    }

    // Insert finished goods
    for (const prod of productosTerminados) {
        sql += `INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, precio_unitario)
SELECT ${ORG_SUBQUERY}, 'bien', 'producto_terminado', 'PZA', '${prod}', 0
WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = '${prod}');\n`;
    }

    sql += `\n-- 2. ENLAZAR MATERIALES CON PRODUCTOS TERMINADOS (BOM)\n`;

    let connections = 0;

    for (let i = headerRowIdx + 1; i < json.length; i++) {
        const row = json[i];
        if (!row || !row[1]) continue; // No material name
        
        let materialName = row[1].toString().trim().replace(/'/g, "''");
        
        for (let c = 2; c < headers.length; c++) {
            const prodName = headers[c] ? headers[c].toString().trim().replace(/'/g, "''") : null;
            if (!prodName) continue;
            
            let qty = parseFloat(row[c]);
            if (isNaN(qty) || qty <= 0) {
                // If it's a string like "1", but maybe they put X or something, fallback to column 0
                qty = parseFloat(row[0]); 
            }
            if (isNaN(qty) || qty <= 0) continue;

            sql += `INSERT INTO producto_materiales (organizacion_id, producto_id, material_id, cantidad)
SELECT 
  ${ORG_SUBQUERY},
  (SELECT id FROM productos WHERE nombre = '${prodName}' LIMIT 1),
  (SELECT id FROM productos WHERE nombre = '${materialName}' LIMIT 1),
  ${qty}
WHERE 
  (SELECT id FROM productos WHERE nombre = '${prodName}' LIMIT 1) IS NOT NULL 
  AND 
  (SELECT id FROM productos WHERE nombre = '${materialName}' LIMIT 1) IS NOT NULL
  AND NOT EXISTS (
    SELECT 1 FROM producto_materiales 
    WHERE producto_id = (SELECT id FROM productos WHERE nombre = '${prodName}' LIMIT 1)
      AND material_id = (SELECT id FROM productos WHERE nombre = '${materialName}' LIMIT 1)
  );\n`;
            connections++;
        }
    }

    fs.writeFileSync(path.join(__dirname, '..', '20261001_03_migracion_bom.sql'), sql, 'utf8');
    console.log(`SQL script created: 20261001_03_migracion_bom.sql with ${productosTerminados.length} products and ${connections} relationships.`);

} catch (e) {
    console.error("Error:", e);
}
