UPDATE presupuestos 
SET datos = '{
  "Chasis": {
    "total": 50000, 
    "items": [
      {"pzas": "1", "material": "Chasis Plataforma", "cu": 50000, "importe": 50000, "peso": 1200}
    ]
  }
}'::jsonb 
WHERE datos ? 'items';
