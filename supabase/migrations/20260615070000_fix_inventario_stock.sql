-- Migracion correctiva para inventario  
-- Asegurar que stock_actual y stock_reservado existan y no sean null en productos  
  
ALTER TABLE productos ADD COLUMN IF NOT EXISTS stock_actual INT DEFAULT 0;  
ALTER TABLE productos ADD COLUMN IF NOT EXISTS stock_reservado INT DEFAULT 0;  
  
UPDATE productos SET stock_actual = 0 WHERE stock_actual IS NULL;  
UPDATE productos SET stock_reservado = 0 WHERE stock_reservado IS NULL;  
  
ALTER TABLE productos ALTER COLUMN stock_actual SET DEFAULT 0;  
ALTER TABLE productos ALTER COLUMN stock_reservado SET DEFAULT 0; 
