-- Migración 4: Crédito de cliente

ALTER TABLE clientes
ADD COLUMN IF NOT EXISTS limite_credito numeric DEFAULT 0;

CREATE OR REPLACE VIEW vista_saldo_cliente AS
SELECT 
    c.id AS cliente_id,
    c.organizacion_id,
    c.limite_credito,
    COALESCE(
        (SELECT SUM(total) FROM cotizaciones WHERE cliente_id = c.id AND estado IN ('Aprobada', 'Pagada')),
        0
    ) - COALESCE(
        (SELECT SUM(p.monto) 
         FROM pagos p 
         JOIN cotizaciones ct ON p.cotizacion_id = ct.id 
         WHERE ct.cliente_id = c.id AND ct.estado IN ('Aprobada', 'Pagada')),
        0
    ) AS saldo_usado
FROM clientes c;
