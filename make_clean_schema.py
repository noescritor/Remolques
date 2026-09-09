import os, glob

files = sorted(glob.glob('supabase/migrations/*.sql'))
# Exclude the KV store migration scripts since this is a fresh setup without legacy data
exclude = ['20260427_00_enable_rls.sql', '20260427_02_migrate_kv_data.sql']

content = ""
for f in files:
    filename = os.path.basename(f)
    if filename not in exclude:
        content += f"-- ========== {filename} ==========\n"
        content += open(f, 'r', encoding='utf-8').read() + "\n\n"

open('schema_nuevo_servidor.sql', 'w', encoding='utf-8').write(content)
print("schema_nuevo_servidor.sql creado exitosamente")
