# Goal: Convertir Cotizaciones a Órdenes de Compra (Requisición)

El usuario quiere poder generar una orden de compra directamente desde una cotización.

## Tareas

1. **Backend (API)**
   - Agregar endpoints en `index.ts` para `/proveedores` (GET, POST, PUT, DELETE).
   - Agregar endpoints en `index.ts` para `/compras-proveedor` (GET, POST, PUT).
   - Agregar endpoints en `index.ts` para `/pagos-proveedor` (POST).

2. **Frontend (Generador de Requisición)**
   - Crear componente `GenerarRequisicionModal.tsx` en `src/app/components/Cotizaciones`.
     - Mostrará los materiales faltantes o permitirá al usuario elegir de la lista de materias primas.
     - Permitirá seleccionar al Proveedor.
     - Creará la `CompraProveedor` enlazada a la `Cotizacion`.
   - Modificar `CotizacionDetalle.tsx` para agregar el botón "Generar Orden de Compra".

3. **Frontend (Varios)**
   - Ajustar `useSupabaseData.ts` para asegurarse de que todos los endpoints concuerdan.

## Verificación
- El botón aparece cuando la cotización está "Aprobada".
- Al generar, la compra aparece en la pantalla de "Compras a proveedor".
