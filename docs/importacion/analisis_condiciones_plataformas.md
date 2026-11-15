# Análisis de Condiciones Sin Mapear en Receta de Plataformas

**Fecha:** 2026-11-14  
**Referencia:** Hoja `MAPEAR_CONDICIONES` de `PLATAFORMAS_AJUSTES_DESPIECE_2026-11-14.xlsx`  
**Autor:** Antigravity (revisión por Claude)

---

## 1. Alcance y Líneas Analizadas

En la base de datos actual (`receta_base`), existen exactamente **10 líneas por modelo de plataforma** (100 renglones en total entre los 10 modelos) que poseen condiciones textuales heredadas de los archivos Excel originales de Leolca (`condicion = {"sin_mapear": "..."}`):

| # | Paso | Material | Cantidad | Condición Textual (`sin_mapear`) | Opción Destino Teórica |
|---|------|----------|---------:|----------------------------------|------------------------|
| 1 | `LUZ` | `CABLE NEGRO CAL,12` | 25.80 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 2 | `LUZ` | `CORRUGADO 1/4` | 22.80 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 3 | `LUZ` | `CORRUGADO 3/8` | 3.00 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 4 | `LUZ` | `TERMINAL 3/16` | 36.00 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 5 | `LUZ` | `TORNILLO 1/8 X 1 1/4` | 72.00 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 6 | `LUZ` | `TUERCA ESTANDAR 1/8` | 72.00 | `SI LLEVA LATERALES Y ESTRIBO` | Plafones de carrito |
| 7 | `LUZ` | `PLAFON DE CARRITO AMBAR` | 20.00 | `LATERALES` | Opciones Ámbar/Rojos laterales |
| 8 | `LUZ` | `PLAFON DE CARRITO ROJO` | 16.00 | `ESTRIBO` | Opciones Rojos/Ámbar estribo |
| 9 | `EXTRAS` | `CANDADO PARA PLANA` | 12.00 | `SI ES MULTIMODAL O PORTA CONTENEDOR` | Adicionales / Multimodal |
| 10 | `EXTRAS` | `CARGADO 3 X 102 IN` | 8.00 | `SI ES MULTIMODAL O PORTA CONTENEDOR` | Adicionales / Multimodal |

---

## 2. Comportamiento Medido en el Motor (`resolver_receta.ts`)

Se auditó la función pura `resolverReceta` (`supabase/functions/make-server-feea4382/motor/resolver_receta.ts`, líneas 82–87):

```typescript
const evaluarCondicion = (condicion: any, lineaNombre: string, lineaCantidad: number, lineaUso: string | null): boolean => {
  if (!condicion) return true;
  if (condicion.sin_mapear) {
    omitidas.push({ 
      descripcion: `Condición sin mapear: ${condicion.sin_mapear}`, 
      texto: `${lineaNombre} (x${lineaCantidad}) - Uso: ${lineaUso || ''}` 
    });
    return false;
  }
  // ...
};
```

### Hallazgo técnico:
1. **¿Incluye siempre o nunca?**: El motor evalúa `sin_mapear` devolviendo **`false`** de manera estricta (**NUNCA se incluyen** en la lista resuelta `lineas`).
2. **Registro en `omitidas`**: En cada corrida del despiece, el motor inserta una entrada en el arreglo `omitidas` advirtiendo que la línea fue excluida por tener condición pendiente de mapeo.
3. **Efecto en Almacén / Orden de Trabajo (OT)**:
   - Al no formar parte de `res.lineas`, estas 10 líneas **no se imprimen como vales de material en la OT** ni se solicitan automáticamente al almacén.
   - Si un remolque se fabrica con multimodal o plafones, el personal de planta actualmente debe abastecer estos insumos de forma manual o fuera de sistema.
4. **Efecto en Precios y Costeo**:
   - **$0.00 (Nulo)**. Las 10 líneas tienen `seccion IS NULL` en `receta_base`. El motor de costeo solo acumula líneas de `seccion = 'acero'`, por lo que la inclusión u omisión de estas líneas no altera el precio sugerido ni el costo total en ninguna cotización.

---

## 3. Factibilidad de Mapeo contra la Configuración Actual

El prompt instruye:
> *"Si el campo de la opción no existe en la configuración, no lo inventes: déjalo como está y repórtalo."*

