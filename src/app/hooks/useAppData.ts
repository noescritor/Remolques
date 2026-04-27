import { useState, useEffect } from 'react';
import { Cliente, Producto, Cotizacion, Pago, Ajustes } from '../types';
import { generarFolio } from '../utils/calculations';

// Mock data inicial
const mockClientes: Cliente[] = [
  {
    id: '1',
    nombre_razon_social: 'Empresa ABC S.A. de C.V.',
    nombre_contacto: 'Juan Pérez',
    telefono: '555-123-4567',
    correo: 'juan@empresaabc.com',
    direccion: 'Av. Principal 123',
    ciudad: 'Ciudad de México',
    estado: 'CDMX',
    codigo_postal: '01000',
    pais: 'México',
    tipo_pago_preferido: 'Transferencia'
  },
  {
    id: '2',
    nombre_razon_social: 'Constructora XYZ',
    nombre_contacto: 'María González',
    telefono: '555-987-6543',
    correo: 'maria@constructoraxyz.com',
    ciudad: 'Guadalajara',
    estado: 'Jalisco',
    pais: 'México',
    tipo_pago_preferido: 'Crédito 30 días'
  }
];

const mockProductos: Producto[] = [
  {
    id: '1',
    nombre: 'Consultoría en Sistemas',
    descripcion: 'Servicio de consultoría especializada',
    unidad: 'hr',
    precio_unitario: 1500.00,
    tasa_iva: 0.16
  },
  {
    id: '2',
    nombre: 'Licencia de Software',
    descripcion: 'Licencia anual de software empresarial',
    unidad: 'pz',
    precio_unitario: 25000.00,
    tasa_iva: 0.16
  },
  {
    id: '3',
    nombre: 'Soporte Técnico',
    descripcion: 'Soporte técnico especializado',
    unidad: 'mes',
    precio_unitario: 5000.00,
    tasa_iva: 0.16
  }
];

const mockCotizaciones: Cotizacion[] = [
  {
    id: '1',
    folio: '2025-00001',
    cliente_id: '1',
    fecha: '2025-01-15',
    validez_dias: 30,
    estado: 'Enviada',
    subtotal: 30000.00,
    iva: 4800.00,
    total: 34800.00,
    nota: 'Cotización para proyecto de implementación',
    items: [
      {
        id: '1',
        posicion: 1,
        cantidad: 20,
        unidad: 'hr',
        descripcion: 'Consultoría en Sistemas',
        numero_proyecto: 'PROJ-2025-001',
        precio_unitario: 1500.00,
        iva_item: 4800.00,
        total_item: 30000.00
      }
    ]
  }
];

const mockPagos: Pago[] = [
  {
    id: '1',
    cotizacion_id: '1',
    tipo_pago: 'Transferencia',
    referencia: 'TRF-001-2025',
    monto: 17400.00,
    fecha: '2025-01-20'
  }
];

const ajustesIniciales: Ajustes = {
  iva_por_defecto: 0.16,
  validez_por_defecto: 30,
  nota_por_defecto: 'Gracias por su preferencia. Esta cotización tiene una validez de {validez_dias} días.',
  prefijo_folio: '',
  offset_folio: 1
};

