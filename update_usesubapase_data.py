import os
import re

file_path = 'src/app/hooks/useSupabaseData.ts'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add fetching of pagos-proveedor in the online block
fetch_block = """      const comprasProveedorData = await fetchJson('compras-proveedor', `${BASE_URL}/compras-proveedor`, token).catch(() => []);
      setComprasProveedor(Array.isArray(comprasProveedorData) ? comprasProveedorData : []);
      saveToLocalStorage('compras_proveedor', comprasProveedorData);"""

new_fetch_block = fetch_block + """

      const pagosProveedorData = await fetchJson('pagos-proveedor', `${BASE_URL}/pagos-proveedor`, token).catch(() => []);
      setPagosProveedor(Array.isArray(pagosProveedorData) ? pagosProveedorData : []);
      saveToLocalStorage('pagos_proveedor', pagosProveedorData);"""

content = content.replace(fetch_block, new_fetch_block)

# 2. Add local storage fallback (offline block)
offline_block = """        const localCompras = localStorage.getItem('compras_proveedor');
        const localEventos = localStorage.getItem('cotizacion_eventos');
        
        setProveedores(localProveedores ? JSON.parse(localProveedores) : []);
        setComprasProveedor(localCompras ? JSON.parse(localCompras) : []);"""

new_offline_block = """        const localCompras = localStorage.getItem('compras_proveedor');
        const localPagosProveedor = localStorage.getItem('pagos_proveedor');
        const localEventos = localStorage.getItem('cotizacion_eventos');
        
        setProveedores(localProveedores ? JSON.parse(localProveedores) : []);
        setComprasProveedor(localCompras ? JSON.parse(localCompras) : []);
        setPagosProveedor(localPagosProveedor ? JSON.parse(localPagosProveedor) : []);"""

content = content.replace(offline_block, new_offline_block)

# 3. Write back
with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
