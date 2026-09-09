import os, glob

# Fix 1: compras_proveedor
f1 = 'supabase/migrations/20260907_03_compras_proveedor.sql'
c1 = open(f1, 'r', encoding='utf-8').read()
c1 = c1.replace('orden_id text,', 'cotizacion_id text REFERENCES cotizaciones(id) ON DELETE SET NULL,')
open(f1, 'w', encoding='utf-8').write(c1)

# Fix 2: cotizacion_eventos
f2 = 'supabase/migrations/20260907_06_cotizacion_eventos.sql'
c2 = open(f2, 'r', encoding='utf-8').read()
c2 = c2.replace('cotizacion_id uuid REFERENCES cotizaciones(id)', 'cotizacion_id text REFERENCES cotizaciones(id)')
open(f2, 'w', encoding='utf-8').write(c2)

# Fix 3: estado_produccion
f3 = 'supabase/migrations/20260907_05_estado_produccion_ampliado.sql'
c3 = open(f3, 'r', encoding='utf-8').read()
c3 = c3.replace('cotizacion_padre_id uuid REFERENCES cotizaciones(id)', 'cotizacion_padre_id text REFERENCES cotizaciones(id)')
open(f3, 'w', encoding='utf-8').write(c3)

# Re-run make_clean_schema
import make_clean_schema

print("Done fixing foreign keys.")
