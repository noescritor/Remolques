const fs = require('fs');

const raw = fs.readFileSync('docs/catalogo-opciones/catalogo_opciones_unificado.json', 'utf8');
const data = JSON.parse(raw);

const SQL_FILE = 'supabase/migrations/20261007_02_catalogo_opciones.sql';

let sql = `BEGIN;

DO $$ 
DECLARE 
    -- org_id se fija manual debido a que este bloque es exclusivo para el cliente actual.
    -- Cuando sea multitenant esto deberá ser parametrizado.
    org_id uuid := '00000000-0000-0000-0000-000000000001';
    v_grupo_id uuid;
    v_count int;
    v_total_modelos int := 0;
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
        // Parse variant string: e.g. "35 ft x2" -> 35, 2
        const matchLargo = v.match(/(\d+)\s*ft/i);
        const matchEjes = v.match(/x(\d)/i);
        
        let regex = "";
        let largoFt = "NULL";
        let numEjes = "NULL";

        if (matchLargo && matchEjes) {
            largoFt = matchLargo[1];
            numEjes = matchEjes[1];
            regex = `^PLATAFORMA +${numEjes} +${largoFt} *FT *$`;
        } else {
            regex = `^${v.toUpperCase()} *$`;
        }

        sql += `
SELECT count(*) INTO v_count FROM productos 
WHERE nombre ~* '${regex}' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id;

IF v_count <> 1 THEN
    RAISE EXCEPTION 'La variante "${v}" (regex: %) devolvió % productos en lugar de 1', '${regex}', v_count;
END IF;

INSERT INTO modelos (organizacion_id, producto_id, tipo, largo_ft, num_ejes)
SELECT org_id, id, 'plataforma', ${largoFt}, ${numEjes}
FROM productos 
WHERE nombre ~* '${regex}' AND tipo_item = 'producto_terminado' AND organizacion_id = org_id
ON CONFLICT (organizacion_id, producto_id) DO UPDATE SET 
    tipo = EXCLUDED.tipo, largo_ft = EXCLUDED.largo_ft, num_ejes = EXCLUDED.num_ejes;

v_total_modelos := v_total_modelos + 1;
`;
    });
}

sql += `
IF v_total_modelos <> 10 THEN
    RAISE EXCEPTION 'Se insertaron % modelos en lugar de los 10 esperados', v_total_modelos;
END IF;

