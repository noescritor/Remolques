import json
import uuid

def clean_product_name(name):
    # Remove quotes, trailing commas, handle encoding issues
    name = name.strip(',"\' ')
    name = name.replace('CAF%', 'CAFE')
    return name

def generate_sql():
    with open('artifacts/parsed_bom.json', 'r', encoding='utf-8') as f:
        recipes = json.load(f)

    sql_statements = [
        "-- MIGRACION DE RECETAS BOM A PARTIR DE EXCEL",
        "-- Fecha: 2026-10-05",
        "BEGIN;",
        ""
    ]

    all_materials = set()
    for recipe_name, items in recipes.items():
        if recipe_name == 'GONDOLA ACERO A-36': continue
        for item in items:
            name = clean_product_name(item['producto'])
            if name:
                all_materials.add(name)

    # Insert raw materials
    sql_statements.append("-- 1. REGISTRAR MATERIAS PRIMAS")
    sql_statements.append("INSERT INTO productos (id, nombre, tipo_item, costo, precio_unitario, organizacion_id)")
    sql_statements.append("VALUES")

    material_id_map = {}
    material_values = []
    
    # We will use hardcoded org_id if possible, or just skip it if it's default
    # The system uses RLS. To bypass RLS in migration, we might just leave organizacion_id NULL? No, we must find a way or let the user run it from Supabase.
    # In Supabase UI, they have their org_id. If they run it, it might fail if organizacion_id is required. 
    # Usually we can get the first org.
    org_id_var = "(SELECT id FROM organizaciones LIMIT 1)"

    for mat in sorted(all_materials):
        mat_id = str(uuid.uuid4())
        material_id_map[mat] = mat_id
        # Replace single quotes
        safe_mat = mat.replace("'", "''")
        material_values.append(f"  ('{mat_id}', '{safe_mat}', 'materia_prima', 0, 0, {org_id_var})")

    sql_statements.append(",\n".join(material_values))
    sql_statements.append("ON CONFLICT (nombre, organizacion_id) DO NOTHING;")
    sql_statements.append("")

    # Insert finished products
    sql_statements.append("-- 2. REGISTRAR PRODUCTOS TERMINADOS")
    product_ids = {}
    prod_values = []
    for recipe_name in recipes.keys():
        if recipe_name == 'GONDOLA ACERO A-36': continue
        prod_id = str(uuid.uuid4())
        product_ids[recipe_name] = prod_id
        safe_name = recipe_name.replace("'", "''")
        prod_values.append(f"  ('{prod_id}', '{safe_name}', 'producto_terminado', 0, 0, {org_id_var})")

    sql_statements.append("INSERT INTO productos (id, nombre, tipo_item, costo, precio_unitario, organizacion_id)")
    sql_statements.append("VALUES")
    sql_statements.append(",\n".join(prod_values))
    sql_statements.append("ON CONFLICT (nombre, organizacion_id) DO NOTHING;")
    sql_statements.append("")

    # Insert recipes
    sql_statements.append("-- 3. REGISTRAR RECETAS (BOM)")
    sql_statements.append("INSERT INTO producto_materiales (producto_id, material_id, cantidad, organizacion_id)")
    sql_statements.append("VALUES")

    recipe_values = []
    for recipe_name, items in recipes.items():
        if recipe_name == 'GONDOLA ACERO A-36': continue
        prod_name_safe = recipe_name.replace("'", "''")
        
        for item in items:
            mat_name = clean_product_name(item['producto'])
            safe_mat = mat_name.replace("'", "''")
            cant = item['cantidad']
            
            try:
                # Convert '15.9' or '2' to float
                cant_float = float(cant)
            except:
                # Sometimes it says '1 PZA' or '1 L'
                import re
                nums = re.findall(r"[-+]?\d*\.\d+|\d+", cant)
                if nums:
                    cant_float = float(nums[0])
                else:
                    cant_float = 1.0

            # Find IDs dynamically using subqueries to handle conflicts gracefully
            recipe_values.append(f"  ((SELECT id FROM productos WHERE nombre = '{prod_name_safe}' LIMIT 1), (SELECT id FROM productos WHERE nombre = '{safe_mat}' LIMIT 1), {cant_float}, {org_id_var})")

    sql_statements.append(",\n".join(recipe_values))
    sql_statements.append("ON CONFLICT DO NOTHING;")
    
    sql_statements.append("")
    sql_statements.append("COMMIT;")

    with open('20261005_01_recetas_nuevas.sql', 'w', encoding='utf-8') as f:
        f.write("\n".join(sql_statements))

if __name__ == '__main__':
    generate_sql()
