const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const path = require('path');
const readline = require('readline');
require('dotenv').config();

const SUPABASE_URL = process.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = process.env.VITE_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
    console.error('Faltan variables VITE_SUPABASE_URL o VITE_SUPABASE_ANON_KEY en el .env');
    process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
const rl = readline.createInterface({ input: process.stdin, output: process.stdout });

function askQuestion(query) {
    return new Promise(resolve => rl.question(query, resolve));
}

async function uploadData() {
    console.log("=== SCRIPT DE MIGRACIÓN DE DATOS (LEOLCA -> SUPABASE) ===");
    console.log("Para subir los datos, necesitamos iniciar sesión en tu app.");
    
    const email = await askQuestion("Email de acceso: ");
    const password = await askQuestion("Contraseña: ");
    rl.close();

    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({ email, password });
    if (authError) {
        console.error("Error al iniciar sesión:", authError.message);
        process.exit(1);
    }
    
    console.log("✅ Sesión iniciada correctamente.");

    // Obtener organizacion_id
    const { data: profile } = await supabase.from('perfiles_organizacion')
        .select('organizacion_id')
        .eq('usuario_id', authData.user.id)
        .limit(1)
        .single();
        
    if (!profile) {
        console.error("No se encontró una organización para este usuario.");
        process.exit(1);
    }
    
    const orgId = profile.organizacion_id;
    console.log("✅ Organización detectada:", orgId);
    
    // Leer CSVs
    const clientesCSV = fs.readFileSync(path.join(__dirname, '..', 'import_clientes.csv'), 'utf8').split('\n');
    const materialesCSV = fs.readFileSync(path.join(__dirname, '..', 'import_materiales.csv'), 'utf8').split('\n');
    
    // Parsear e Insertar Clientes
    if (clientesCSV.length > 1) {
        const clientesToInsert = [];
        for (let i = 1; i < clientesCSV.length; i++) {
            if (!clientesCSV[i].trim()) continue;
            // Split by comma ignoring commas inside quotes
            const row = clientesCSV[i].match(/(".*?"|[^",\s]+)(?=\s*,|\s*$)/g) || clientesCSV[i].split(',');
            const clean = row.map(s => s.replace(/^"|"$/g, '').trim());
            
            clientesToInsert.push({
                organizacion_id: orgId,
                nombre_razon_social: clean[0] || 'Cliente Sin Nombre',
                nombre_contacto: clean[2] || '', // empresa
                direccion: clean[3] || '',
                codigo_postal: clean[4] || '',
                telefono: clean[5] || '',
                correo: clean[6] || ''
            });
        }
        
        console.log(`Subiendo ${clientesToInsert.length} clientes...`);
        const { error: cliErr } = await supabase.from('clientes').insert(clientesToInsert);
        if (cliErr) console.error("⚠️ Error insertando clientes:", cliErr.message);
        else console.log("✅ Clientes subidos exitosamente.");
    }
    
    // Parsear e Insertar Materiales
    if (materialesCSV.length > 1) {
        const materialesToInsert = [];
        for (let i = 1; i < materialesCSV.length; i++) {
            if (!materialesCSV[i].trim()) continue;
            const row = materialesCSV[i].match(/(".*?"|[^",\s]+)(?=\s*,|\s*$)/g) || materialesCSV[i].split(',');
            const clean = row.map(s => s.replace(/^"|"$/g, '').trim());
            
            materialesToInsert.push({
                organizacion_id: orgId,
                nombre: clean[0] || 'Material sin nombre',
                costo: parseFloat(clean[1]) || 0,
                precio_unitario: parseFloat(clean[1]) || 0,
                tipo_item: clean[2] || 'materia_prima',
                tipo: 'bien',
                unidad: 'PZA'
            });
        }
        
        console.log(`Subiendo ${materialesToInsert.length} materiales...`);
        // Supabase limits bulk inserts sometimes, slice in chunks of 100
        const chunkSize = 100;
        for (let i = 0; i < materialesToInsert.length; i += chunkSize) {
            const chunk = materialesToInsert.slice(i, i + chunkSize);
            const { error: matErr } = await supabase.from('productos').insert(chunk);
            if (matErr) console.error("⚠️ Error insertando materiales:", matErr.message);
        }
        console.log("✅ Materiales subidos exitosamente.");
    }
    
    console.log("🎉 ¡Migración finalizada! Ya puedes ir a la app y ver los datos.");
}

uploadData();
