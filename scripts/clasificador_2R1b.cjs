const fs = require('fs');

const manualData = require('../docs/manual-recetas/lineas_parseadas.json');
const catData = require('../docs/catalogo-opciones/catalogo_opciones_unificado.json');

const planas = manualData.filter(d => d.hoja === 'PLANA');

const clasificacion = [];
const informe = {
    leidas: planas.length,
    asignadas_fija: 0,
    asignadas_opcion: 0,
    asignadas_condicionada: 0,
    sin_asignar: [],
    ignoradas: [],
    condiciones_no_mapeadas: [],
    materiales_nuevos: new Set(),
    materiales_existentes: new Set(),
    faltan_en_receta: []
};

let currentGroup = null;
let currentOption = null;

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
    // Normalize X spacing in dimensions, e.g., 3/4X3 -> 3/4 X 3
    s = s.replace(/([0-9\/]+)\s*X\s*([0-9\/]+)/g, '$1 X $2');
    return s.trim().replace(/\s+/g, ' ');
}

function findOption(groupKey, manualName) {
    const norm = normalize(manualName);
    const g = catData.grupos.find(x => x.clave === groupKey || normalize(x.nombre) === groupKey);
    if (!g) return null;
    
    // Explicit mappings to fix errors
    if (groupKey === 'suspension') {
        if (norm.includes('ALTA')) {
            if (norm.includes('HENDRICKSON')) return { grupo: g.clave, opcion: 'alta_hendrickson' };
            if (norm.includes('FLEET MASTER') || norm.includes('FLEET')) return { grupo: g.clave, opcion: 'alta_fleet_master' };
            if (norm.includes('HJ')) return { grupo: g.clave, opcion: 'alta_hj' };
        } else if (norm.includes('NORMAL')) {
            if (norm.includes('HENDRICKSON')) return { grupo: g.clave, opcion: 'hendrickson' };
            if (norm.includes('FLEET MASTER') || norm.includes('FLEET')) return { grupo: g.clave, opcion: 'fleet_master' };
            if (norm.includes('AMPRO')) return { grupo: g.clave, opcion: 'ampro' };
            if (norm.includes('FCR')) return { grupo: g.clave, opcion: 'fcr' };
        }
    }

    if (groupKey === 'retractil') {
        if (norm.includes('CHICA') || norm.includes('CHICO')) return { grupo: g.clave, opcion: 'chico' };
        if (norm.includes('GRANDE')) return { grupo: g.clave, opcion: 'grande' };
        if (norm.includes('PREP')) return { grupo: g.clave, opcion: 'preparacion' };
    }

    if (groupKey === 'rines') {
        if (norm.includes('ALUMINIO')) return { grupo: g.clave, opcion: 'aluminio' };
        if (norm.includes('ACERO')) return { grupo: g.clave, opcion: 'acero' };
    }

    // Exact name match or alias match
    for (const opt of g.opciones) {
        if (normalize(opt.nombre) === norm || normalize(opt.clave) === norm) return { grupo: g.clave, opcion: opt.clave };
        if (opt.aliases) {
            for (const alias of opt.aliases) {
                if (normalize(alias) === norm) return { grupo: g.clave, opcion: opt.clave };
            }
        }
    }
    
    // Fuzzy matching
    for (const opt of g.opciones) {
        if (norm.includes(normalize(opt.nombre))) return { grupo: g.clave, opcion: opt.clave };
        if (norm.includes(normalize(opt.clave))) return { grupo: g.clave, opcion: opt.clave };
        if (opt.aliases) {
            for (const alias of opt.aliases) {
                if (norm.includes(normalize(alias))) return { grupo: g.clave, opcion: opt.clave };
            }
        }
    }
    return null;
}

const GROUP_MAP = {
    'TIPO DE SUSPENSION': 'suspension',
    'TIPO DE PATIN': 'patin',
    'TIPO DE EJE': 'eje',
    'TIPO DE GANCHO': 'gancho',
    'TIPO DE BOLSA RETRACTIL': 'retractil',
    'TIPO DE RINES 24,5 Y 22,5': 'rines',
    'TIPO DE LLANTAS 24,5 Y 22,5': 'llantas',
    'TIPO DE SISTEMA RETRACTIL': 'retractil',
    'TIPO DE PINTURA': 'pintura'
};



let lastProceso = null;
let lastFila = null;

