import { useState, useEffect } from 'react';
import { supabase } from '../utils/supabase/client';
import { Cliente, Producto, Cotizacion, Pago, Ajustes, Plantilla, PerfilOrganizacion, InvitacionEquipo, MovimientoInventario, CategoriaProducto, CategoriaCliente } from '../types';
const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;

const getHeaders = (token?: string) => ({
  'Content-Type': 'application/json',
  ...(token ? { 'Authorization': `Bearer ${token}` } : {})
});

const parseResponse = async (label: string, response: Response) => {
  const text = await response.text();
  let data;
  try {
    data = text ? JSON.parse(text) : null;
  } catch {
    throw new Error(`${label}: respuesta no JSON (${text.slice(0, 120) || 'vacía'})`);
  }
  if (!response.ok) {
    throw new Error(`${label}: ${data?.error || data?.message || `Error ${response.status}`}`);
  }
  return data;
};

const fetchJson = async (label: string, url: string, token?: string) => {
  const response = await fetch(url, { headers: getHeaders(token) });
  return parseResponse(label, response);
};

const sendJson = async (label: string, url: string, token: string | undefined, init: RequestInit = {}) => {
  const response = await fetch(url, {
    ...init,
    headers: {
      ...getHeaders(token),
      ...(init.headers || {}),
    },
  });
  return parseResponse(label, response);
};