-- 3. GRUPOS Y OPCIONES
`;

let order = 10;
for (const grupo of data.grupos) {
    const seleccion = grupo.seleccion ? `'${grupo.seleccion}'` : "'unica'";
    const groupNameEscaped = grupo.nombre.replace(/'/g, "''");
    const claveGrupo = grupo.clave.replace(/'/g, "''");
    
    // Group fields mapping
    let aplica_a = 'NULL';
    if (grupo.aplica) {
        const arr = (Array.isArray(grupo.aplica) ? grupo.aplica : [grupo.aplica]);
        aplica_a = `ARRAY[${arr.map(a => `'${a.replace(/'/g, "''")}'`).join(',')}]::text[]`;
    }
    
    const notasGrupo = grupo.notas ? `'${grupo.notas.replace(/'/g, "''")}'` : 'NULL';
    const unidadPrecio = grupo.unidad_precio ? `'${grupo.unidad_precio.replace(/'/g, "''")}'` : 'NULL';
    const cantidadStr = grupo.cantidad ? `'${grupo.cantidad.replace(/'/g, "''")}'` : 'NULL';
    const reglaJson = grupo.regla ? `'{"texto": "${grupo.regla.replace(/"/g, '\\\\\"').replace(/'/g, "''")}"}'::jsonb` : 'NULL';
    const medidasGrupo = grupo.medidas ? `'${JSON.stringify(grupo.medidas).replace(/'/g, "''")}'::jsonb` : 'NULL';

    sql += `
-- Grupo: ${groupNameEscaped}
INSERT INTO grupos_configuracion (organizacion_id, clave, nombre, seleccion, aplica_a, regla, notas, unidad_precio, cantidad, medidas, orden)
VALUES (org_id, '${claveGrupo}', '${groupNameEscaped}', ${seleccion}, ${aplica_a}, ${reglaJson}, ${notasGrupo}, ${unidadPrecio}, ${cantidadStr}, ${medidasGrupo}, ${order})
ON CONFLICT (organizacion_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, seleccion = EXCLUDED.seleccion, aplica_a = EXCLUDED.aplica_a, regla = EXCLUDED.regla, notas = EXCLUDED.notas, unidad_precio = EXCLUDED.unidad_precio, cantidad = EXCLUDED.cantidad, medidas = EXCLUDED.medidas, orden = EXCLUDED.orden
RETURNING id INTO v_grupo_id;
`;

    if (grupo.opciones) {
        for (const opcion of grupo.opciones) {
            const descEscaped = opcion.nombre.replace(/'/g, "''");
            const claveOpcion = (opcion.clave || opcion.nombre).replace(/'/g, "''");
            const price = opcion.precio === "sin_precio" || opcion.precio === null ? 'NULL' : parseFloat(opcion.precio) || 'NULL';
            
            let aliasesArray = 'NULL';
            if (opcion.aliases && opcion.aliases.length > 0) {
                const escapedAliases = opcion.aliases.map(a => `'${a.replace(/'/g, "''")}'`).join(', ');
                aliasesArray = `ARRAY[${escapedAliases}]::text[]`;
            }

            const medidasOpcion = opcion.medidas ? `'${JSON.stringify(opcion.medidas).replace(/'/g, "''")}'::jsonb` : 'NULL';
            const clase = opcion.clase ? `'${opcion.clase.replace(/'/g, "''")}'` : 'NULL';
            const notasOpcion = opcion.notas ? `'${opcion.notas.replace(/'/g, "''")}'` : 'NULL';
            const precioFuente = opcion.precio_fuente ? `'${opcion.precio_fuente.replace(/'/g, "''")}'` : 'NULL';
            const otrosPrecios = opcion.otros_precios ? `'${JSON.stringify(opcion.otros_precios).replace(/'/g, "''")}'::jsonb` : 'NULL';
            const proveedor = opcion.proveedor ? `'${opcion.proveedor.replace(/'/g, "''")}'` : 'NULL';
            
            let marcasArray = 'NULL';
            if (opcion.marcas && opcion.marcas.length > 0) {
                const escaped = opcion.marcas.map(a => `'${a.replace(/'/g, "''")}'`).join(', ');
                marcasArray = `ARRAY[${escaped}]::text[]`;
            }

            // Put any other unmatched fields in 'datos'
            const extras = {};
            for (const key of Object.keys(opcion)) {
                if (!['clave', 'nombre', 'precio', 'aliases', 'medidas', 'clase', 'notas', 'precio_fuente', 'otros_precios', 'proveedor', 'marcas'].includes(key)) {
                    extras[key] = opcion[key];
                }
            }
            const datosJson = Object.keys(extras).length > 0 ? `'${JSON.stringify(extras).replace(/'/g, "''")}'::jsonb` : `'{}'::jsonb`;

            sql += `
INSERT INTO opciones_configuracion (grupo_id, organizacion_id, clave, nombre, precio_venta, medidas, clase, notas, precio_fuente, otros_precios, marcas, proveedor, aliases, datos)
VALUES (v_grupo_id, org_id, '${claveOpcion}', '${descEscaped}', ${price}, ${medidasOpcion}, ${clase}, ${notasOpcion}, ${precioFuente}, ${otrosPrecios}, ${marcasArray}, ${proveedor}, ${aliasesArray}, ${datosJson})
ON CONFLICT (grupo_id, clave) DO UPDATE SET 
    nombre = EXCLUDED.nombre, precio_venta = EXCLUDED.precio_venta, medidas = EXCLUDED.medidas, clase = EXCLUDED.clase, notas = EXCLUDED.notas, precio_fuente = EXCLUDED.precio_fuente, otros_precios = EXCLUDED.otros_precios, marcas = EXCLUDED.marcas, proveedor = EXCLUDED.proveedor, aliases = EXCLUDED.aliases, datos = EXCLUDED.datos;
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
