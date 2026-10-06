# Propuesta de Diseño de Sistemas y UX (Remolques)

## 1. El Problema: El "Salto" Mental desde Excel
Los operadores vienen de un mundo donde **todo está en una sola pantalla infinita**. Si quieren ver el precio de venta y el costo del acero, solo giran la rueda del ratón. 

En nuestro sistema actual, el flujo está dividido (Cotizaciones por un lado, Presupuestos por otro, Productos por otro). Para un usuario joven esto tiene sentido lógico (bases de datos relacionales), pero para un usuario mayor, **cambiar de pantalla rompe su concentración y les hace sentir que "perdieron" la información.**

## 2. Principios de UX para Operadores Senior
Para que el sistema sea intuitivo y no genere rechazo tecnológico, debemos aplicar estas reglas:

*   **Fuera los menús ocultos:** Nada de "tres puntitos" (kebab menus) para acciones críticas. Los botones deben ser grandes, tener iconos claros y texto explícito (ej. `[📄 Generar Presupuesto]`, no solo un icono de engranaje).
*   **Feedback Permanente:** Los mensajes emergentes (Toasts) desaparecen muy rápido. Si algo se guardó, la pantalla debe indicarlo permanentemente con una etiqueta verde de `Guardado` o `Sincronizado`.
*   **Idioma de Taller, no de Software:** En lugar de "Items del Presupuesto", usar "Lista de Materiales" o "Receta de Producción". 
*   **Evitar el "Síndrome de la Pantalla en Blanco":** Nunca mostrar una tabla vacía. Siempre debe haber un botón gigante en el centro que diga "Crear nueva cotización" con una flecha.

## 3. Propuesta de Arquitectura: El "Expediente del Remolque"
En lugar de tener el módulo de *Cotizaciones* completamente divorciado del módulo de *Presupuestos*, debemos crear un concepto unificado llamado **"Expediente"**.

**El Flujo Ideal en UX:**
1.  El vendedor crea la **Cotización** (Precio de Venta).
2.  Al guardar, la misma pantalla le muestra un panel lateral o una pestaña inferior que dice **"Costos de Producción (Presupuesto)"**.
3.  Con un solo clic en *“Calcular Materiales”*, el sistema jala la receta y rellena la tabla ahí mismo.
4.  El usuario ve en la **misma pantalla**: "Lo voy a vender en $500,000 y me va a costar $320,000 fabricarlo". 
*(Esto replica la sensación de control que tenían en Excel, pero automatizado).*

## 4. Estructuración Visual de las Recetas (BOM)
El Excel que me pasaste está dividido lógicamente en la mente del operador. Tienen secciones claras: *Chasis, Suspensión, Aire, Luz, Pintura*.

Actualmente, si listamos 150 materiales en una sola tabla web, el usuario se va a abrumar. 
**Solución UX para las Recetas:**
*   Implementar "Acordeones" (secciones colapsables).
*   Cuando entren a ver los materiales de un remolque, verán bloques grandes:
    *   `[+] Acero y Chasis (42 items)`
    *   `[+] Ejes y Suspensión (18 items)`
    *   `[+] Frenos y Aire (35 items)`
    *   `[+] Pintura y Limpieza (8 items)`
*   Esto hace que la revisión sea digerible. Si saben que la pintura está bien, ni siquiera abren esa sección.

## 5. Prevención de Errores (Poka-Yoke)
En Excel, si alguien borra una celda por error, la fórmula se rompe y nadie sabe por qué. En nuestro sistema:
*   **Cálculos bloqueados:** El costo unitario de un tornillo no se debería poder editar desde la cotización (se edita en el catálogo maestro). En la cotización solo se muestra el resultado.
*   **Alertas visuales:** Si un remolque requiere "Llantas" y el inventario o la receta marca "0", poner un icono rojo gigante ⚠️ indicando "Faltan Llantas en la receta".
