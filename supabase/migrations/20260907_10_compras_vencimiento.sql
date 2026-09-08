-- Agregar fecha de vencimiento a compras_proveedor para programar cuentas por pagar
ALTER TABLE compras_proveedor 
ADD COLUMN IF NOT EXISTS fecha_vencimiento_pago TIMESTAMPTZ;

-- Actualizar las existentes para que venzan en 30 días si no tienen
UPDATE compras_proveedor 
SET fecha_vencimiento_pago = fecha + INTERVAL '30 days'
WHERE fecha_vencimiento_pago IS NULL;
