import re
import os
import glob

def fix_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    original = content

    # Fix references to productos(id)
    # Match something like: material_id uuid [NOT NULL] REFERENCES productos(id)
    # and change uuid to text
    content = re.sub(r'(\w+)\s+uuid\s+(.*?REFERENCES\s+productos\s*\(\s*id\s*\))', r'\1 text \2', content, flags=re.IGNORECASE)
    
    # Fix references to cotizaciones(id)
    content = re.sub(r'(\w+)\s+uuid\s+(.*?REFERENCES\s+cotizaciones\s*\(\s*id\s*\))', r'\1 text \2', content, flags=re.IGNORECASE)

    # Fix references to clientes(id)
    content = re.sub(r'(\w+)\s+uuid\s+(.*?REFERENCES\s+clientes\s*\(\s*id\s*\))', r'\1 text \2', content, flags=re.IGNORECASE)

    if original != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {filepath}")

for f in glob.glob('supabase/migrations/*.sql'):
    fix_file(f)

# Re-run make_clean_schema
import make_clean_schema
