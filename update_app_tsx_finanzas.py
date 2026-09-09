import os

file_path = r"c:\Users\luisa\Downloads\proyectos_antygravity\Remolques\src\app\App.tsx"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

# 1. Imports
imports = """
import { CuentasPorCobrar } from './components/Finanzas/CuentasPorCobrar';
import { CuentasPorPagar } from './components/Finanzas/CuentasPorPagar';
"""
content = content.replace("import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';", imports + "import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';")

# 2. Add to getCurrentPage
current_page_cases = """
    if (path.startsWith('/cxc')) return 'cxc';
    if (path.startsWith('/cxp')) return 'cxp';
"""
content = content.replace("    if (path.startsWith('/trazabilidad')) return 'trazabilidad';", current_page_cases + "    if (path.startsWith('/trazabilidad')) return 'trazabilidad';")

# 3. Add routes
new_routes = """
        <Route path="/cxc" element={
          <CuentasPorCobrar
            cotizaciones={cotizaciones}
            pagos={pagos}
            clientes={clientes}
            loading={loading}
            onCrearPago={crearPago}
          />
        } />

        <Route path="/cxp" element={
          <CuentasPorPagar
            compras={comprasProveedor}
            pagos={pagosProveedor}
            proveedores={proveedores}
            productos={productos}
            loading={loading}
            onCrearPago={crearPagoProveedor}
          />
        } />
"""
content = content.replace('        <Route path="/trazabilidad" element={', new_routes + '        <Route path="/trazabilidad" element={')

with open(file_path, "w", encoding="utf-8") as f:
    f.write(content)
print("App.tsx updated for CXC and CXP.")