for (const row of planas) {
    const rawProd = row.producto || '';
    const normProd = normalize(rawProd);
    const uso = normalize(row.estatus_o_uso);

    if (row.proceso !== lastProceso && lastProceso !== null) {
        currentGroup = null;
        currentOption = null;
    }
    lastProceso = row.proceso;

    // Detect empty rows that were skipped by the parser
    if (lastFila !== null && row.fila > lastFila + 1) {
        currentGroup = null;
        currentOption = null;
    }
    lastFila = row.fila;

    if (!rawProd || row.tipo === 'blanco' || rawProd.trim() === '') {
        currentGroup = null;
        currentOption = null;
        clasificacion.push({ ...row, destino: 'ignorar', razon: 'Fila en blanco' });
        informe.ignoradas.push({ ...row, razon: 'Fila en blanco' });
        continue;
    }

    if (/^\d+$/.test(normProd)) {
        clasificacion.push({ ...row, destino: 'ignorar', razon: 'Fila informativa con solo cantidad' });
        informe.ignoradas.push({ ...row, razon: 'Fila informativa con solo cantidad' });
        continue;
    }

    if (row.tipo === 'grupo_opcion') {
        currentGroup = GROUP_MAP[normProd] || null;
        currentOption = null;
        if (!currentGroup) {
            clasificacion.push({ ...row, destino: 'sin_asignar', razon: 'Grupo no mapeado: ' + normProd });
            informe.sin_asignar.push(row);
        } else {
            clasificacion.push({ ...row, destino: 'ignorar', razon: 'Encabezado de grupo válido' });
            informe.ignoradas.push({ ...row, razon: 'Encabezado de grupo válido' });
        }
        continue;
    }

    if (row.tipo === 'opcion_suspension' || row.tipo === 'opcion_pintura') {
        if (!currentGroup) {
            if (row.tipo === 'opcion_suspension') currentGroup = 'suspension';
            if (row.tipo === 'opcion_pintura') currentGroup = 'pintura_chasis';
        }
        const opt = findOption(currentGroup, normProd);
        if (opt) {
            currentOption = opt.opcion;
            clasificacion.push({ ...row, destino: 'ignorar', razon: 'Encabezado de opción válida' });
            informe.ignoradas.push({ ...row, razon: 'Encabezado de opción válida' });
        } else {
            clasificacion.push({ ...row, destino: 'sin_asignar', razon: 'Opción no mapeada: ' + normProd });
            informe.sin_asignar.push(row);
            currentOption = null;
        }
        continue;
    }
    
    if (row.tipo === 'encabezado') {
        clasificacion.push({ ...row, destino: 'ignorar', razon: 'Encabezado de sección' });
        informe.ignoradas.push({ ...row, razon: 'Encabezado de sección' });
        continue;
    }

    if (row.tipo === 'linea') {
        let escala = 'fija';
        if (currentGroup === 'suspension' || currentGroup === 'eje' || currentGroup === 'rines' || currentGroup === 'llantas' || currentGroup === 'abs') {
            escala = 'por_eje';
        } else if (normProd.includes('CONSUMIBLE') || uso.includes('CONSUMIBLE')) {
            escala = 'por_largo';
        }

        let qty = parseFloat(row.cantidad) || 0;
        if (escala === 'por_eje' && qty > 0) {
            qty = qty / 2;
        }

        let dest = null;
        let finalOpt = null;
        let finalGroup = null;

        // Route specific 'uso' directly to their option components
        if (uso.includes('RETRACTIL CHICO') || uso.includes('RETRACTIL CHICA')) {
            dest = 'opcion_componentes';
            finalGroup = 'retractil';
            finalOpt = 'chico';
        } else if (uso.includes('RETRACTIL GRANDE') || uso.includes('RETRACTIL G')) {
            dest = 'opcion_componentes';
            finalGroup = 'retractil';
            finalOpt = 'grande';
        }

        if (!dest && currentGroup !== null) {
            let opt = currentOption;
            if (!opt) {
                const found = findOption(currentGroup, normProd);
                if (found) opt = found.opcion;
            }
            if (opt) {
                dest = 'opcion_componentes';
                finalGroup = currentGroup;
                finalOpt = opt;
            }
        }

        if (dest === 'opcion_componentes') {
            clasificacion.push({
                ...row,
                destino: dest,
                grupo_id: finalGroup,
                opcion_id: finalOpt,
                escala: escala,
                cantidad_calculada: qty,
                rol: uso === 'COMPONENTE' || uso === 'SUSTITUTO' || uso === 'INDEPENDIENTE' ? uso.toLowerCase() : 'componente'
            });
            informe.asignadas_opcion++;
            informe.materiales_nuevos.add(normProd);
        } else {
            // receta_base
            dest = 'receta_base';
            
            if (uso.includes('SI LLEVA') || uso.includes('PARA') || uso.includes('HECHIZO') || uso.includes('KIT DE') || uso === 'JUEGO DE REDILAS') {
                dest = 'receta_base_condicionada';
                informe.condiciones_no_mapeadas.push({ producto: normProd, uso: uso });
            }

            if (uso.includes('TORNILLERIA DE') || normProd.includes('BICICLETERO') || normProd.includes('CAJA AUXILIAR') || normProd.includes('MANIVELA') || normProd.includes('TAPA DE CHAMBER') || normProd.includes('KIT C/TORNILLO')) {
                informe.faltan_en_receta.push(normProd);
            }

            clasificacion.push({
                ...row,
                destino: dest,
                escala: escala,
                cantidad_calculada: qty,
                uso: uso || null
            });
            if (dest === 'receta_base') informe.asignadas_fija++;
            else informe.asignadas_condicionada++;
            informe.materiales_nuevos.add(normProd);
        }
    }
}

