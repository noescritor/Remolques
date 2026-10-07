const fs = require('fs');
const clasificacion = require('../docs/importacion/clasificacion_2R1b.json');

let sql = `BEGIN;

DO $$ 
DECLARE 
    v_org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_model_id uuid;
    v_group_id uuid;
    v_option_id uuid;
    v_mat_id uuid;
    v_count int;
    rec record;
BEGIN

-- 1. Asegurar que existan los 10 modelos de plataforma
SELECT count(*) INTO v_count FROM modelos WHERE tipo = 'plataforma';
IF v_count != 10 THEN
    RAISE EXCEPTION 'Se esperaban 10 modelos de plataforma, pero se encontraron %', v_count;
END IF;

-- 2. Limpieza idempotente
DELETE FROM receta_base WHERE notas = 'import-2r1b';
DELETE FROM opcion_componentes WHERE notas = 'import-2r1b';

-- 3. Inserción de materiales faltantes
`;

// Collect all unique normalized materials to create
const uniqueMaterials = new Set();
for (const row of clasificacion) {
    if (row.destino !== 'ignorar' && row.producto) {
        uniqueMaterials.add(row.producto.toString().toUpperCase().trim().replace(/\s+/g, ' '));
    }
}

for (const mat of uniqueMaterials) {
    const safeMat = mat.replace(/'/g, "''");
    sql += `INSERT INTO productos (nombre, tipo, tipo_item, costo, precio_unitario, descripcion, organizacion_id)
            SELECT '${safeMat}', 'bien', 'materia_prima', 0, 0, 'SIN PRECIO', v_org_id
            WHERE NOT EXISTS (SELECT 1 FROM productos WHERE nombre = '${safeMat}' AND organizacion_id = v_org_id AND tipo_item = 'materia_prima');\n`;
}

const modelsToProcess = [
    { num_ejes: 2, largo_ft: 35 },
    { num_ejes: 2, largo_ft: 40 },
    { num_ejes: 3, largo_ft: 40 },
    { num_ejes: 2, largo_ft: 42 },
    { num_ejes: 3, largo_ft: 42 },
    { num_ejes: 3, largo_ft: 43 },
    { num_ejes: 2, largo_ft: 45 },
    { num_ejes: 3, largo_ft: 45 },
    { num_ejes: 2, largo_ft: 48 },
    { num_ejes: 3, largo_ft: 48 }
];

sql += `\n-- 4. Inserción de receta_base\n`;

for (const model of modelsToProcess) {
    sql += `
    SELECT id INTO v_model_id FROM modelos WHERE tipo = 'plataforma' AND num_ejes = ${model.num_ejes} AND largo_ft = ${model.largo_ft} LIMIT 1;
    IF v_model_id IS NULL THEN RAISE EXCEPTION 'Modelo PLATAFORMA % % FT no encontrado', ${model.num_ejes}, ${model.largo_ft}; END IF;
`;
    for (const row of clasificacion) {
        if (row.destino === 'receta_base' || row.destino === 'receta_base_condicionada') {
            const mat = row.producto.toString().toUpperCase().trim().replace(/\s+/g, ' ').replace(/'/g, "''");
            const paso = (row.proceso || 'PASO 1').replace(/'/g, "''");
            let uso = row.uso ? `'${row.uso.replace(/'/g, "''")}'` : 'NULL';
            
            sql += `
    SELECT id INTO v_mat_id FROM productos WHERE nombre = '${mat}' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ${mat}'; END IF;
    INSERT INTO receta_base (modelo_id, material_id, cantidad, escala, paso, uso, notas)
    VALUES (v_model_id, v_mat_id, ${row.cantidad_calculada || row.cantidad}, '${row.escala}', '${paso}', ${uso}, 'import-2r1b');\n`;
        }
    }
}

sql += `\n-- 5. Inserción de opcion_componentes\n`;

for (const row of clasificacion) {
    if (row.destino === 'opcion_componentes') {
        const mat = row.producto.toString().toUpperCase().trim().replace(/\s+/g, ' ').replace(/'/g, "''");
        const paso = (row.proceso || 'PASO 1').replace(/'/g, "''");
        
        sql += `
    SELECT id INTO v_group_id FROM grupos_configuracion WHERE clave = '${row.grupo_id}' LIMIT 1;
    IF v_group_id IS NULL THEN RAISE EXCEPTION 'Grupo no encontrado: ${row.grupo_id}'; END IF;
    
    SELECT id INTO v_option_id FROM opciones_configuracion WHERE grupo_id = v_group_id AND clave = '${row.opcion_id}' LIMIT 1;
    IF v_option_id IS NULL THEN RAISE EXCEPTION 'Opción no encontrada: ${row.grupo_id} -> ${row.opcion_id}'; END IF;
    
    SELECT id INTO v_mat_id FROM productos WHERE nombre = '${mat}' AND tipo_item = 'materia_prima' LIMIT 1;
    IF v_mat_id IS NULL THEN RAISE EXCEPTION 'Material no encontrado: ${mat}'; END IF;

    INSERT INTO opcion_componentes (opcion_id, material_id, cantidad, escala, rol, paso, notas)
    VALUES (v_option_id, v_mat_id, ${row.cantidad_calculada || row.cantidad}, '${row.escala}', '${row.rol}', '${paso}', 'import-2r1b');\n`;
    }
}

sql += `
END $$;
COMMIT;
`;

fs.writeFileSync('supabase/migrations/20261008_01_recetas_plataforma.sql', sql, 'utf8');
console.log('SQL generado.');
