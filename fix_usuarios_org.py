import os

filepath = 'supabase/migrations/20260907_09_pagos_proveedor.sql'
content = open(filepath, 'r', encoding='utf-8').read()

content = content.replace('usuarios_organizaciones', 'perfiles_organizacion')

open(filepath, 'w', encoding='utf-8').write(content)
print(f"Fixed {filepath}")

# Re-run make_clean_schema
import make_clean_schema
