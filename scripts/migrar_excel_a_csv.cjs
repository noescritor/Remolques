const XLSX = require('xlsx');
const fs = require('fs');
const path = require('path');

function exportToCSV(filename, data) {
    if (data.length === 0) return;
    const header = Object.keys(data[0]);
    const csvContent = [
        header.join(','),
        ...data.map(row => 
            header.map(fieldName => {
                let cell = row[fieldName] === null || row[fieldName] === undefined ? '' : row[fieldName].toString();
                cell = cell.replace(/"/g, '""'); // escape comillas dobles
                if (cell.search(/("|,|\n)/g) >= 0) {
                    cell = `"${cell}"`;
                }
                return cell;
            }).join(',')
        )
    ].join('\n');
    
    fs.writeFileSync(path.join(__dirname, '..', filename), csvContent, 'utf8');
    console.log(`✅ Archivo generado: ${filename} con ${data.length} registros.`);
}

try {
    console.log("Leyendo archivo Excel... esto puede tomar unos segundos...");
    const wb = XLSX.readFile(path.join(__dirname, '..', 'PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm'));
    
    // ==========================================
    // 1. EXTRAER CLIENTES
    // ==========================================
    const sheetClientes = wb.Sheets['CLIENTES'];
    const jsonClientes = XLSX.utils.sheet_to_json(sheetClientes, { header: 1 });
    
    const clientesProcesados = [];
    
    // Las primeras filas suelen ser títulos. Buscamos donde empieza "CLIENTE"
    let startRow = 0;
    for (let i = 0; i < jsonClientes.length; i++) {
        if (jsonClientes[i] && jsonClientes[i][0] === 'CLIENTE') {
            startRow = i + 1;
            break;
        }
    }

    for (let i = startRow; i < jsonClientes.length; i++) {
        const row = jsonClientes[i];
        if (!row || !row[0]) continue; // Si no hay nombre de cliente, ignorar
        
        clientesProcesados.push({
            nombre: row[0] || '',
            rfc: row[1] || '',
            empresa: row[2] || '',
            direccion: `${row[3] || ''} ${row[4] || ''}`.trim(),
            codigo_postal: row[5] || '',
            telefono: row[6] || '',
            email: row[7] || '',
            tipo: 'Fisica' // Default
        });
    }
    
    exportToCSV('import_clientes.csv', clientesProcesados);


    // ==========================================
    // 2. EXTRAER TARIFARIO (Materia Prima)
    // ==========================================
    const sheetTarifario = wb.Sheets['TARIFARIO'];
    const jsonTarifario = XLSX.utils.sheet_to_json(sheetTarifario, { header: 1 });
    
    const materialesProcesados = [];
    
    // Buscamos líneas que tengan un material y un precio
    for (let i = 0; i < jsonTarifario.length; i++) {
        const row = jsonTarifario[i];
        if (!row) continue;
        
        // En TARIFARIO, suele ser Columna 1: MATERIAL, Columna 2: PRECIO
        // Vamos a buscar en múltiples combinaciones que detectamos
        const mat1 = row[1]; // A veces el material está en index 1
        const precio1 = row[2]; 
        
        if (typeof mat1 === 'string' && mat1.trim() !== '' && typeof precio1 === 'number') {
            materialesProcesados.push({
                nombre: mat1.trim(),
                precio_base: precio1,
                tipo_item: 'materia_prima',
                tipo: 'bien',
                categoria: 'Acero/Materiales'
            });
        }
        
        // El tarifario tiene varias columnas, buscamos en otras también (index 5 y 6)
        const mat2 = row[5];
        const precio2 = row[6];
        if (typeof mat2 === 'string' && mat2.trim() !== '' && typeof precio2 === 'number') {
             materialesProcesados.push({
                nombre: mat2.trim(),
                precio_base: precio2,
                tipo_item: 'materia_prima',
                tipo: 'bien',
                categoria: 'Acero/Materiales'
            });
        }
    }
    
    // Limpiar duplicados por nombre
    const unicos = [];
    const nombresVistos = new Set();
    for (const m of materialesProcesados) {
        if (!nombresVistos.has(m.nombre)) {
            nombresVistos.add(m.nombre);
            unicos.push(m);
        }
    }

    exportToCSV('import_materiales.csv', unicos);

    console.log("\nProceso terminado exitosamente. Usa el Dashboard de Supabase para importar estos archivos CSV.");

} catch (e) {
    console.error("Error al procesar el Excel:", e);
}
