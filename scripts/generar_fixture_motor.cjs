const fs = require('fs');

const clasificacion = require('../docs/importacion/clasificacion_2R1b.json');
const catalogo = require('../docs/catalogo-opciones/catalogo_opciones_unificado.json');

const uuid = (str) => {
    let hash = 0;
    for (let i = 0; i < str.length; i++) {
        hash = str.charCodeAt(i) + ((hash << 5) - hash);
    }
    const hex = (hash >>> 0).toString(16).padStart(8, '0');
    return `${hex}-0000-0000-0000-000000000000`;
};

const modelo = {
    id: uuid('PLATAFORMA 2 40 FT'),
    tipo: 'plataforma',
    largo_ft: 40,
    num_ejes: 2,
    nombre: 'PLATAFORMA 2 40 FT'
};

function normalize(str) {
    if(!str) return '';
    let s = str.toString().toUpperCase().trim().replace(/\s+/g, ' ');
    s = s.normalize("NFD").replace(/[\u0300-\u036f]/g, ""); // remove accents
    s = s.replace(/FLET/g, 'FLEET')
         .replace(/AUMINIO/g, 'ALUMINIO')
         .replace(/HOLAND/g, 'HOLLAND')
         .replace(/SEGURIRAD/g, 'SEGURIDAD')
         .replace(/MICRO ALAMBRE/g, 'MICROALAMBRE')
         .replace(/SHERVI/g, 'SHERWIN-WILLIAMS');
    s = s.replace(/([0-9\/]+)\s*X\s*([0-9\/]+)/g, '$1 X $2');
    return s.trim().replace(/\s+/g, ' ');
}

const materialesMap = new Map();

function getMaterial(rawNombre, unidad_sugerida) {
    const nombre = normalize(rawNombre);
    if (!materialesMap.has(nombre)) {
        materialesMap.set(nombre, {
            id: uuid('MAT_' + nombre),
            nombre: nombre,
            unidad: unidad_sugerida || 'PZA',
            costo: 0,
            descripcion: 'SIN PRECIO'
        });
    }
    return materialesMap.get(nombre);
}

const gruposMap = new Map();
const grupos = [];
const opciones = [];

for (const g of catalogo.grupos) {
    const gId = uuid('GRP_' + g.clave);
    gruposMap.set(g.clave, gId);
    grupos.push({
        id: gId,
        clave: g.clave,
        nombre: g.nombre,
        seleccion: g.seleccion || g.tipo || 'unica', // fallback
        regla: g.regla || null,
        aplica_a: g.aplica_a || null,
        depende_de: g.depende_de || null,
        cantidad: g.cantidad || null,
        unidad_precio: g.unidad_precio || null,
        medidas: g.medidas || null
    });

    for (const o of g.opciones) {
        opciones.push({
            id: uuid('OPT_' + g.clave + '_' + o.clave),
            grupo_id: gId,
            clave: o.clave,
            nombre: o.nombre,
            precio_venta: o.precio_venta || 0,
            clase: o.clase || '',
            marcas: o.marcas || null,
            medidas: o.medidas || null,
            activo: o.activo !== false,
            aliases: o.aliases || null
        });
    }
}

const receta_base = [];
const opcion_componentes = [];

for (const row of clasificacion) {
    if (row.destino === 'ignorar') continue;

    const mat = getMaterial(row.producto, row.unidad_sugerida);

    if (row.destino === 'receta_base' || row.destino === 'receta_base_condicionada') {
        receta_base.push({
            material_id: mat.id,
            nombre: mat.nombre,
            unidad: mat.unidad,
            costo: mat.costo,
            descripcion: mat.descripcion,
            cantidad: row.cantidad_calculada || row.cantidad,
            escala: row.escala,
            paso: row.proceso,
            uso: row.uso,
            condicion: row.condicion || null
        });
    } else if (row.destino === 'opcion_componentes') {
        const optId = uuid('OPT_' + row.grupo_id + '_' + row.opcion_id);
        opcion_componentes.push({
            opcion_id: optId,
            grupo_clave: row.grupo_id, // For easier debugging
            opcion_clave: row.opcion_id,
            material_id: mat.id,
            nombre: mat.nombre,
            unidad: mat.unidad,
            costo: mat.costo,
            descripcion: mat.descripcion,
            cantidad: row.cantidad_calculada || row.cantidad,
            escala: row.escala,
            paso: row.proceso,
            rol: row.rol,
            uso: row.uso
        });
    }
}

const fixture = {
    modelo,
    receta_base,
    grupos,
    opciones,
    opcion_componentes
};

fs.writeFileSync('supabase/functions/make-server-feea4382/motor/fixtures/datos_modelo.json', JSON.stringify(fixture, null, 2));
console.log('Fixture generada con', receta_base.length, 'lineas base y', opcion_componentes.length, 'componentes opcionales');