// Write the classification JSON
fs.writeFileSync('docs/importacion/clasificacion_2R1b.json', JSON.stringify(clasificacion, null, 2), 'utf8');

// Autocontrol: Check mixed processes in options
const optionProcesses = {};
let autocontrolFailed = false;
for (const row of clasificacion) {
    if (row.destino === 'opcion_componentes') {
        const key = `${row.grupo_id}/${row.opcion_id}`;
        if (!optionProcesses[key]) optionProcesses[key] = new Set();
        optionProcesses[key].add(row.proceso);
    }
}
for (const [key, procesos] of Object.entries(optionProcesses)) {
    if (procesos.size > 1) {
        if (!key.startsWith('suspension/') && !key.startsWith('retractil/')) {
            console.error(`AUTOCONTROL FALLÓ: La opción ${key} mezcla procesos: ${Array.from(procesos).join(', ')}`);
            autocontrolFailed = true;
        }
    }
}
if (autocontrolFailed) {
    process.exit(1);
}

// Build Receta por destino section
let recetaDestinoMd = '## Receta por destino\n\n';

// Group receta_base by paso
const recetaBaseByPaso = {};
for (const row of clasificacion) {
    if (row.destino === 'receta_base' || row.destino === 'receta_base_condicionada') {
        const paso = row.proceso || 'PASO 1';
        if (!recetaBaseByPaso[paso]) recetaBaseByPaso[paso] = [];
        recetaBaseByPaso[paso].push(row);
    }
}
recetaDestinoMd += `### Receta Base Fija\n`;
for (const paso of Object.keys(recetaBaseByPaso).sort()) {
    recetaDestinoMd += `\n**${paso}**\n`;
    for (const row of recetaBaseByPaso[paso]) {
        recetaDestinoMd += `- Fila ${row.fila}: ${row.producto} (Cant: ${row.cantidad_calculada}, Escala: ${row.escala})\n`;
    }
}

// Group opcion_componentes by option
const opcionComponentesByOpt = {};
for (const row of clasificacion) {
    if (row.destino === 'opcion_componentes') {
        const key = `${row.grupo_id}/${row.opcion_id}`;
        if (!opcionComponentesByOpt[key]) opcionComponentesByOpt[key] = [];
        opcionComponentesByOpt[key].push(row);
    }
}
recetaDestinoMd += `\n### Opciones\n`;
for (const key of Object.keys(opcionComponentesByOpt).sort()) {
    recetaDestinoMd += `\n**${key}**\n`;
    for (const row of opcionComponentesByOpt[key]) {
        recetaDestinoMd += `- Fila ${row.fila}: ${row.producto} (Cant: ${row.cantidad_calculada}, Escala: ${row.escala}, Rol: ${row.rol})\n`;
    }
}

// Write the INFORME_2R1B.md
const md = `# Informe de Importación 2R-1b (Plataformas)

## Resumen de Filas Leídas
- **Filas procesadas**: ${informe.leidas}
- **Receta Base Fija**: ${informe.asignadas_fija}
- **Receta Base Condicionada**: ${informe.asignadas_condicionada}
- **Componentes de Opciones**: ${informe.asignadas_opcion}
- **Sin asignar**: ${informe.sin_asignar.length}

${recetaDestinoMd}

## Filas sin asignar
${informe.sin_asignar.map(x => '- Fila ' + x.fila + ' [' + x.producto + ']: ' + x.razon).join('\n') || '*Ninguna*'}

## Filas ignoradas (${informe.ignoradas.length})
${informe.ignoradas.map(x => '- Fila ' + x.fila + ' [' + x.producto + ']: ' + x.razon).join('\n') || '*Ninguna*'}

## Condiciones no mapeadas (Se conservó el texto original en \`uso\`)
${informe.condiciones_no_mapeadas.map(x => '- ' + x.producto + ': ' + x.uso).join('\n') || '*Ninguna*'}

## Materiales Nuevos a Crear (${informe.materiales_nuevos.size})
${Array.from(informe.materiales_nuevos).map(x => '- ' + x).join('\n')}

## Elementos que faltan en la receta original
${informe.faltan_en_receta.map(x => '- ' + x).join('\n')}
`;

fs.writeFileSync('docs/importacion/INFORME_2R1B.md', md, 'utf8');
console.log('Clasificación generada.');
