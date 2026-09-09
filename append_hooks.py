import os

file_path = r"c:\Users\luisa\Downloads\proyectos_antygravity\Remolques\src\app\hooks\useSupabaseData.ts"

with open(file_path, "r", encoding="utf-8") as f:
    content = f.read()

if "const [proveedores, setProveedores]" not in content:
    # 1. Add state variables
    state_vars = """
  const [proveedores, setProveedores] = useState<Proveedor[]>([]);
  const [comprasProveedor, setComprasProveedor] = useState<CompraProveedor[]>([]);
  const [cotizacionEventos, setCotizacionEventos] = useState<CotizacionEvento[]>([]);
"""
    content = content.replace('const [notasList, setNotasList] = useState<NotaSimple[]>([]);', 'const [notasList, setNotasList] = useState<NotaSimple[]>([]);' + state_vars)

    # 2. Add to loadData try block
    load_data_adds = """
      const proveedoresData = await fetchJson('proveedores', `${BASE_URL}/proveedores`, token).catch(() => []);
      const comprasProveedorData = await fetchJson('compras-proveedor', `${BASE_URL}/compras-proveedor`, token).catch(() => []);
      const eventosData = await fetchJson('cotizacion-eventos', `${BASE_URL}/cotizacion-eventos`, token).catch(() => []);
"""
    content = content.replace("const pagosData = await fetchJson('pagos', `${BASE_URL}/pagos`, token);", "const pagosData = await fetchJson('pagos', `${BASE_URL}/pagos`, token);" + load_data_adds)

    # 3. Add to set states in loadData
    set_states = """
      setProveedores(Array.isArray(proveedoresData) ? proveedoresData : []);
      setComprasProveedor(Array.isArray(comprasProveedorData) ? comprasProveedorData : []);
      setCotizacionEventos(Array.isArray(eventosData) ? eventosData : []);
"""
    content = content.replace("setPagos(Array.isArray(pagosData) ? pagosData : []);", "setPagos(Array.isArray(pagosData) ? pagosData : []);" + set_states)

    # 4. Add to saveToLocalStorage
    local_storage = """
      saveToLocalStorage('proveedores', proveedoresData);
      saveToLocalStorage('compras_proveedor', comprasProveedorData);
      saveToLocalStorage('cotizacion_eventos', eventosData);
"""
    content = content.replace("saveToLocalStorage('pagos', pagosData);", "saveToLocalStorage('pagos', pagosData);" + local_storage)

    # 5. Add local storage fallback
    local_storage_fallback = """
        const localProveedores = localStorage.getItem('proveedores');
        const localCompras = localStorage.getItem('compras_proveedor');
        const localEventos = localStorage.getItem('cotizacion_eventos');
        
        setProveedores(localProveedores ? JSON.parse(localProveedores) : []);
        setComprasProveedor(localCompras ? JSON.parse(localCompras) : []);
        setCotizacionEventos(localEventos ? JSON.parse(localEventos) : []);
"""
    content = content.replace("setPagos(localPagos ? JSON.parse(localPagos) : []);", "setPagos(localPagos ? JSON.parse(localPagos) : []);" + local_storage_fallback)

    # 6. Add CRUD functions for Proveedores, Compras, Eventos
    crud_funcs = """
  // CRUD Proveedores
  const crearProveedor = async (proveedor: Omit<Proveedor, 'id'>) => {
    try {
      const resultado = await sendJson('crear proveedor', `${BASE_URL}/proveedores`, token, {
        method: 'POST',
        body: JSON.stringify(proveedor)
      });
      setProveedores(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating proveedor:', error);
      throw error;
    }
  };

  const actualizarProveedor = async (id: string, proveedor: Partial<Proveedor>) => {
    try {
      const resultado = await sendJson('actualizar proveedor', `${BASE_URL}/proveedores/${id}`, token, {
        method: 'PUT',
        body: JSON.stringify(proveedor)
      });
      setProveedores(prev => prev.map(p => p.id === id ? resultado : p));
      return resultado;
    } catch (error) {
      console.error('Error updating proveedor:', error);
      throw error;
    }
  };

  const eliminarProveedor = async (id: string) => {
    try {
      await sendJson('eliminar proveedor', `${BASE_URL}/proveedores/${id}`, token, { method: 'DELETE' });
      setProveedores(prev => prev.filter(p => p.id !== id));
    } catch (error) {
      console.error('Error deleting proveedor:', error);
      throw error;
    }
  };

  // CRUD Compras Proveedor
  const crearCompraProveedor = async (compra: Omit<CompraProveedor, 'id'>) => {
    try {
      const resultado = await sendJson('crear compra_proveedor', `${BASE_URL}/compras-proveedor`, token, {
        method: 'POST',
        body: JSON.stringify(compra)
      });
      setComprasProveedor(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating compra_proveedor:', error);
      throw error;
    }
  };

  const actualizarCompraProveedor = async (id: string, compra: Partial<CompraProveedor>) => {
    try {
      const resultado = await sendJson('actualizar compra_proveedor', `${BASE_URL}/compras-proveedor/${id}`, token, {
        method: 'PUT',
        body: JSON.stringify(compra)
      });
      setComprasProveedor(prev => prev.map(c => c.id === id ? resultado : c));
      return resultado;
    } catch (error) {
      console.error('Error updating compra_proveedor:', error);
      throw error;
    }
  };

  // CRUD Eventos
  const crearCotizacionEvento = async (evento: Omit<CotizacionEvento, 'id' | 'created_at' | 'usuario_id'>) => {
    try {
      const resultado = await sendJson('crear evento', `${BASE_URL}/cotizacion-eventos`, token, {
        method: 'POST',
        body: JSON.stringify(evento)
      });
      setCotizacionEventos(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating evento:', error);
      throw error;
    }
  };
"""
    content = content.replace("// Relaciones", crud_funcs + "\n  // Relaciones")
    
    # 7. Add imports
    content = content.replace("import { Cliente, Producto, Cotizacion, Pago, Ajustes, Plantilla, PerfilOrganizacion, InvitacionEquipo, MovimientoInventario, CategoriaProducto, CategoriaCliente, NotaSimple }", "import { Cliente, Producto, Cotizacion, Pago, Ajustes, Plantilla, PerfilOrganizacion, InvitacionEquipo, MovimientoInventario, CategoriaProducto, CategoriaCliente, NotaSimple, Proveedor, CompraProveedor, CotizacionEvento }")
    
    # 8. Return values in useSupabaseData
    return_values = """
    proveedores,
    comprasProveedor,
    cotizacionEventos,
    crearProveedor,
    actualizarProveedor,
    eliminarProveedor,
    crearCompraProveedor,
    actualizarCompraProveedor,
    crearCotizacionEvento,
"""
    content = content.replace("clientes,\n    productos,", return_values + "    clientes,\n    productos,")

    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)
    print("Hooks appended.")
else:
    print("Hooks already appended.")
