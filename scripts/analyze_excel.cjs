const XLSX = require('xlsx');

try {
    const wb = XLSX.readFile('PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm');
    
    function peekSheet(name) {
        const sheet = wb.Sheets[name];
        if (!sheet) return;
        console.log(`\n=== SHEET: ${name} ===`);
        const json = XLSX.utils.sheet_to_json(sheet, { header: 1, range: 0, defval: null });
        let rowsShown = 0;
        for (let i = 0; i < json.length; i++) {
            const row = json[i].filter(cell => cell !== null && cell !== "");
            if (row.length > 0) {
                console.log(`Row ${i}: ${row.join(" | ")}`);
                rowsShown++;
                if (rowsShown > 10) break;
            }
        }
        console.log(`Total rows in ${name}: ${json.length}`);
    }

    peekSheet('CLIENTES');
    peekSheet('PRODUCTOS');
    peekSheet('TARIFARIO');
    peekSheet('BASE DAT PLANAS');
    peekSheet('COTIZACION');
    
} catch (e) {
    console.error("Error:", e);
}
