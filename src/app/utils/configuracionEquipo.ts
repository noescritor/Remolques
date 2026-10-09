export function obtenerConfiguracion(item: any): any {
    if (!item) return undefined;
    return item.configuracion ?? item.metadata?.configuracion;
}

export function normalizarResumenLineas(lineas: any): Array<{etiqueta: string, valor: string}> {
    if (!lineas || !Array.isArray(lineas)) return [];
    
    return lineas.map(linea => {
        if (typeof linea === 'string') {
            const idx = linea.indexOf(':');
            if (idx === -1) {
                return { etiqueta: linea.trim(), valor: '' };
            }
            return { 
                etiqueta: linea.substring(0, idx).trim(), 
                valor: linea.substring(idx + 1).trim() 
            };
        }
        
        if (typeof linea === 'object' && linea !== null) {
            // Check if it's the expected object
            if (linea.etiqueta !== undefined || linea.valor !== undefined) {
                return { 
                    etiqueta: linea.etiqueta ? String(linea.etiqueta).trim() : '', 
                    valor: linea.valor ? String(linea.valor).trim() : '' 
                };
            }
        }
        
        return null;
    }).filter((item): item is {etiqueta: string, valor: string} => item !== null);
}
