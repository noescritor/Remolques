const XLSX = require('xlsx');

try {
    const workbook = XLSX.readFile('PRESUPUESTOS Y COTIZACIONES LEOLCA.xlsm');
    console.log("Sheet names:");
    console.log(workbook.SheetNames);
    
    // For each sheet, let's print the first 5 rows to see what it looks like
    for (const sheetName of workbook.SheetNames) {
        console.log(`\n--- Sheet: ${sheetName} ---`);
        const sheet = workbook.Sheets[sheetName];
        const json = XLSX.utils.sheet_to_json(sheet, { header: 1, range: 0, defval: "" });
        for (let i = 0; i < Math.min(10, json.length); i++) {
            console.log(json[i].filter(cell => cell !== "").join(" | "));
        }
        
        // Also show some row lower down just in case there's a header gap
        if (json.length > 20) {
            console.log("... row 20 ...");
            console.log(json[20].filter(cell => cell !== "").join(" | "));
        }
    }
} catch (e) {
    console.error("Error:", e);
}
