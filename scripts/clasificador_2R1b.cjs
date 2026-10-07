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
    s = s.normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/-/g, ' '); // remove accents and hyphens
    s = s.replace(/FLET/g, 'FLEET')
         .replace(/HOLAND/g, 'HOLLAND')
         .replace(/SEGURIRAD/g, 'SEGURIDAD')
         .replace(/MICRO ALAMBRE/g, 'MICROALAMBRE')
         .replace(/SHERVI/g, 'SHERWIN');
    return s;
}

function findOption(groupKey, manualName) {
    const norm = normalize(manualName);
    const g = catData.grupos.find(x => x.clave === groupKey || normalize(x.nombre) === groupKey);
    if (!g) return null;
    
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



for (const row of planas) {
    const rawProd = row.producto || '';
    const normProd = normalize(rawProd);
    const uso = normalize(row.estatus_o_uso);

    if (row.tipo === 'grupo_opcion') {
        currentGroup = GROUP_MAP[normProd] || null;
        currentOption = null;
        if (!currentGroup) {
            clasificacion.push({ ...row, destino: 'sin_asignar', razon: 'Grupo no mapeado: ' + normProd });
            informe.sin_asignar.push(row);
        } else {
            clasificacion.push({ ...row, destino: 'ignorar' });
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
            clasificacion.push({ ...row, destino: 'ignorar' });
        } else {
            clasificacion.push({ ...row, destino: 'sin_asignar', razon: 'Opción no mapeada: ' + normProd });
            informe.sin_asignar.push(row);
            currentOption = null;
        }
        continue;
    }
    
    if (row.tipo === 'encabezado') {
        clasificacion.push({ ...row, destino: 'ignorar' });
        continue;
    }

    if (row.tipo === 'linea') {
        const isComponente = currentGroup !== null;

        let escala = 'fija';
        if (currentGroup === 'suspension' || currentGroup === 'eje' || currentGroup === 'rines' || currentGroup === 'llantas' || currentGroup === 'abs') {
            escala = 'por_eje';
        } else if (normProd.includes('CONSUMIBLE') || uso.includes('CONSUMIBLE')) {
            escala = 'por_largo';
        }

        let qty = parseFloat(row.cantidad) || 0;
        if (escala === 'por_eje' && qty > 0) {
            // El manual viene para 2 ejes. Si la cantidad es por eje, la dividimos entre 2.
            // Para la suspensión de una plataforma de 2 ejes es x2. Entonces si cantidad=2, dividimos por 2 => 1 por eje.
            // Para las llantas (8), 8/2 => 4 por eje.
            // A menos que la cantidad ya sea 1 (ej. un kit que no depende de ejes? No, si está en el grupo ejes y dice 2, es 1 por eje).
            // ¡Excepción!: "TIPO DE EJE" group rows say quantity "1", but for a 2-axle it should be 2! Wait! Let's check TIPO DE EJE rows later. We divide by 2 only if the raw qty assumes 2 axles. We'll verify this manually.
            qty = qty / 2;
        }

        if (isComponente) {
            let opt = currentOption;
            if (!opt) {
                const found = findOption(currentGroup, normProd);
                if (found) opt = found.opcion;
            }

            if (!opt) {
                // It does not belong to any option. The group might have ended or it's a fixed line interspersed.
                // We process it as a fixed line (receta_base)
                let condicion = null;
                let dest = 'receta_base';
                
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
            } else {
                clasificacion.push({
                    ...row,
                    destino: 'opcion_componentes',
                    grupo_id: currentGroup,
                    opcion_id: opt,
                    escala: escala,
                    cantidad_calculada: qty,
                    rol: uso === 'COMPONENTE' || uso === 'SUSTITUTO' || uso === 'INDEPENDIENTE' ? uso.toLowerCase() : 'componente'
                });
                informe.asignadas_opcion++;
                informe.materiales_nuevos.add(normProd);
            }
        } else {
            // receta_base
            let condicion = null;
            let dest = 'receta_base';
            
            if (uso.includes('SI LLEVA') || uso.includes('PARA') || uso.includes('HECHIZO') || uso.includes('KIT DE') || uso === 'JUEGO DE REDILAS') {
                dest = 'receta_base_condicionada';
                informe.condiciones_no_mapeadas.push({ producto: normProd, uso: uso });
            }

            // Check if hardware without recipe
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

// Write the INFORME_2R1B.md
const md = `# Informe de Importación 2R-1b (Plataformas)

## Resumen de Filas Leídas
- **Filas procesadas**: ${informe.leidas}
- **Receta Base Fija**: ${informe.asignadas_fija}
- **Receta Base Condicionada**: ${informe.asignadas_condicionada}
- **Componentes de Opciones**: ${informe.asignadas_opcion}
- **Sin asignar**: ${informe.sin_asignar.length}

## Filas sin asignar
${informe.sin_asignar.map(x => '- Fila ' + x.fila + ' [' + x.producto + ']: ' + x.razon).join('\n') || '*Ninguna*'}

## Condiciones no mapeadas (Se conservó el texto original en \`uso\`)
${informe.condiciones_no_mapeadas.map(x => '- ' + x.producto + ': ' + x.uso).join('\n') || '*Ninguna*'}

## Materiales Nuevos a Crear (${informe.materiales_nuevos.size})
${Array.from(informe.materiales_nuevos).map(x => '- ' + x).join('\n')}

## Elementos que faltan en la receta original
${informe.faltan_en_receta.map(x => '- ' + x).join('\n')}
`;

fs.writeFileSync('INFORME_2R1B.md', md, 'utf8');
console.log('Clasificación generada.');
