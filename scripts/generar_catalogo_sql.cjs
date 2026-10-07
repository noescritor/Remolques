const fs = require('fs');

const raw = fs.readFileSync('docs/catalogo-opciones/catalogo_opciones_unificado.json', 'utf8');
const data = JSON.parse(raw);

const SQL_FILE = 'supabase/migrations/20261007_02_catalogo_opciones.sql';

let sql = `BEGIN;

DO $$ 
DECLARE 
    org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_grupo_id uuid;
BEGIN

-- 1. PARAMETROS COSTEO
INSERT INTO parametros_costeo (organizacion_id, clave, valor)
VALUES 
    (org_id, 'iva_pct', '16'::jsonb),
    (org_id, 'margen_sugerido', '{"plataforma": 110000, "dolly": 40000}'::jsonb)
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    valor = EXCLUDED.valor;

-- 2. MODELOS PLATAFORMA (10 Variantes)
`;

const plataforma = data.modelos.find(m => m.tipo === 'plataforma');
if (plataforma && plataforma.variantes) {
    plataforma.variantes.forEach((v) => {
        // Parse variant string: e.g. "35 ft x2"
        const matchLargo = v.match(/(\d+)\s*ft/i);
        const matchEjes = v.match(/x(\d)/i);
        
        let matchCond = "";
        if (matchLargo && matchEjes) {
            matchCond = `nombre ILIKE '%${matchLargo[1]}%FT%' AND nombre ILIKE '%${matchEjes[1]}%EJES%'`;
        } else if (matchLargo) {
            matchCond = `nombre ILIKE '%${matchLargo[1]}%FT%'`;
        } else {
            matchCond = `nombre ILIKE '%${v.toUpperCase()}%'`;
        }
        
        sql += `
INSERT INTO modelos (organizacion_id, producto_id, tipo, prefijo)
SELECT org_id, id, 'plataforma', 'PLA'
FROM productos 
WHERE ${matchCond} AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
LIMIT 1
ON CONFLICT (organizacion_id, producto_id) DO NOTHING;
`;
    });
}

sql += `\n-- 3. GRUPOS Y OPCIONES\n`;

let order = 10;
for (const grupo of data.grupos) {
    const req = grupo.seleccion === 'unica' ? 'true' : 'false';
    const mult = grupo.seleccion === 'multiple' ? 'true' : 'false';
    const groupNameEscaped = grupo.nombre.replace(/'/g, "''");
    const claveGrupo = grupo.clave.replace(/'/g, "''");
    
    sql += `
-- Grupo: ${groupNameEscaped}
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, requerido, multiple, orden)
VALUES (org_id, '${claveGrupo}', '${groupNameEscaped}', ${req}, ${mult}, ${order})
ON CONFLICT (organizacion_id, clave) DO UPDATE SET nombre = EXCLUDED.nombre, requerido = EXCLUDED.requerido, multiple = EXCLUDED.multiple, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;
`;

    if (grupo.opciones) {
        for (const opcion of grupo.opciones) {
            const descEscaped = opcion.nombre.replace(/'/g, "''");
            const claveOpcion = (opcion.clave || opcion.nombre).replace(/'/g, "''");
            const price = opcion.precio === "sin_precio" || opcion.precio === null ? 'NULL' : parseFloat(opcion.precio) || 'NULL';
            
            // Build aliases array
            let aliasesArray = 'NULL';
            if (opcion.aliases && opcion.aliases.length > 0) {
                const escapedAliases = opcion.aliases.map(a => `'${a.replace(/'/g, "''")}'`).join(', ');
                aliasesArray = `ARRAY[${escapedAliases}]::text[]`;
            }

            const jsonDatos = {};
            if (opcion.otros_precios) jsonDatos.otros_precios = opcion.otros_precios;
            if (opcion.medidas) jsonDatos.medidas = opcion.medidas;
            // Any other extra fields can go into datos. e.g. precio_fuente
            if (opcion.precio_fuente) jsonDatos.precio_fuente = opcion.precio_fuente;

            const jsonStr = Object.keys(jsonDatos).length > 0 ? `'${JSON.stringify(jsonDatos).replace(/'/g, "''")}'::jsonb` : `'{}'::jsonb`;
            
            sql += `
INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, descripcion, precio_venta, costo_adicional, cantidad, aliases, datos)
VALUES (v_grupo_id, org_id, '${claveOpcion}', '${descEscaped}', ${price}, 0, 1, ${aliasesArray}, ${jsonStr})
ON CONFLICT (grupo_id, clave) DO UPDATE SET descripcion = EXCLUDED.descripcion, precio_venta = EXCLUDED.precio_venta, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;
`;
        }
    }
    
    order += 10;
}

sql += `
END $$;
COMMIT;
`;

fs.writeFileSync(SQL_FILE, sql, 'utf8');
console.log('Generado:', SQL_FILE);
