import csv
import json

def parse_bom():
    recipes = {}
    current_recipe = None
    
    with open('artifacts/raw_bom.csv', 'r', encoding='utf-8', errors='ignore') as f:
        reader = csv.reader(f)
        for row in reader:
            if not row: continue
            
            # Detect recipe header
            if row[0] and ' ' in row[0] and not row[0].startswith('PASO') and not row[0].startswith('PROCESO') and not row[0].startswith('LUZ') and not row[0].startswith('TERMINADO') and not row[0].startswith('EXTRAS') and not row[0].startswith('AIRE') and not row[0].startswith('PINTURA') and not row[0].startswith('LIMPIEZA') and not row[0].startswith('DOLLY'):
                if 'PLANA' in row[0] or 'DOLLY' in row[0] or 'GONDOLA' in row[0]:
                    current_recipe = row[0].strip()
                    recipes[current_recipe] = []
                    continue
            
            if 'DOLLY  CON RETRACTIL' in row[0]:
                current_recipe = 'DOLLY CON RETRACTIL'
                recipes[current_recipe] = []
                continue
                
            if current_recipe:
                # Typically format is: PROCESO, CANTIDAD, PRODUCTOS...
                # Or sometimes just: CANTIDAD, PRODUCTOS
                
                # Check if row looks like an item
                if len(row) >= 3:
                    cantidad = row[1].strip()
                    producto = row[2].strip()
                    
                    if cantidad and producto and producto != 'PRODUCTOS' and producto != 'DESCRIPCION':
                        # Clean up cantidad (might be '0.5', '1 L', '2 PARES', '20')
                        try:
                            # Just keep the raw product name for now
                            if producto and producto != 'TIPO DE SISTEMA RETRACTIL' and producto != 'TIPO DE SUSPENSION' and producto != 'TIPO DE PATIN' and producto != 'TIPO DE EJE':
                                recipes[current_recipe].append({
                                    'cantidad': cantidad,
                                    'producto': producto
                                })
                        except:
                            pass

    with open('artifacts/parsed_bom.json', 'w', encoding='utf-8') as f:
        json.dump(recipes, f, indent=2, ensure_ascii=False)

if __name__ == '__main__':
    parse_bom()
