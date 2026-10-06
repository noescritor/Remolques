# Análisis de Recetas BOM y Estructura de Datos

He analizado el archivo CSV exportado desde Excel. El documento está diseñado de forma muy "visual" (múltiples tablas en paralelo, cotizaciones mezcladas con despieces, y comparativas de precios). 

A continuación detallo exactamente **qué** extraeremos y **cómo** se integrará en el sistema de Remolques:

## 1. Productos Terminados (Remolques)
Se crearán (o actualizarán) en la tabla `productos` con la etiqueta `tipo_item = 'producto_terminado'`. Los modelos principales detectados son:

*   **Planas:** Plana 40 FT (2 y 3 ejes), Plana 42 FT, Plana 45 FT.
*   **Dollys:** Dolly con retráctil, Dolly sin retráctil.
*   **Góndolas:** Góndola Acero A-36, Góndola Acero Hardox 450 (con variantes de 2 y 3 ejes).
*   **Otros:** Jaula, Multimodal 40 Ft, Cama Baja 53 Ft, Porta Contenedor 40 Ft, Caja Seca.
*   **Juego de Redilas:** (Diferentes alturas: 70cm, 80cm, 90cm, 1M).

## 2. Complementos y Subensambles (Opcionales)
Estos se registrarán también en la tabla `productos` para poder agregarlos como "extras" al armar un presupuesto:
*   Concha laminada
*   Bicicletero
*   Riel con matracas (Winches)
*   Caja de herramientas / Caja Auxiliar
*   Burro
*   Plafones laterales y en estribo

## 3. Materias Primas e Insumos
Todo el material físico se registrará en `productos` con la etiqueta `tipo_item = 'materia_prima'`. Se dividen en las siguientes categorías:

*   **Acero y Chasis:** Placas (A-36, A-50, Hardox), Soleras, PTR, Canal U, IPR, Tubos.
*   **Suspensión y Ejes:** Suspensiones (Hendrickson, Fleet Master, Ampro, HJ, FCR), Ejes, Bolsas retráctiles, Amortiguadores, Cámaras de suspensión, Muelles.
*   **Frenos y Aire (Kit ABS):** Mangueras (Azul/Roja/Chamber), Conexiones (Niple, Tapón, Codo, Te, Adaptador, Manitas, Válvulas niveladoras/protectoras), Tanques de aire.
*   **Luz y Eléctrico:** Cables (Cal. 12 varios colores), Corrugados, Hembras/Machos 7 polos, Plafones (Rojos, Ámbar, Ovalados), Cinta de aislar.
*   **Pintura y Acabados:** Pintura (Shervi, PPG, Axalta), Thinner, Reductor, Transparente, Catalizador, Praimer, Lijas, Fosfato.
*   **Tornillería y Varios:** Tornillos (Grado 5, Grado 8, Allen, Coche), Tuercas (Estándar, Seguridad, Gripco), Rondanas, Perno Rey, Ganchos (Holland, Premier, Bestia), Patines, Loderas, Cintas reflejantes, Winches.

## 4. Recetas BOM (Tabla `producto_materiales`)
Esta es la integración más importante. Para cada Producto Terminado, crearemos su "receta" exacta en la base de datos vinculando las Materias Primas necesarias. Por ejemplo, para la **Plana 40 FT 2 Ejes con Retráctil**, el sistema guardará automáticamente que necesita:
*   1 Perno Rey 3/8"
*   2 Suspensiones HT300US
*   1 Sistema Retráctil
*   38 Cargadores 4x102 in
*   *X* cantidad de acero, mangueras, plafones y tornillos específicos.

## 5. Costos y Precios
*   El CSV incluye listas de precios de varios proveedores (El Benja, Ferreprecios, Promare, Aznor, Cadeco). 
*   Se actualizará el campo `costo` de cada materia prima en la base de datos utilizando el precio promedio o el precio de lista indicado en la hoja de Excel, para que al generar el presupuesto se calcule el costo real de producción.
*   *Nota:* El CSV también incluye tiempos de "Mano de Obra" (horas hombre por soldadores, pintores, etc.). Si el sistema actual no maneja costos de mano de obra por hora en la base de datos, este rubro se consideraría como un gasto indirecto o se puede sumar al costo base del producto.

---

### Siguiente paso propuesto:
Como el formato de Excel es muy "humano" (columnas combinadas y tablas paralelas), la extracción directa por código es propensa a fallos. Lo ideal es que **yo escriba un script de limpieza y migración** que procese este archivo estructurándolo en formato SQL para insertarlo limpiamente en tu base de datos Supabase.