Se revisó la estructura de `configuracion.grupos` tanto en la base de datos (`grupos_configuracion`) como en el frontend (`ConfiguradorEquipo.tsx`):

### A. Grupo `adicionales` (Candados y Cargadores Multimodal):
- En `grupos_configuracion`, el grupo `adicionales` está definido como `seleccion = 'multiple_con_cantidad'`.
- En `ConfiguradorEquipo.tsx` (líneas 306–313), las opciones seleccionadas se guardan como un **arreglo de objetos**:
  ```typescript
  configuracion.grupos['adicionales'] = [
    { opcion: 'multimodal', cantidad: 1 },
    { opcion: 'bicicletera', cantidad: 1 }
  ];
  ```
- El evaluador de condiciones de `resolver_receta.ts` (línea 96–97) evalúa los campos asumiendo una cadena o un objeto escalar:
  ```typescript
  const valConfigRaw = configuracion.grupos[cond.campo];
  valConfig = typeof valConfigRaw === 'string' ? valConfigRaw : ((valConfigRaw as any)?.opcion || '');
  ```
  Al ser `valConfigRaw` un arreglo, `typeof valConfigRaw === 'string'` es `false` y `valConfigRaw.opcion` es `undefined`. En consecuencia, `valConfig` evalúa a `''`.
- Si se hubiera mapeado `{"campo": "adicionales", "op": "==", "valor": "multimodal"}`, la condición **nunca se cumpliría** (fallaría silenciosamente incluso cuando el usuario selecciona Multimodal).

### B. Grupo `plafones` (Plafones de carrito, cables, corrugados y tornillería):
- En `grupos_configuracion`, `plafones` tiene `seleccion = 'cantidad'` con 4 claves: `ambar_estribo`, `ambar_laterales`, `rojo_estribo`, `rojo_laterales`.
- No existe una opción `ninguna`, ni un selector booleano `laterales` o `estribo`.
- En cotizaciones estándar, `configuracion.grupos['plafones']` no está presente (`undefined`).
- Mapear condiciones hacia `plafones` requeriría inventar un campo intermedio no soportado por el motor ni por el configurador actual.

---

## 4. Decisión Técnica Aplicada

En estricto cumplimiento de la regla:
> *"Si el campo de la opción no existe en la configuración, no lo inventes: déjalo como está y repórtalo."*

1. **Se mantienen las 10 líneas de `receta_base` con su condición `{"sin_mapear": "..."}` intacta.**
2. No se alteró `resolver_receta.ts` ni se agregaron campos ficticios al esquema de configuración.
3. Se garantizó compatibilidad total con la suite de pruebas (Deno 334/334, verificación 11/11).

---

## 5. Recomendación para Siguiente Ronda

Para cuando Luis y Leolca decidan activar el despiece de estos accesorios:

1. **Para Candados y Cargadores Multimodal (Paso EXTRAS):**
   - La arquitectura correcta no es una condición en `receta_base`, sino dar de alta ambos materiales en `opcion_componentes` de la opción `Multimodal` (`opcion_id = '2886d9f6-dbca-4386-bfc6-0cfe6cbac81d'`):
     - `CANDADO PARA PLANA`: cantidad 12, escala 'fija', paso 'EXTRAS', uso 'Multimodal', seccion NULL.
     - `CARGADO 3 X 102 IN`: cantidad 8, escala 'fija', paso 'EXTRAS', uso 'Multimodal', seccion NULL.
   - El motor ya resuelve automáticamente `opcion_componentes` para grupos de tipo `multiple_con_cantidad`, por lo que al elegir Multimodal se agregarían limpiamente a la OT sin tocar `receta_base`.
2. **Para Plafones de carrito (Paso LUZ):**
   - Solicitar a Leolca la aclaración pendiente:
     - ¿Cuáles modelos llevan ámbar lateral y cuáles rojo?
     - ¿El cableado y corrugados (25.8 m cable, 22.8 m corrugado 1/4, 3 m corrugado 3/8) se consumen siempre que haya plafones de carrito, o cambian según la cantidad de plafones?
   - Con esa definición, modelar los cables y plafones directamente como `opcion_componentes` en las 4 opciones de plafones.
