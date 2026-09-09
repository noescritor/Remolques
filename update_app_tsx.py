import os

file_path = r"c:\Users\luisa\Downloads\proyectos_antygravity\Remolques\src\app\App.tsx"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Imports
imports = """
import { ProveedoresList } from './components/Proveedores/ProveedoresList';
import { ComprasProveedorList } from './components/ComprasProveedor/ComprasProveedorList';
import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';
"""
content = content.replace("import { ClientesList } from './components/Clientes/ClientesList';", imports + "import { ClientesList } from './components/Clientes/ClientesList';")

# 2. Add destructured values from useSupabaseData
hooks_to_destructure = """
    proveedores,
    comprasProveedor,
    cotizacionEventos,
    crearProveedor,
    actualizarProveedor,
    eliminarProveedor,
    crearCompraProveedor,
    actualizarCompraProveedor,
"""
content = content.replace("    productos,", hooks_to_destructure + "    productos,")

# 3. Add to getCurrentPage
current_page_cases = """
    if (path.startsWith('/proveedores')) return 'proveedores';
    if (path.startsWith('/compras')) return 'compras';
    if (path.startsWith('/trazabilidad')) return 'trazabilidad';
"""
content = content.replace("    if (path.startsWith('/productos')) return 'productos';", current_page_cases + "    if (path.startsWith('/productos')) return 'productos';")

# 4. Add routes
new_routes = """
        <Route path="/proveedores" element={
          <ProveedoresList
            proveedores={proveedores}
            productos={productos}
            loading={loading}
            onCrearProveedor={crearProveedor}
            onActualizarProveedor={actualizarProveedor}
            onEliminarProveedor={eliminarProveedor}
          />
        } />

        <Route path="/compras" element={
          <ComprasProveedorList
            compras={comprasProveedor}
            proveedores={proveedores}
            productos={productos}
            loading={loading}
            onRecibirCompra={(id) => actualizarCompraProveedor(id, { estado: 'Recibida' })}
            rolActual={session?.user?.user_metadata?.rol || 'usuario'}
          />
        } />

        <Route path="/trazabilidad" element={
          <TrazabilidadList
            eventos={cotizacionEventos}
            cotizaciones={cotizaciones}
            loading={loading}
          />
        } />
"""
content = content.replace('        <Route path="/productos" element={', new_routes + '        <Route path="/productos" element={')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("App.tsx updated.")