export function useSupabaseData(token?: string) {
  const [clientes, setClientes] = useState<Cliente[]>([]);
  const [productos, setProductos] = useState<Producto[]>([]);
  const [cotizaciones, setCotizaciones] = useState<Cotizacion[]>([]);
  const [pagos, setPagos] = useState<Pago[]>([]);
  const [plantillas, setPlantillas] = useState<Plantilla[]>([]);
  const [equipo, setEquipo] = useState<PerfilOrganizacion[]>([]);
  const [invitaciones, setInvitaciones] = useState<InvitacionEquipo[]>([]);
  const [categoriasProducto, setCategoriasProducto] = useState<CategoriaProducto[]>([]);
  const [categoriasCliente, setCategoriasCliente] = useState<CategoriaCliente[]>([]);
  const [ajustes, setAjustes] = useState<Ajustes>({
    iva_por_defecto: 0.16,
    validez_por_defecto: 30,
    nota_por_defecto: 'Gracias por su preferencia. Esta cotización tiene una validez de {validez_dias} días.',
    prefijo_folio: '',
    offset_folio: 1,
    nombre_empresa: 'IDEALLY',
    tagline: 'Arte . Diseño . Ingeniería',
    direccion: 'Retorno Pascual Mendoza 27, Puebla, Pue. 72260',
    telefono: '+52 22 1120 2976',
    email: 'ventas@ideally.com.mx',
    sitio_web: 'www.ideally.com.mx',
    cuenta_bancaria: '',
    resumen_servicios: {
      titulo: 'RESUMEN DE SERVICIOS',
      pago_unico: 'Servicio de pago único',
      suscripcion: 'Servicio de suscripción',
      hibrido: 'Servicio híbrido',
      setup_completo: 'Incluye setup completo',
      setup_inicial: 'Incluye setup inicial',
      periodo_label: 'Periodo:',
      meses_contratados_label: 'Meses contratados:',
      permanencia_minima_label: 'Permanencia mínima:',
      base_asientos_label: 'Base:',
      asientos_adicionales_label: 'Asientos adicionales:'
    }
  });
  const [loading, setLoading] = useState(true);
  const [serverError, setServerError] = useState<string | null>(null);
  const [useLocalData, setUseLocalData] = useState(false);
  

  // CRUD Categorías Producto
  const crearCategoriaProducto = async (categoria: Omit<CategoriaProducto, 'id' | 'organizacion_id'>) => {
    try {
      const { data, error } = await supabase.from('categorias_producto').insert(categoria).select().single();
      if (error) throw error;
      setCategoriasProducto([...categoriasProducto, data]);
      toast.success('Categoría creada', { description: 'La categoría se creó correctamente.' });
      return data;
    } catch (error: any) {
      toast.error('Error al crear categoría', { description: error.message });
      throw error;
    }
  };

  const actualizarCategoriaProducto = async (id: string, categoria: Partial<CategoriaProducto>) => {
    try {
      const { data, error } = await supabase.from('categorias_producto').update(categoria).eq('id', id).select().single();
      if (error) throw error;
      setCategoriasProducto(categoriasProducto.map(c => c.id === id ? data : c));
      toast.success('Categoría actualizada');
    } catch (error: any) {
      toast.error('Error al actualizar', { description: error.message });
      throw error;
    }
  };

  const eliminarCategoriaProducto = async (id: string) => {
    try {
      const { error } = await supabase.from('categorias_producto').delete().eq('id', id);
      if (error) throw error;
      setCategoriasProducto(categoriasProducto.filter(c => c.id !== id));
      toast.success('Categoría eliminada');
    } catch (error: any) {
      toast.error('Error al eliminar', { description: error.message });
      throw error;
    }
  };


  // CRUD Categorías Cliente
  const crearCategoriaCliente = async (categoria: Omit<CategoriaCliente, 'id' | 'organizacion_id'>) => {
    try {
      const { data, error } = await supabase.from('categorias_cliente').insert(categoria).select().single();
      if (error) throw error;
      setCategoriasCliente([...categoriasCliente, data]);
      toast.success('Categoría creada', { description: 'La categoría se creó correctamente.' });
      return data;
    } catch (error: any) {
      toast.error('Error al crear categoría', { description: error.message });
      throw error;
    }
  };

  const actualizarCategoriaCliente = async (id: string, categoria: Partial<CategoriaCliente>) => {
    try {
      const { data, error } = await supabase.from('categorias_cliente').update(categoria).eq('id', id).select().single();
      if (error) throw error;
      setCategoriasCliente(categoriasCliente.map(c => c.id === id ? data : c));
      toast.success('Categoría actualizada');
    } catch (error: any) {
      toast.error('Error al actualizar', { description: error.message });
      throw error;
    }
  };

  const eliminarCategoriaCliente = async (id: string) => {
    try {
      const { error } = await supabase.from('categorias_cliente').delete().eq('id', id);
      if (error) throw error;
      setCategoriasCliente(categoriasCliente.filter(c => c.id !== id));
      toast.success('Categoría eliminada');
    } catch (error: any) {
      toast.error('Error al eliminar', { description: error.message });
      throw error;
    }
  };

  // Helper to generate ID


  const generateId = () => `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
  
  // Helper to generate folio
  const generarFolio = (prefijo: string, numero: number): string => {
    const año = new Date().getFullYear();
    const numeroFormateado = numero.toString().padStart(5, '0');
    return prefijo ? `${prefijo}-${año}-${numeroFormateado}` : `${año}-${numeroFormateado}`;
  };
  
  // Helper to save to localStorage
  const saveToLocalStorage = (key: string, data: any) => {
    try {
      localStorage.setItem(key, JSON.stringify(data));
    } catch (error) {
      console.error(`Error saving ${key} to localStorage:`, error);
    }
  };

  // Check if server is available
  const checkServerAvailability = async (): Promise<boolean> => {
    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 8000); // 8s — handles cold starts

      const response = await fetch(`${BASE_URL}/health`, {
        signal: controller.signal
      });

      clearTimeout(timeoutId);
      return response.ok;
    } catch (error) {
      return false;
    }
  };

  // Load initial data
  const loadData = async () => {
    if (!token) {
      setLoading(false);
      return;
    }

    setLoading(true);
    
    // Check if server is available (single check, no console errors)
    const serverAvailable = await checkServerAvailability();
    
    if (!serverAvailable) {
      // Server not available - use local mode silently
      setUseLocalData(true);
      setServerError('Server unavailable');
      
      // Load from localStorage
      try {
        const localClientes = localStorage.getItem('clientes');
        const localProductos = localStorage.getItem('productos');
        const localCotizaciones = localStorage.getItem('cotizaciones');
        const localPagos = localStorage.getItem('pagos');
        const localAjustes = localStorage.getItem('ajustes');
        
        setClientes(localClientes ? JSON.parse(localClientes) : []);
        setProductos(localProductos ? JSON.parse(localProductos) : []);
        setCotizaciones(localCotizaciones ? JSON.parse(localCotizaciones) : []);
        setPagos(localPagos ? JSON.parse(localPagos) : []);
        setAjustes(localAjustes ? JSON.parse(localAjustes) : ajustes);
      } catch (error) {
        // Silent fail - just use empty arrays
      }
      
      setLoading(false);
      return;
    }
    
    // Server is available, try to fetch
    try {
      const clientesData = await fetchJson('clientes', `${BASE_URL}/clientes`, token);
      const productosData = await fetchJson('productos', `${BASE_URL}/productos`, token);
      const cotizacionesData = await fetchJson('cotizaciones', `${BASE_URL}/cotizaciones`, token);
      const pagosData = await fetchJson('pagos', `${BASE_URL}/pagos`, token);

      const categoriasReq = await supabase.from('categorias_producto').select('*').order('orden');
      if (categoriasReq.data) setCategoriasProducto(categoriasReq.data);


      const categoriasReqC = await supabase.from('categorias_cliente').select('*').order('orden');
      if (categoriasReqC.data) setCategoriasCliente(categoriasReqC.data);

      const ajustesData = await fetchJson('ajustes', `${BASE_URL}/ajustes`, token);
      const plantillasData = await fetchJson('plantillas', `${BASE_URL}/plantillas`, token).catch(error => {
        console.warn('No se pudieron cargar plantillas:', error);
        return [];
      });
      const equipoData = await fetchJson('equipo', `${BASE_URL}/equipo`, token).catch(error => {
        console.warn('No se pudo cargar equipo:', error);
        return [];
      });
      const invitacionesData = await fetchJson('invitaciones', `${BASE_URL}/invitaciones`, token).catch(error => {
        console.warn('No se pudieron cargar invitaciones:', error);
        return [];
      });

      setClientes(Array.isArray(clientesData) ? clientesData : []);
      setProductos(Array.isArray(productosData) ? productosData : []);
      setCotizaciones(Array.isArray(cotizacionesData) ? cotizacionesData : []);
      setPagos(Array.isArray(pagosData) ? pagosData : []);
      setAjustes(ajustesData?.error ? ajustes : (ajustesData || ajustes));
      setPlantillas(Array.isArray(plantillasData) ? plantillasData : []);
      setEquipo(Array.isArray(equipoData) ? equipoData : []);
      setInvitaciones(Array.isArray(invitacionesData) ? invitacionesData : []);
      setUseLocalData(false);
      setServerError(null);

      // Save to localStorage as backup
      saveToLocalStorage('clientes', clientesData);
      saveToLocalStorage('productos', productosData);
      saveToLocalStorage('cotizaciones', cotizacionesData);
      saveToLocalStorage('pagos', pagosData);
      saveToLocalStorage('ajustes', ajustesData);
      
    } catch (error) {
      const message = error instanceof Error ? error.message : 'Failed to load from server';
      setServerError(message);
      setUseLocalData(true);
      
      // Fallback to localStorage
      try {
        const localClientes = localStorage.getItem('clientes');
        const localProductos = localStorage.getItem('productos');
        const localCotizaciones = localStorage.getItem('cotizaciones');
        const localPagos = localStorage.getItem('pagos');
        const localAjustes = localStorage.getItem('ajustes');
        
        setClientes(localClientes ? JSON.parse(localClientes) : []);
        setProductos(localProductos ? JSON.parse(localProductos) : []);
        setCotizaciones(localCotizaciones ? JSON.parse(localCotizaciones) : []);
        setPagos(localPagos ? JSON.parse(localPagos) : []);
        setAjustes(localAjustes ? JSON.parse(localAjustes) : ajustes);
      } catch (localError) {
        // Silent fail
      }
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, [token]);

  // Relaciones
  const cotizacionesConClientes = cotizaciones.map(cotizacion => ({
    ...cotizacion,
    cliente: clientes.find(c => c?.id === cotizacion?.cliente_id) || undefined
  }));

  // CRUD Clientes
  const crearCliente = async (cliente: Omit<Cliente, 'id'>) => {
    const nuevoCliente: Cliente = {
      ...cliente,
      id: generateId()
    };
    
    if (useLocalData) {
      const nuevosClientes = [...clientes, nuevoCliente];
      setClientes(nuevosClientes);
      saveToLocalStorage('clientes', nuevosClientes);
      return nuevoCliente;
    }
    
    try {
      const resultado = await sendJson('crear cliente', `${BASE_URL}/clientes`, token, {
        method: 'POST',
        body: JSON.stringify(cliente)
      });
      setClientes(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating cliente:', error);
      throw error;
    }
  };

  const actualizarCliente = async (id: string, cliente: Partial<Cliente>) => {
    if (useLocalData) {
      const clientesActualizados = clientes.map(c => c.id === id ? { ...c, ...cliente } : c);
      setClientes(clientesActualizados);
      saveToLocalStorage('clientes', clientesActualizados);
      return;
    }
    
    try {
      const resultado = await sendJson('actualizar cliente', `${BASE_URL}/clientes/${id}`, token, {
        method: 'PUT',
        body: JSON.stringify(cliente)
      });
      setClientes(prev => prev.map(c => c.id === id ? resultado : c));
      return resultado;
    } catch (error) {
      console.error('Error updating cliente:', error);
      throw error;
    }
  };

  const eliminarCliente = async (id: string) => {
    if (useLocalData) {
      const clientesActualizados = clientes.filter(c => c.id !== id);
      setClientes(clientesActualizados);
      saveToLocalStorage('clientes', clientesActualizados);
      return;
    }
    
    try {
      await sendJson('eliminar cliente', `${BASE_URL}/clientes/${id}`, token, {
        method: 'DELETE',
      });
      setClientes(prev => prev.filter(c => c.id !== id));
    } catch (error) {
      console.error('Error deleting cliente:', error);
      throw error;
    }
  };

  // CRUD Productos
  const crearProducto = async (producto: Omit<Producto, 'id'>) => {
    const nuevoProducto: Producto = {
      ...producto,
      id: generateId()
    };
    
    if (useLocalData) {
      const nuevosProductos = [...productos, nuevoProducto];
      setProductos(nuevosProductos);
      saveToLocalStorage('productos', nuevosProductos);
      return nuevoProducto;
    }
    
    try {
      const resultado = await sendJson('crear producto', `${BASE_URL}/productos`, token, {
        method: 'POST',
        body: JSON.stringify(producto)
      });
      setProductos(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating producto:', error);
      throw error;
    }
  };

  const actualizarProducto = async (id: string, producto: Partial<Producto>) => {
    if (useLocalData) {
      const productosActualizados = productos.map(p => p.id === id ? { ...p, ...producto } : p);
      setProductos(productosActualizados);
      saveToLocalStorage('productos', productosActualizados);
      return;
    }

    // Si cambia el precio, registrar historial antes de actualizar
    if (producto.precio_unitario !== undefined) {
      const productoActual = productos.find(p => p.id === id);
      if (productoActual && productoActual.precio_unitario !== producto.precio_unitario) {
        fetch(`${BASE_URL}/productos/${id}/historial-precio`, {
          method: 'POST',
          headers: getHeaders(token),
          body: JSON.stringify({
            precio_anterior: productoActual.precio_unitario,
            precio_nuevo: producto.precio_unitario
          })
        }).catch(() => {}); // best-effort, no bloqueante
      }
    }

    try {
      const resultado = await sendJson('actualizar producto', `${BASE_URL}/productos/${id}`, token, {
        method: 'PUT',
        body: JSON.stringify(producto)
      });
      setProductos(prev => prev.map(p => p.id === id ? resultado : p));
      return resultado;
    } catch (error) {
      console.error('Error updating producto:', error);
      throw error;
    }
  };

  const eliminarProducto = async (id: string) => {
    if (useLocalData) {
      const productosActualizados = productos.filter(p => p.id !== id);
      setProductos(productosActualizados);
      saveToLocalStorage('productos', productosActualizados);
      return;
    }
    
    try {
      await sendJson('eliminar producto', `${BASE_URL}/productos/${id}`, token, {
        method: 'DELETE',
      });
      setProductos(prev => prev.filter(p => p.id !== id));
    } catch (error) {
      console.error('Error deleting producto:', error);
      throw error;
    }
  };

  // CRUD Cotizaciones
  const crearCotizacion = async (cotizacion: Omit<Cotizacion, 'id' | 'folio'>) => {
    if (useLocalData) {
      const ultimaFolio = Math.max(
        ...cotizaciones.map(c => {
          const partes = c.folio.split('-');
          return parseInt(partes[partes.length - 1]) || 0;
        }),
        0
      );
      
      const nuevaCotizacion: Cotizacion = {
        ...cotizacion,
        id: generateId(),
        folio: generarFolio(ajustes.prefijo_folio, ultimaFolio + 1)
      };
      
      const nuevasCotizaciones = [...cotizaciones, nuevaCotizacion];
      setCotizaciones(nuevasCotizaciones);
      saveToLocalStorage('cotizaciones', nuevasCotizaciones);
      return nuevaCotizacion;
    }
    
    try {
      const resultado = await sendJson('crear cotización', `${BASE_URL}/cotizaciones`, token, {
        method: 'POST',
        body: JSON.stringify(cotizacion)
      });
      if (!resultado?.id || !resultado?.folio) {
        throw new Error('El servidor no devolvió una cotización válida.');
      }
      setCotizaciones(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error creating cotizacion:', error);
      throw error;
    }
  };

  const actualizarCotizacion = async (id: string, cotizacion: Partial<Cotizacion>) => {
    if (useLocalData) {
      const cotizacionesActualizadas = cotizaciones.map(c => 
        c.id === id ? { ...c, ...cotizacion } : c
      );
      setCotizaciones(cotizacionesActualizadas);
      saveToLocalStorage('cotizaciones', cotizacionesActualizadas);
      return;
    }
    
    try {
      const resultado = await sendJson('actualizar cotización', `${BASE_URL}/cotizaciones/${id}`, token, {
        method: 'PUT',
        body: JSON.stringify(cotizacion)
      });
      if (!resultado?.id) {
        throw new Error('El servidor no devolvió una cotización válida.');
      }
      setCotizaciones(prev => prev.map(c => c.id === id ? resultado : c));
      return resultado;
    } catch (error) {
      console.error('Error updating cotizacion:', error);
      throw error;
    }
  };

  const eliminarCotizacion = async (id: string) => {
    if (useLocalData) {
      const cotizacionesActualizadas = cotizaciones.filter(c => c.id !== id);
      const pagosActualizados = pagos.filter(p => p.cotizacion_id !== id);
      setCotizaciones(cotizacionesActualizadas);
      setPagos(pagosActualizados);
      saveToLocalStorage('cotizaciones', cotizacionesActualizadas);
      saveToLocalStorage('pagos', pagosActualizados);
      return;
    }
    
    try {
      await sendJson('eliminar cotización', `${BASE_URL}/cotizaciones/${id}`, token, {
        method: 'DELETE',
      });
      setCotizaciones(prev => prev.filter(c => c.id !== id));
      setPagos(prev => prev.filter(p => p.cotizacion_id !== id));
    } catch (error) {
      console.error('Error deleting cotizacion:', error);
      throw error;
    }
  };

  const duplicarCotizacion = async (id: string) => {
    const cotizacionExistente = cotizaciones.find(c => c.id === id);
    if (!cotizacionExistente) {
      throw new Error('Cotización no encontrada');
    }
    
    if (useLocalData) {
      const ultimaFolio = Math.max(
        ...cotizaciones.map(c => {
          const partes = c.folio.split('-');
          return parseInt(partes[partes.length - 1]) || 0;
        }),
        0
      );
      
      const cotizacionDuplicada: Cotizacion = {
        ...cotizacionExistente,
        id: generateId(),
        folio: generarFolio(ajustes.prefijo_folio, ultimaFolio + 1),
        estado: 'Borrador',
        fecha: new Date().toISOString().split('T')[0],
        items: cotizacionExistente.items.map(item => ({
          ...item,
          id: generateId()
        }))
      };
      
      const nuevasCotizaciones = [...cotizaciones, cotizacionDuplicada];
      setCotizaciones(nuevasCotizaciones);
      saveToLocalStorage('cotizaciones', nuevasCotizaciones);
      return cotizacionDuplicada;
    }
    
    try {
      const resultado = await sendJson('duplicar cotización', `${BASE_URL}/cotizaciones/${id}/duplicate`, token, {
        method: 'POST',
      });
      if (!resultado?.id || !resultado?.folio) {
        throw new Error('El servidor no devolvió una cotización válida.');
      }
      setCotizaciones(prev => [...prev, resultado]);
      return resultado;
    } catch (error) {
      console.error('Error duplicating cotizacion:', error);
      throw error;
    }
  };

  const generarTokenPortal = async (id: string) => {
    if (useLocalData) {
      const tokenPortal = crypto.randomUUID();
      const cotizacion = cotizaciones.find(c => c.id === id);
      const expira = new Date();
      expira.setDate(expira.getDate() + (cotizacion?.validez_dias || 30));

      const cotizacionesActualizadas = cotizaciones.map(c =>
        c.id === id
          ? {
              ...c,
              token_publico: tokenPortal,
              token_expira_en: expira.toISOString(),
              estado: 'Enviada' as const
            }
          : c
      );
      setCotizaciones(cotizacionesActualizadas);
      saveToLocalStorage('cotizaciones', cotizacionesActualizadas);
    
  // Inventario
  const obtenerMovimientosInventario = async (): Promise<MovimientoInventario[]> => {
    try {
      const data = await fetchJson('obtener movimientos inventario', `${BASE_URL}/inventario/movimientos`, token);
      return data;
    } catch (error) {
      console.error('Error fetching movimientos:', error);
      throw error;
    }
  };

  const registrarMovimientoInventario = async (movimiento: Partial<MovimientoInventario>) => {
    try {
      const resultado = await sendJson('crear movimiento inventario', `${BASE_URL}/inventario/movimientos`, token, {
        method: 'POST',
        body: JSON.stringify(movimiento)
      });
      // Recargar productos para actualizar stock
      loadData();
      return resultado;
    } catch (error) {
      console.error('Error creating movimiento inventario:', error);
      throw error;
    }
  };

  return {
    categoriasProducto,
    categoriasCliente,
    crearCategoriaCliente,
    actualizarCategoriaCliente,
    eliminarCategoriaCliente,
    crearCategoriaProducto,
    actualizarCategoriaProducto,
    eliminarCategoriaProducto,
 token: tokenPortal, expira: expira.toISOString() };
    }

    const resultado = await sendJson('generar portal', `${BASE_URL}/cotizaciones/${id}/generar-token-portal`, token, {
      method: 'POST',
    });

    setCotizaciones(prev => prev.map(c =>
      c.id === id
        ? {
            ...c,
            token_publico: resultado.token,
            token_expira_en: resultado.expira,
            estado: 'Enviada' as const
          }
        : c
    ));
    return resultado;
  };

  // CRUD Pagos
  const crearPago = async (pago: Omit<Pago, 'id'>) => {
    const nuevoPago: Pago = {
      ...pago,
      id: generateId()
    };
    
    if (useLocalData) {
      const nuevosPagos = [...pagos, nuevoPago];
      setPagos(nuevosPagos);
      saveToLocalStorage('pagos', nuevosPagos);
      
      // Check if cotizacion should be marked as paid
      const pagosCotizacion = nuevosPagos.filter(p => p.cotizacion_id === pago.cotizacion_id);
      const totalPagado = pagosCotizacion.reduce((sum, p) => sum + p.monto, 0);
      const cotizacion = cotizaciones.find(c => c.id === pago.cotizacion_id);
      
      if (cotizacion && Math.abs(totalPagado - cotizacion.total) < 0.01) {
        const cotizacionesActualizadas = cotizaciones.map(c =>
          c.id === pago.cotizacion_id ? { ...c, estado: 'Pagada' as const } : c
        );
        setCotizaciones(cotizacionesActualizadas);
        saveToLocalStorage('cotizaciones', cotizacionesActualizadas);
      }
      
      return nuevoPago;
    }
    
    try {
      const resultado = await sendJson('crear pago', `${BASE_URL}/pagos`, token, {
        method: 'POST',
        body: JSON.stringify(pago)
      });
      setPagos(prev => [...prev, resultado]);
      
      // Reload cotizaciones to get updated state
      const cotizacionesActualizadas = await fetchJson('cotizaciones', `${BASE_URL}/cotizaciones`, token);
      setCotizaciones(cotizacionesActualizadas);
      
      return resultado;
    } catch (error) {
      console.error('Error creating pago:', error);
      throw error;
    }
  };

  const obtenerPagosPorCotizacion = (cotizacionId: string) => {
    if (!cotizacionId || !Array.isArray(pagos)) return [];
    return pagos.filter(p => p?.cotizacion_id === cotizacionId);
  };

  const calcularSaldoPendiente = (cotizacionId: string) => {
    if (!cotizacionId) return 0;
    const cotizacion = cotizaciones.find(c => c?.id === cotizacionId);
    const pagosCotizacion = obtenerPagosPorCotizacion(cotizacionId);
    const totalPagado = pagosCotizacion.reduce((sum, p) => sum + (p?.monto || 0), 0);
    return (cotizacion?.total || 0) - totalPagado;
  };

  // Ajustes
  const actualizarAjustes = async (nuevosAjustes: Partial<Ajustes>) => {
    const ajustesActualizados = { ...ajustes, ...nuevosAjustes };
    
    if (useLocalData) {
      setAjustes(ajustesActualizados);
      saveToLocalStorage('ajustes', ajustesActualizados);
      return ajustesActualizados;
    }
    
    try {
      const resultado = await sendJson('actualizar ajustes', `${BASE_URL}/ajustes`, token, {
        method: 'PUT',
        body: JSON.stringify(nuevosAjustes)
      });
      setAjustes(resultado);
      return resultado;
    } catch (error) {
      console.error('Error updating ajustes:', error);
      throw error;
    }
  };

  // ─── Plantillas ───────────────────────────────────────────────────────────

  const crearPlantilla = async (plantilla: Omit<Plantilla, 'id' | 'created_at'>) => {
    if (useLocalData) {
      const nueva: Plantilla = { ...plantilla, id: generateId() };
      setPlantillas(prev => [nueva, ...prev]);
      return nueva;
    }
    const resultado = await sendJson('crear plantilla', `${BASE_URL}/plantillas`, token, {
      method: 'POST',
      body: JSON.stringify(plantilla)
    });
    setPlantillas(prev => [resultado, ...prev]);
    return resultado;
  };

  const actualizarPlantilla = async (id: string, plantilla: Partial<Plantilla>) => {
    if (useLocalData) {
      setPlantillas(prev => prev.map(p => p.id === id ? { ...p, ...plantilla } : p));
      return;
    }
    const resultado = await sendJson('actualizar plantilla', `${BASE_URL}/plantillas/${id}`, token, {
      method: 'PUT',
      body: JSON.stringify(plantilla)
    });
    setPlantillas(prev => prev.map(p => p.id === id ? resultado : p));
    return resultado;
  };

  const eliminarPlantilla = async (id: string) => {
    if (useLocalData) {
      setPlantillas(prev => prev.filter(p => p.id !== id));
      return;
    }
    await sendJson('eliminar plantilla', `${BASE_URL}/plantillas/${id}`, token, {
      method: 'DELETE',
    });
    setPlantillas(prev => prev.filter(p => p.id !== id));
  };

  const guardarComoPlantilla = async (nombre: string, descripcion: string, cotizacion: { items: Plantilla['items']; nota?: string; con_factura?: boolean }) => {
    return crearPlantilla({
      nombre,
      descripcion,
      items: cotizacion.items,
      nota: cotizacion.nota,
      con_factura: cotizacion.con_factura ?? true
    });
  };

  // ─── Equipo e Invitaciones ────────────────────────────────────────────────

  const crearInvitacion = async (email: string, rol: 'admin' | 'usuario') => {
    const resultado = await sendJson('crear invitación', `${BASE_URL}/invitaciones`, token, {
      method: 'POST',
      body: JSON.stringify({ email, rol })
    });
    setInvitaciones(prev => [...prev, resultado]);
    return resultado;
  };

  const eliminarInvitacion = async (id: string) => {
    await sendJson('eliminar invitación', `${BASE_URL}/invitaciones/${id}`, token, {
      method: 'DELETE',
    });
    setInvitaciones(prev => prev.filter(i => i.id !== id));
  };

  // ─────────────────────────────────────────────────────────────────────────────

  // Función para exportar PDF
  const onExportPDF = (cotizacion: Cotizacion) => {
    const currentUrl = window.location.href;
    const baseUrl = currentUrl.split('?')[0];
    const pdfUrl = `${baseUrl}?pdf=${cotizacion.id}`;
    
    const printWindow = window.open(pdfUrl, '_blank', 'width=1200,height=800,scrollbars=yes,resizable=yes');
    
    if (printWindow) {
      printWindow.addEventListener('load', () => {
        setTimeout(() => {
          printWindow.print();
        }, 1000);
      });
    } else {
      window.location.href = pdfUrl;
    }
  };


  // Inventario
  const obtenerMovimientosInventario = async (): Promise<MovimientoInventario[]> => {
    try {
      const data = await fetchJson('obtener movimientos inventario', `${BASE_URL}/inventario/movimientos`, token);
      return data;
    } catch (error) {
      console.error('Error fetching movimientos:', error);
      throw error;
    }
  };

  const registrarMovimientoInventario = async (movimiento: Partial<MovimientoInventario>) => {
    try {
      const resultado = await sendJson('crear movimiento inventario', `${BASE_URL}/inventario/movimientos`, token, {
        method: 'POST',
        body: JSON.stringify(movimiento)
      });
      // Recargar productos para actualizar stock
      loadData();
      return resultado;
    } catch (error) {
      console.error('Error creating movimiento inventario:', error);
      throw error;
    }
  };

  return {
    categoriasProducto,
    categoriasCliente,
    crearCategoriaCliente,
    actualizarCategoriaCliente,
    eliminarCategoriaCliente,
    crearCategoriaProducto,
    actualizarCategoriaProducto,
    eliminarCategoriaProducto,

    // Datos
    clientes,
    productos,
    cotizaciones: cotizacionesConClientes,
    pagos,
    ajustes,
    plantillas,
    equipo,
    invitaciones,
    loading,
    serverError,
    useLocalData,

    // CRUD clientes
    crearCliente,
    actualizarCliente,
    eliminarCliente,
    // Inventario
    obtenerMovimientosInventario,
    registrarMovimientoInventario,
    // CRUD productos
    crearProducto,
    actualizarProducto,
    eliminarProducto,
    // CRUD cotizaciones
    crearCotizacion,
    actualizarCotizacion,
    eliminarCotizacion,
    duplicarCotizacion,
    generarTokenPortal,
    // Pagos
    crearPago,
    obtenerPagosPorCotizacion,
    calcularSaldoPendiente,
    // Ajustes
    actualizarAjustes,
    // Plantillas
    crearPlantilla,
    actualizarPlantilla,
    eliminarPlantilla,
    guardarComoPlantilla,
    // Equipo e Invitaciones
    crearInvitacion,
    eliminarInvitacion,

    // Eventos
    onExportPDF,

    // Utilities
    loadData
  };
}