export function useAppData() {
  const [clientes, setClientes] = useState<Cliente[]>(mockClientes);
  const [productos, setProductos] = useState<Producto[]>(mockProductos);
  const [cotizaciones, setCotizaciones] = useState<Cotizacion[]>(mockCotizaciones);
  const [pagos, setPagos] = useState<Pago[]>(mockPagos);
  const [ajustes, setAjustes] = useState<Ajustes>(ajustesIniciales);
  const [loading, setLoading] = useState(false);

  // Relaciones
  const cotizacionesConClientes = cotizaciones.map(cotizacion => ({
    ...cotizacion,
    cliente: clientes.find(c => c.id === cotizacion.cliente_id)
  }));

  // CRUD Clientes
  const crearCliente = (cliente: Omit<Cliente, 'id'>) => {
    const nuevoCliente = {
      ...cliente,
      id: Date.now().toString()
    };
    setClientes(prev => [...prev, nuevoCliente]);
    return nuevoCliente;
  };

  const actualizarCliente = (id: string, cliente: Partial<Cliente>) => {
    setClientes(prev => prev.map(c => c.id === id ? { ...c, ...cliente } : c));
  };

  const eliminarCliente = (id: string) => {
    setClientes(prev => prev.filter(c => c.id !== id));
  };

  // CRUD Productos
  const crearProducto = (producto: Omit<Producto, 'id'>) => {
    const nuevoProducto = {
      ...producto,
      id: Date.now().toString()
    };
    setProductos(prev => [...prev, nuevoProducto]);
    return nuevoProducto;
  };

  const actualizarProducto = (id: string, producto: Partial<Producto>) => {
    setProductos(prev => prev.map(p => p.id === id ? { ...p, ...producto } : p));
  };

  const eliminarProducto = (id: string) => {
    setProductos(prev => prev.filter(p => p.id !== id));
  };

  // CRUD Cotizaciones
  const crearCotizacion = (cotizacion: Omit<Cotizacion, 'id' | 'folio'>) => {
    const ultimaFolio = Math.max(...cotizaciones.map(c => parseInt(c.folio.split('-')[1]) || 0), 0);
    const nuevoCotizacion = {
      ...cotizacion,
      id: Date.now().toString(),
      folio: generarFolio(ajustes.prefijo_folio, ultimaFolio + 1)
    };
    setCotizaciones(prev => [...prev, nuevoCotizacion]);
    return nuevoCotizacion;
  };

  const actualizarCotizacion = (id: string, cotizacion: Partial<Cotizacion>) => {
    setCotizaciones(prev => prev.map(c => c.id === id ? { ...c, ...cotizacion } : c));
  };

  const eliminarCotizacion = (id: string) => {
    setCotizaciones(prev => prev.filter(c => c.id !== id));
    setPagos(prev => prev.filter(p => p.cotizacion_id !== id));
  };

  const duplicarCotizacion = (id: string) => {
    const cotizacion = cotizaciones.find(c => c.id === id);
    if (cotizacion) {
      const ultimaFolio = Math.max(...cotizaciones.map(c => parseInt(c.folio.split('-')[1]) || 0), 0);
      const cotizacionDuplicada = {
        ...cotizacion,
        id: Date.now().toString(),
        folio: generarFolio(ajustes.prefijo_folio, ultimaFolio + 1),
        estado: 'Borrador' as const,
        fecha: new Date().toISOString().split('T')[0],
        items: cotizacion.items.map(item => ({
          ...item,
          id: Date.now().toString() + Math.random()
        }))
      };
      setCotizaciones(prev => [...prev, cotizacionDuplicada]);
      return cotizacionDuplicada;
    }
  };

  // CRUD Pagos
  const crearPago = (pago: Omit<Pago, 'id'>) => {
    const nuevoPago = {
      ...pago,
      id: Date.now().toString()
    };
    setPagos(prev => [...prev, nuevoPago]);
    
    // Verificar si la cotización debe marcarse como pagada
    const pagosCotizacion = [...pagos, nuevoPago].filter(p => p.cotizacion_id === pago.cotizacion_id);
    const totalPagado = pagosCotizacion.reduce((sum, p) => sum + p.monto, 0);
    const cotizacion = cotizaciones.find(c => c.id === pago.cotizacion_id);
    
    if (cotizacion && Math.abs(totalPagado - cotizacion.total) < 0.01) {
      actualizarCotizacion(pago.cotizacion_id, { estado: 'Pagada' });
    }
    
    return nuevoPago;
  };

  const obtenerPagosPorCotizacion = (cotizacionId: string) => {
    return pagos.filter(p => p.cotizacion_id === cotizacionId);
  };

  const calcularSaldoPendiente = (cotizacionId: string) => {
    const cotizacion = cotizaciones.find(c => c.id === cotizacionId);
    const pagosCotizacion = obtenerPagosPorCotizacion(cotizacionId);
    const totalPagado = pagosCotizacion.reduce((sum, p) => sum + p.monto, 0);
    return (cotizacion?.total || 0) - totalPagado;
  };

  // Ajustes
  const actualizarAjustes = (nuevosAjustes: Partial<Ajustes>) => {
    setAjustes(prev => ({ ...prev, ...nuevosAjustes }));
  };

  // Eventos placeholders para integración futura
  const onExportPDF = (cotizacion: Cotizacion) => {
    console.log('Exportar PDF:', cotizacion);
    // Placeholder para integración futura
  };

  return {
    // Datos
    clientes,
    productos,
    cotizaciones: cotizacionesConClientes,
    pagos,
    ajustes,
    loading,
    
    // CRUD
    crearCliente,
    actualizarCliente,
    eliminarCliente,
    crearProducto,
    actualizarProducto,
    eliminarProducto,
    crearCotizacion,
    actualizarCotizacion,
    eliminarCotizacion,
    duplicarCotizacion,
    crearPago,
    obtenerPagosPorCotizacion,
    calcularSaldoPendiente,
    actualizarAjustes,
    
    // Eventos
    onExportPDF
  };
}