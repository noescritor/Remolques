const fs = require('fs');
const path = require('path');

try {
    const clientesCSV = fs.readFileSync(path.join(__dirname, '..', 'import_clientes.csv'), 'utf8').split('\n');
    const materialesCSV = fs.readFileSync(path.join(__dirname, '..', 'import_materiales.csv'), 'utf8').split('\n');
    
    function parseCSVLine(text) {
        const ret = [];
        let inQuote = false;
        let value = "";
        for (let i = 0; i < text.length; i++) {
            const char = text[i];
            if (char === '"' && text[i+1] === '"') {
                value += '"';
                i++;
            } else if (char === '"') {
                inQuote = !inQuote;
            } else if (char === ',' && !inQuote) {
                ret.push(value);
                value = "";
            } else {
                value += char;
            }
        }
        ret.push(value);
        return ret;
    }

    let sql = `-- Script de Migración Inicial de Datos (LEOLCA)
-- (Compatible con Supabase SQL Editor)

-- 1. INSERTAR CLIENTES
`;

    const ORG_SUBQUERY = `(SELECT id FROM organizaciones LIMIT 1)`;

    // Process Clientes
    const clientesVals = [];
    for (let i = 1; i < clientesCSV.length; i++) {
        if (!clientesCSV[i].trim()) continue;
        const row = parseCSVLine(clientesCSV[i]);
        const clean = row.map(s => s.trim().replace(/'/g, "''"));
        
        const nombre = clean[0] || 'Cliente Sin Nombre';
        const contacto = clean[2] || '';
        const direccion = clean[3] || '';
        const cp = clean[4] || '';
        const tel = clean[5] || '';
        const email = clean[6] || '';
        
        clientesVals.push(`    (${ORG_SUBQUERY}, '${nombre}', '${contacto}', '${direccion}', '${cp}', '${tel}', '${email}')`);
    }

    if (clientesVals.length > 0) {
        sql += `INSERT INTO clientes (organizacion_id, nombre_razon_social, nombre_contacto, direccion, codigo_postal, telefono, correo) VALUES\n`;
        sql += clientesVals.join(',\n') + ';\n\n';
    }

    sql += `-- 2. INSERTAR MATERIALES\n`;

    // Process Materiales
    const matVals = [];
    for (let i = 1; i < materialesCSV.length; i++) {
        if (!materialesCSV[i].trim()) continue;
        const row = parseCSVLine(materialesCSV[i]);
        const clean = row.map(s => s.trim().replace(/'/g, "''"));
        
        const nombre = clean[0] || 'Material sin nombre';
        const precio = parseFloat(clean[1]) || 0;
        
        matVals.push(`    (${ORG_SUBQUERY}, 'bien', 'materia_prima', 'PZA', '${nombre}', ${precio}, ${precio})`);
    }

    if (matVals.length > 0) {
        sql += `INSERT INTO productos (organizacion_id, tipo, tipo_item, unidad, nombre, costo, precio_unitario) VALUES\n`;
        sql += matVals.join(',\n') + ';\n';
    }

    fs.writeFileSync(path.join(__dirname, '..', '20261001_02_migracion_leolca.sql'), sql, 'utf8');
    console.log("SQL script FIXED for Supabase Editor: 20261001_02_migracion_leolca.sql");

} catch (e) {
    console.error("Error creating SQL:", e);
}
