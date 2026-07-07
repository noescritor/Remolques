import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog';
import { Alert, AlertDescription } from '../ui/alert';
import { ArrowLeft, Plus, Trash2, FileDown, Copy, Save, UserPlus, Eye, BookTemplate, FileSpreadsheet, Sparkles, Loader2 , AlertTriangle} from 'lucide-react';
import { Cliente, Cotizacion, ItemCotizacion, Producto, EstadoCotizacion, TRANSICIONES_ESTADO, CostosIndirectos, ComisionesPago, Plantilla } from '../../types';
import { ExcelImportModal } from './ExcelImportModal';
import { supabase } from '../../utils/supabase/client';
import { calcularItemCotizacion, calcularTotalesCotizacion, formatearMoneda, calcularAnalisisCompleto, calcularUtilidadItem, calcularTotalesCotizacionServiciosAware, totalItemServicio } from '../../utils/calculations';
import { ClienteModal } from '../Clientes/ClienteModal';
import { AnalisisUtilidad } from './AnalisisUtilidad';
import { CostosIndirectos as CostosIndirectosComponent } from './CostosIndirectos';



interface CotizacionEditorProps {
  cotizacion?: Cotizacion;
  clientes: Cliente[];
  productos: Producto[];
  plantillas?: Plantilla[];
  ajustes: any;
  onGuardar: (cotizacion: Omit<Cotizacion, 'id' | 'folio'> | Partial<Cotizacion>) => void;
  onVolver: () => void;
  onExportPDF: (cotizacion: Cotizacion) => void;
  onVerPDF?: (cotizacion: Cotizacion) => void;
  onDuplicar?: (id: string) => void;
  onCrearCliente: (cliente: Omit<Cliente, 'id'>) => Promise<Cliente> | Cliente;
  onGuardarComoPlantilla?: (nombre: string, descripcion: string, data: { items: ItemCotizacion[]; nota?: string; con_factura?: boolean }) => Promise<Plantilla>;
  esNueva?: boolean;
}

export function CotizacionEditor({
  cotizacion,
  clientes,
  productos,
  plantillas = [],
  ajustes,
  onGuardar,
  onVolver,
  onExportPDF,
  onVerPDF,
  onDuplicar,
  onCrearCliente,
  onGuardarComoPlantilla,
  esNueva = false
}: CotizacionEditorProps) {
  const [formData, setFormData] = useState({
    cliente_id: '',
    contacto_id: '' as string | undefined,
    fecha: new Date().toISOString().split('T')[0],
    validez_dias: ajustes.validez_por_defecto,
    estado: 'Borrador' as EstadoCotizacion,
    con_factura: true,
    descripcion: '',
    nota: ajustes.nota_por_defecto,
    items: [] as ItemCotizacion[],
    costos_indirectos: {
      mano_obra: 0,
      insumos_dtf: 0,
      empaque: 0,
      mermas: 0,
      envio: 0,
      otros: 0
    },
    comisiones_pago: {
      porcentaje: 0,
      fijo: 0
    }
  });

  const [errores, setErrores] = useState<string[]>([]);
  const [clienteModalOpen, setClienteModalOpen] = useState(false);
  const [busquedaCliente, setBusquedaCliente] = useState('');
  const [showClienteDropdown, setShowClienteDropdown] = useState(false);
  const [busquedaProducto, setBusquedaProducto] = useState('');
  const [showProductoDropdown, setShowProductoDropdown] = useState(false);
  const [showVersionDialog, setShowVersionDialog] = useState(false);
  const [showPlantillasModal, setShowPlantillasModal] = useState(false);
  const [showGuardarPlantillaModal, setShowGuardarPlantillaModal] = useState(false);
  const [nombreNuevaPlantilla, setNombreNuevaPlantilla] = useState('');
  const [descripcionNuevaPlantilla, setDescripcionNuevaPlantilla] = useState('');
  const [guardandoPlantilla, setGuardandoPlantilla] = useState(false);
  const [showExcelModal, setShowExcelModal] = useState(false);
  const [iaLoadingItemId, setIaLoadingItemId] = useState<string | null>(null);
  const [iaLoadingNota, setIaLoadingNota] = useState(false);

  useEffect(() => {
    if (cotizacion) {
      setFormData({
        cliente_id: cotizacion.cliente_id,
        contacto_id: cotizacion.contacto_id || '',
        fecha: cotizacion.fecha,
        validez_dias: cotizacion.validez_dias,
        estado: cotizacion.estado,
        con_factura: cotizacion.con_factura !== false, // Por defecto true si no está definido
        descripcion: cotizacion.descripcion || '',
        nota: cotizacion.nota || '',
        items: cotizacion.items,
        costos_indirectos: cotizacion.costos_indirectos || {
          mano_obra: 0,
          insumos_dtf: 0,
          empaque: 0,
          mermas: 0,
          envio: 0,
          otros: 0
        },
        comisiones_pago: cotizacion.comisiones_pago || {
          porcentaje: 0,
          fijo: 0
        }
      });
    }
  }, [cotizacion]);

  const clientesFiltrados = clientes.filter(cliente => {
    if (!cliente) return false;
    if (!busquedaCliente.trim()) return true; // Mostrar todos si no hay búsqueda
    const busquedaLower = busquedaCliente.toLowerCase();
    return (
      (cliente.nombre_razon_social || '').toLowerCase().includes(busquedaLower) ||
      (cliente.correo || '').toLowerCase().includes(busquedaLower) ||
      (cliente.telefono || '').includes(busquedaCliente)
    );
  });

  const productosFiltrados = productos.filter(producto => {
    if (!producto) return false;
    if (!busquedaProducto.trim()) return true; // Mostrar todos si no hay búsqueda
    const busquedaLower = busquedaProducto.toLowerCase();
    return (
      (producto.nombre || '').toLowerCase().includes(busquedaLower) ||
      (producto.descripcion || '').toLowerCase().includes(busquedaLower) ||
      (producto.id || '').toLowerCase().includes(busquedaLower)
    );
  });

  const clienteSeleccionado = clientes.find(c => c?.id === formData.cliente_id);
  
  // Crear índice de productos para búsquedas rápidas
  const productosIdx = productos.reduce((acc, producto) => {
    if (producto?.id) {
      acc[producto.id] = producto;
    }
    return acc;
  }, {} as Record<string, Producto>);
  
  const totales = calcularTotalesCotizacionServiciosAware(
    formData.items, 
    productosIdx, 
    ajustes.iva_por_defecto, 
    formData.con_factura
  );

  const agregarItem = () => {
    const nuevoItem: ItemCotizacion = {
      id: Date.now().toString(),
      posicion: formData.items.length + 1,
      cantidad: 1,
      unidad: 'pz',
      descripcion: '',
      precio_unitario: 0,
      iva_item: 0,
      total_item: 0
    };
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, nuevoItem]
    }));
  };

  const agregarItemDesdeProducto = (producto: Producto) => {
    let nuevoItem: ItemCotizacion;

    if (producto.tipo === 'servicio' && producto.servicio) {
      // Para servicios, usamos valores por defecto y permitimos configuración posterior
      const servicio = producto.servicio;
      nuevoItem = {
        id: Date.now().toString(),
        producto_id: producto.id,
        posicion: formData.items.length + 1,
        cantidad: 1, // Para servicios puede representar base/asientos
        unidad: producto.unidad || 'servicio',
        descripcion: producto.nombre,
        incluir_setup: servicio.modo === 'unico' || servicio.modo === 'hibrido',
        meses_cobrados: 1,
        asientos_extra: 0,
        iva_item: 0, // Se calculará dinámicamente
        total_item: 0, // Se calculará dinámicamente
        numero_proyecto: producto.id
      };
    } else {
      // Para bienes, mantener la lógica existente
      const { iva_item, total_item } = calcularItemCotizacion(
        1,
        producto.precio_unitario || 0,
        formData.con_factura ? ajustes.iva_por_defecto : 0
      );
      
      nuevoItem = {
        id: Date.now().toString(),
        producto_id: producto.id,
        posicion: formData.items.length + 1,
        cantidad: 1,
        unidad: producto.unidad || 'pz',
        descripcion: producto.nombre,
        precio_unitario: producto.precio_unitario,
        costo_unitario: producto.costo || 0,
        iva_item,
        total_item,
        numero_proyecto: producto.id
      };
    }
    
    setFormData(prev => ({
      ...prev,
      items: [...prev.items, nuevoItem]
    }));
    
    setBusquedaProducto('');
    setShowProductoDropdown(false);
  };

  const actualizarItem = (itemId: string, cambios: Partial<ItemCotizacion>) => {
    setFormData(prev => ({
      ...prev,
      items: prev.items.map(item => {
        if (item?.id === itemId) {
          const itemActualizado = { ...item, ...cambios };
          
          // Recalcular totales si cambia cantidad o precio
          if ('cantidad' in cambios || 'precio_unitario' in cambios) {
            const { iva_item, total_item } = calcularItemCotizacion(
              itemActualizado.cantidad,
              itemActualizado.precio_unitario,
              ajustes.iva_por_defecto
            );
            itemActualizado.iva_item = iva_item;
            itemActualizado.total_item = total_item;
          }
          
          return itemActualizado;
        }
        return item;
      })
    }));
  };

  const eliminarItem = (itemId: string) => {
    setFormData(prev => ({
      ...prev,
      items: prev.items.filter(item => item?.id !== itemId).map((item, index) => ({
        ...item,
        posicion: index + 1
      }))
    }));
  };

  const duplicarItem = (itemId: string) => {
    const item = formData.items.find(i => i?.id === itemId);
    if (item) {
      const itemDuplicado = {
        ...item,
        id: Date.now().toString(),
        posicion: formData.items.length + 1
      };
      setFormData(prev => ({
        ...prev,
        items: [...prev.items, itemDuplicado]
      }));
    }
  };

  const validarFormulario = (): string[] => {
    const errores = [];
    
    if (!formData.cliente_id) {
      errores.push('Debe seleccionar un cliente');
    }
    
    if (formData.items.length === 0) {
      errores.push('Debe agregar al menos un concepto');
    }
    
    formData.items.forEach((item, index) => {
      if (item.cantidad <= 0) {
        errores.push(`La cantidad del concepto ${index + 1} debe ser mayor a 0`);
      }
      if (item.precio_unitario < 0) {
        errores.push(`El precio unitario del concepto ${index + 1} no puede ser negativo`);
      }
      if (!item.descripcion.trim()) {
        errores.push(`La descripción del concepto ${index + 1} es requerida`);
      }
    });
    
    return errores;
  };

  // Strips internal-only fields (costo/utilidad/margen) that are not columns in the DB
  const totalesBD = (() => {
    const { costo: _c, utilidad: _u, margen: _m, ...rest } = totales;
    return rest;
  })();

  const manejarGuardar = () => {
    const erroresValidacion = validarFormulario();
    if (erroresValidacion.length > 0) {
      setErrores(erroresValidacion);
      return;
    }

    setErrores([]);

    const datosParaGuardar = {
      ...formData,
      ...totalesBD
    };

    // Lógica de versiones (Fase 2)
    // Si la cotización ya existe y NO es borrador, preguntamos si desea crear una versión nueva
    if (!esNueva && cotizacion && (cotizacion.estado === 'Enviada' || cotizacion.estado === 'Aprobada')) {
      setShowVersionDialog(true);
      return;
    }
    
    onGuardar(datosParaGuardar);
  };

  const confirmarGuardarComoVersion = () => {
    const datosParaGuardar = {
      ...formData,
      ...totalesBD,
      estado: 'Borrador' as EstadoCotizacion,
      cotizacion_padre_id: cotizacion?.id,
      version: (cotizacion?.version || 1) + 1
    };
    
    // Al guardar como versión, tratamos esto como una "Nueva" cotización
    // para que el backend genere un nuevo ID/Folio o maneje la relación
    onGuardar(datosParaGuardar);
    setShowVersionDialog(false);
  };

  const importarDesdeExcel = (items: Omit<ItemCotizacion, 'id' | 'posicion'>[]) => {
    const nuevos: ItemCotizacion[] = items.map((item, i) => ({
      ...item,
      id: Date.now().toString() + i,
      posicion: formData.items.length + i + 1
    }));
    setFormData(prev => ({ ...prev, items: [...prev.items, ...nuevos] }));
  };

  const getIaHeaders = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    const token = session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY;
    return { 'Content-Type': 'application/json', 'Authorization': `Bearer ${token}` };
  };

  const mejorarDescripcionConIA = async (itemId: string) => {
    const item = formData.items.find(i => i.id === itemId);
    if (!item?.descripcion.trim()) return;
    setIaLoadingItemId(itemId);
    try {
      const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;
      const response = await fetch(`${BASE_URL}/ia/mejorar-descripcion`, {
        method: 'POST',
        headers: await getIaHeaders(),
        body: JSON.stringify({ descripcion: item.descripcion })
      });
      const data = await response.json();
      if (data.descripcion_mejorada) {
        actualizarItem(itemId, { descripcion: data.descripcion_mejorada });
      }
    } catch {
      // Silencioso — la descripción original se mantiene
    } finally {
      setIaLoadingItemId(null);
    }
  };

  const generarNotaConIA = async () => {
    setIaLoadingNota(true);
    try {
      const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;
      const cliente = clientes.find(c => c.id === formData.cliente_id);
      const response = await fetch(`${BASE_URL}/ia/generar-nota`, {
        method: 'POST',
        headers: await getIaHeaders(),
        body: JSON.stringify({
          cliente: cliente?.nombre_razon_social,
          descripcion: formData.descripcion,
          items: formData.items
        })
      });
      const data = await response.json();
      if (data.nota) {
        setFormData(prev => ({ ...prev, nota: data.nota }));
      }
    } catch {
      // Silencioso
    } finally {
      setIaLoadingNota(false);
    }
  };

  const aplicarPlantilla = (plantilla: Plantilla) => {
    setFormData(prev => ({
      ...prev,
      items: plantilla.items.map(item => ({ ...item, id: Date.now().toString() + Math.random() })),
      nota: plantilla.nota || prev.nota,
      con_factura: plantilla.con_factura ?? prev.con_factura
    }));
    setShowPlantillasModal(false);
  };

  const handleGuardarComoPlantilla = async () => {
    if (!nombreNuevaPlantilla.trim() || !onGuardarComoPlantilla) return;
    setGuardandoPlantilla(true);
    try {
      await onGuardarComoPlantilla(nombreNuevaPlantilla, descripcionNuevaPlantilla, {
        items: formData.items,
        nota: formData.nota,
        con_factura: formData.con_factura
      });
      setShowGuardarPlantillaModal(false);
      setNombreNuevaPlantilla('');
      setDescripcionNuevaPlantilla('');
    } finally {
      setGuardandoPlantilla(false);
    }
  };

  const confirmarSobreesscribir = () => {
    const datosParaGuardar = {
      ...formData,
      ...totalesBD
    };
    onGuardar(datosParaGuardar);
    setShowVersionDialog(false);
  };

  const manejarCrearCliente = async (nuevoCliente: Omit<Cliente, 'id'>) => {
    const clienteCreado = await onCrearCliente(nuevoCliente);
    if (clienteCreado?.id) {
      setFormData(prev => ({ ...prev, cliente_id: clienteCreado.id }));
    }
    setClienteModalOpen(false);
  };

  const transicionesPermitidas = cotizacion ? TRANSICIONES_ESTADO[cotizacion.estado] : [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
        <div className="flex items-center gap-2 sm:gap-4">
          <Button variant="outline" size="sm" onClick={onVolver}>
            <ArrowLeft className="h-4 w-4 sm:mr-2" />
            <span className="hidden sm:inline">{esNueva ? 'Volver' : 'Volver'}</span>
          </Button>
          <h1 className="text-sm sm:text-base font-semibold truncate">{esNueva ? 'Nueva Cotización' : `${cotizacion?.folio}`}</h1>
        </div>
        
        <div className="flex gap-1.5 sm:gap-2 flex-wrap">
          {plantillas.length > 0 && esNueva && (
            <Button variant="outline" size="sm" onClick={() => setShowPlantillasModal(true)} title="Usar Plantilla">
              <BookTemplate className="h-4 w-4 sm:mr-2" />
              <span className="hidden sm:inline">Plantilla</span>
            </Button>
          )}

          {formData.items.length > 0 && onGuardarComoPlantilla && (
            <Button variant="outline" size="sm" onClick={() => setShowGuardarPlantillaModal(true)} title="Guardar como Plantilla">
              <BookTemplate className="h-4 w-4 sm:mr-2" />
              <span className="hidden sm:inline">Guardar Plantilla</span>
            </Button>
          )}

          <Button variant="outline" size="sm" onClick={() => setShowExcelModal(true)} title="Importar Excel">
            <FileSpreadsheet className="h-4 w-4 sm:mr-2" />
            <span className="hidden sm:inline">Excel</span>
          </Button>

          <Button size="sm" onClick={manejarGuardar} title="Guardar">
            <Save className="h-4 w-4 sm:mr-2" />
            <span className="hidden sm:inline">Guardar</span>
          </Button>

          {cotizacion && (
            <>
              {onVerPDF && (
                <Button variant="outline" size="sm" onClick={() => onVerPDF(cotizacion)} title="Vista Previa PDF">
                  <Eye className="h-4 w-4 sm:mr-2" />
                  <span className="hidden sm:inline">PDF</span>
                </Button>
              )}
              
              <Button variant="outline" size="sm" onClick={() => onExportPDF(cotizacion)} title="Exportar PDF">
                <FileDown className="h-4 w-4 sm:mr-2" />
                <span className="hidden sm:inline">Exportar</span>
              </Button>
              
              {onDuplicar && (
                <Button variant="outline" size="sm" onClick={() => onDuplicar(cotizacion.id)} title="Duplicar">
                  <Copy className="h-4 w-4 sm:mr-2" />
                  <span className="hidden sm:inline">Duplicar</span>
                </Button>
              )}
            </>
          )}
        </div>
      </div>

      {/* Dialogo de Versiones (Fase 2) */}
      <Dialog open={showVersionDialog} onOpenChange={setShowVersionDialog}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>¿Crear una nueva versión?</DialogTitle>
            <DialogDescription>
              Esta cotización ya ha sido <strong>{cotizacion?.estado}</strong>. 
              Se recomienda crear una nueva versión (v{(cotizacion?.version || 1) + 1}) para mantener el historial.
            </DialogDescription>
          </DialogHeader>
          <div className="py-4 space-y-4">
            <div className="bg-amber-50 p-3 rounded-md text-sm text-amber-800 border border-amber-200">
              <strong>Nota:</strong> Si eliges "Nueva Versión", la cotización actual se mantendrá intacta y se creará un nuevo borrador.
            </div>
          </div>
          <DialogFooter className="flex flex-col sm:flex-row gap-2">
            <Button variant="outline" className="sm:flex-1" onClick={confirmarSobreesscribir}>
              Sobreesscribir actual
            </Button>
            <Button className="sm:flex-1 bg-purple-600 hover:bg-purple-700" onClick={confirmarGuardarComoVersion}>
              Crear v{(cotizacion?.version || 1) + 1}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {errores.length > 0 && (
        <Alert>
          <AlertDescription>
            <ul className="list-disc list-inside">
              {errores.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      {/* Encabezado de Cotización */}
      <Card>
        <CardHeader>
          <CardTitle>Encabezado de Cotización</CardTitle>
        </CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <Label>Folio</Label>
            <Input value={cotizacion?.folio || 'Se asignar�� al guardar'} disabled />
          </div>
          
          <div>
            <Label>Fecha</Label>
            <Input
              type="date"
              value={formData.fecha}
              onChange={(e) => setFormData(prev => ({ ...prev, fecha: e.target.value }))}
            />
          </div>
          
          <div>
            <Label>Validez (días)</Label>
            <Input
              type="number"
              value={formData.validez_dias}
              onChange={(e) => setFormData(prev => ({ ...prev, validez_dias: parseInt(e.target.value) }))}
            />
          </div>

          <div className="flex items-center gap-3">
            <Label>Con factura (incluye IVA)</Label>
            <Switch
              checked={formData.con_factura}
              onCheckedChange={(checked) => setFormData(prev => ({ ...prev, con_factura: checked }))}
            />
            <span className="text-sm text-muted-foreground">
              {formData.con_factura ? 'Se cobrará IVA' : 'Sin IVA'}
            </span>
          </div>

          <div>
            <Label>Descripción de la cotización</Label>
            <Input
              placeholder="Ej: Diseño de identidad corporativa, Desarrollo web e-commerce, etc."
              value={formData.descripcion}
              onChange={(e) => setFormData(prev => ({ ...prev, descripcion: e.target.value }))}
            />
          </div>
          
          {!esNueva && (
            <div>
              <Label>Estado</Label>
              <Select 
                value={formData.estado} 
                onValueChange={(value: EstadoCotizacion) => setFormData(prev => ({ ...prev, estado: value }))}
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={formData.estado}>{formData.estado}</SelectItem>
                  {transicionesPermitidas.map(estado => (
                    <SelectItem key={estado} value={estado}>{estado}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
          )}
        </CardContent>
      </Card>

      {/* Cliente */}
      <Card>
        <CardHeader>
          <CardTitle>Cliente</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex gap-4 items-end">
            <div className="flex-1">
              <Label>Buscar Cliente</Label>
              <div className="relative">
                <Input
                  placeholder="Buscar por nombre, correo o teléfono..."
                  value={busquedaCliente}
                  onChange={(e) => setBusquedaCliente(e.target.value)}
                  onFocus={() => setShowClienteDropdown(true)}
                  onBlur={() => setTimeout(() => setShowClienteDropdown(false), 200)}
                />
                
                {showClienteDropdown && (
                  <div className="absolute z-10 w-full mt-1 border border-white/10 rounded-md bg-[var(--surface-secondary)] shadow-lg max-h-40 overflow-y-auto">
                    {clientesFiltrados.length > 0 ? (
                      clientesFiltrados.map(cliente => cliente ? (
                        <div
                          key={cliente.id}
                          className="p-2 hover:bg-white/[0.06] cursor-pointer border-b border-white/[0.06] last:border-b-0"
                          onClick={() => {
                            setFormData(prev => ({ ...prev, cliente_id: cliente.id }));
                            setBusquedaCliente('');
                            setShowClienteDropdown(false);
                          }}
                        >
                          <div className="font-medium text-white">{cliente.nombre_razon_social}</div>
                          <div className="text-sm text-muted-foreground">
                            {cliente.correo} • {cliente.telefono}
                          </div>
                        </div>
                      ) : null)
                    ) : (
                      <div className="p-2 text-muted-foreground text-center">
                        {clientes.length === 0 ? 'No hay clientes registrados' : 'No se encontraron clientes'}
                      </div>
                    )}
                  </div>
                )}
              </div>
              
              {clienteSeleccionado && !showClienteDropdown && (
                <div className="mt-2 p-3 bg-accent-blue/10 border border-accent-blue/20 rounded-md">
                  <div className="font-medium text-white">{clienteSeleccionado.nombre_razon_social}</div>
                  <div className="text-sm text-muted-foreground">
                    {clienteSeleccionado.correo} • {clienteSeleccionado.telefono}
                  </div>
                  <Button 
                    variant="ghost" 
                    size="sm" 
                    className="mt-1 h-6 px-2 text-xs"
                    onClick={() => {
                      setFormData(prev => ({ ...prev, cliente_id: '', contacto_id: '' }));
                      setBusquedaCliente('');
                    }}
                  >
                    Cambiar cliente
                  </Button>

                  {/* Selector de Contacto */}
                  {clienteSeleccionado.contactos && clienteSeleccionado.contactos.length > 0 && (
                    <div className="mt-3 pt-3 border-t border-accent-blue/20">
                      <Label className="text-xs text-accent-blue font-medium">¿Quién solicita esta cotización?</Label>
                      <Select
                        value={formData.contacto_id || '_none'}
                        onValueChange={(value) => setFormData(prev => ({ ...prev, contacto_id: value === '_none' ? '' : value }))}
                      >
                        <SelectTrigger className="mt-1 bg-transparent text-sm h-9">
                          <SelectValue placeholder="Seleccionar contacto..." />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="_none">— Sin contacto específico —</SelectItem>
                          {clienteSeleccionado.contactos.map((contacto) => (
                            <SelectItem key={contacto.id} value={contacto.id}>
                              <span className="font-medium">{contacto.nombre}</span>
                              {contacto.departamento && <span className="text-muted-foreground"> · {contacto.departamento}</span>}
                              {contacto.puesto && <span className="text-muted-foreground"> ({contacto.puesto})</span>}
                            </SelectItem>
                          ))}
                        </SelectContent>
                      </Select>
                      {formData.contacto_id && (() => {
                        const c = clienteSeleccionado.contactos?.find(x => x.id === formData.contacto_id);
                        if (!c) return null;
                        return (
                          <div className="mt-1.5 text-xs text-muted-foreground flex gap-3">
                            {c.correo && <span>📧 {c.correo}</span>}
                            {c.telefono && <span>📱 {c.telefono}</span>}
                          </div>
                        );
                      })()}
                    </div>
                  )}
                </div>
              )}
            </div>
            
            <Dialog open={clienteModalOpen} onOpenChange={setClienteModalOpen}>
              <DialogTrigger asChild>
                <Button variant="outline">
                  <UserPlus className="mr-2 h-4 w-4" />
                  Crear Cliente
                </Button>
              </DialogTrigger>
              <DialogContent className="max-w-2xl">
                <DialogHeader>
                  <DialogTitle>Crear Cliente Rápido</DialogTitle>
                  <DialogDescription>
                    Crea un nuevo cliente con los datos básicos para usar en esta cotización.
                  </DialogDescription>
                </DialogHeader>
                <ClienteModal onGuardar={manejarCrearCliente} onCancelar={() => setClienteModalOpen(false)} />
              </DialogContent>
            </Dialog>
          </div>
        </CardContent>
      </Card>

      {/* Análisis de Utilidad */}
      {formData.items.length > 0 && (
        <AnalisisUtilidad 
          analisis={calcularAnalisisCompleto(formData, productos)} 
        />
      )}

      {/* Conceptos */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Conceptos</CardTitle>
            <div className="flex gap-2">
              <Button variant="outline" onClick={agregarItem}>
                <Plus className="mr-2 h-4 w-4" />
                Concepto Manual
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent>
          {/* Selector de productos */}
          <div className="mb-4">
            <Label>Agregar Producto</Label>
            <div className="relative">
              <Input
                placeholder="Buscar productos por nombre, ID o descripción..."
                value={busquedaProducto}
                onChange={(e) => setBusquedaProducto(e.target.value)}
                onFocus={() => setShowProductoDropdown(true)}
                onBlur={() => setTimeout(() => setShowProductoDropdown(false), 200)}
              />
              
              {showProductoDropdown && productosFiltrados.length > 0 && (
                <div className="absolute z-10 w-full mt-1 border border-white/10 rounded-md bg-[var(--surface-secondary)] shadow-lg max-h-40 overflow-y-auto">
                  {productosFiltrados.map(producto => producto ? (
                    <div
                      key={producto.id}
                      className="p-2 hover:bg-white/[0.06] cursor-pointer border-b border-white/[0.06] last:border-b-0"
                      onClick={() => agregarItemDesdeProducto(producto)}
                    >
                      <div className="flex justify-between items-start">
                        <div className="flex-1">
                          <div className="font-medium text-white">{producto.nombre}</div>
                          {producto.descripcion && <div className="text-sm text-muted-foreground">{producto.descripcion}</div>}
                          <div className="text-xs text-muted-foreground/60">ID: {producto.id}</div>
                        </div>
                        <div className="text-right ml-2">
                          <div className="font-medium text-white">{formatearMoneda(producto.precio_unitario)}</div>
                          <div className="text-xs text-muted-foreground">{producto.unidad}</div>
                        </div>
                      </div>
                    </div>
                  ) : null)}
                </div>
              )}
              
              {showProductoDropdown && productosFiltrados.length === 0 && (
                <div className="absolute z-10 w-full mt-1 border border-white/10 rounded-md bg-[var(--surface-secondary)] shadow-lg p-2 text-muted-foreground text-center">
                  {productos.length === 0 ? 'No hay productos registrados. Crea productos en la sección "Productos".' : 'No se encontraron productos'}
                </div>
              )}
            </div>
          </div>

          {formData.items.length === 0 ? (
            <div className="text-center py-8 text-gray-500">
              No hay conceptos agregados. Busca un producto arriba o haz clic en "Concepto Manual" para comenzar.
            </div>
          ) : (
            <>
              {/* ─── MOBILE: Card-based layout ─── */}
              <div className="md:hidden space-y-3">
                {formData.items.map((item) => {
                  if (!item) return null;
                  const producto = item.producto_id ? productosIdx[item.producto_id] : null;
                  const esServicio = producto?.tipo === 'servicio';
                  const disponible = (producto?.stock_actual || 0) - (producto?.stock_reservado || 0);
                  const advertenciaStock = producto?.tipo === 'bien' && (item.cantidad || 0) > disponible;

                  let totalCalculado = { subtotal: 0, iva: 0, total: 0, costoTotal: 0 };
                  if (esServicio && producto?.servicio) {
                    totalCalculado = totalItemServicio(item, producto, formData.con_factura ? ajustes.iva_por_defecto : 0);
                  } else {
                    const base = (item.cantidad || 0) * (item.precio_unitario || 0);
                    const iva = formData.con_factura ? base * ajustes.iva_por_defecto : 0;
                    totalCalculado = { subtotal: base, iva, total: base + iva, costoTotal: (item.cantidad || 0) * (item.costo_unitario || 0) };
                  }
                  return (
                    <div key={item.id} className="border rounded-lg p-3 bg-white space-y-2">
                      <div className="flex justify-between items-start">
                        <span className="text-xs text-gray-400 font-mono">#{item.posicion}</span>
                        <div className="flex gap-1">
                          <Button variant="ghost" size="sm" className="h-7 w-7 p-0" onClick={() => duplicarItem(item.id)}><Copy className="h-3.5 w-3.5" /></Button>
                          <Button variant="ghost" size="sm" className="h-7 w-7 p-0 text-red-500" onClick={() => eliminarItem(item.id)}><Trash2 className="h-3.5 w-3.5" /></Button>
                        </div>
                      </div>
                      <Input value={item.descripcion} onChange={(e) => actualizarItem(item.id, { descripcion: e.target.value })} placeholder="Descripción" className="text-sm" />
                      <div className="grid grid-cols-3 gap-2">
                        <div>
                          <Label className="text-xs text-gray-500">Cant.</Label>
                          <Input type="number" value={item.cantidad} onChange={(e) => actualizarItem(item.id, { cantidad: parseFloat(e.target.value) || 0 })} className={`text-sm ${advertenciaStock ? 'border-orange-500 bg-orange-50' : ''}`} min="0" step="0.01" />
                          {advertenciaStock && (
                            <div className="flex items-center text-orange-600 text-[10px] mt-1 font-semibold leading-tight">
                              <AlertTriangle className="w-3 h-3 mr-1" />
                              Stock dispo: {disponible}
                            </div>
                          )}
                        </div>
                        <div>
                          <Label className="text-xs text-gray-500">Precio</Label>
                          {esServicio ? (
                            <div className="text-sm text-gray-500 py-1.5">{formatearMoneda(totalCalculado.subtotal)}</div>
                          ) : (
                            <Input type="number" value={item.precio_unitario || 0} onChange={(e) => actualizarItem(item.id, { precio_unitario: parseFloat(e.target.value) || 0 })} className="text-sm" min="0" step="0.01" />
                          )}
                        </div>
                        <div>
                          <Label className="text-xs text-gray-500">Total</Label>
                          <div className="text-sm font-semibold py-1.5">{formatearMoneda(totalCalculado.total)}</div>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* ─── DESKTOP: Table layout ─── */}
              <div className="hidden md:block">
              <Table>
              <TableHeader>
                <TableRow>
                  <TableHead className="w-16">Pos</TableHead>
                  <TableHead className="w-20">Cant.</TableHead>
                  <TableHead className="w-20">Unidad</TableHead>
                  <TableHead>Descripción</TableHead>
                  <TableHead className="w-24">No. Proyecto</TableHead>
                  <TableHead className="w-28">Precio Unit.</TableHead>
                  <TableHead className="w-28">Costo Unit.</TableHead>
                  <TableHead className="w-24">Utilidad</TableHead>
                  <TableHead className="w-20">Margen</TableHead>
                  <TableHead className="w-28">Total + IVA</TableHead>
                  <TableHead className="w-24">Acciones</TableHead>
                </TableRow>
              </TableHeader>
              <TableBody>
                {formData.items.map((item) => {
                  if (!item) return null;
                  
                  const producto = item.producto_id ? productosIdx[item.producto_id] : null;
                  const esServicio = producto?.tipo === 'servicio';
                  const disponible = (producto?.stock_actual || 0) - (producto?.stock_reservado || 0);
                  const advertenciaStock = producto?.tipo === 'bien' && (item.cantidad || 0) > disponible;

                  
                  let totalCalculado = { subtotal: 0, iva: 0, total: 0, costoTotal: 0 };
                  if (esServicio && producto?.servicio) {
                    totalCalculado = totalItemServicio(item, producto, formData.con_factura ? ajustes.iva_por_defecto : 0);
                  } else {
                    const base = (item.cantidad || 0) * (item.precio_unitario || 0);
                    const iva = formData.con_factura ? base * ajustes.iva_por_defecto : 0;
                    totalCalculado = { 
                      subtotal: base, 
                      iva, 
                      total: base + iva, 
                      costoTotal: (item.cantidad || 0) * (item.costo_unitario || 0) 
                    };
                  }
                  
                  return (
                    <TableRow key={item.id}>
                    <TableCell>{item.posicion}</TableCell>
                    <TableCell>
                      <Input
                        type="number"
                        value={item.cantidad}
                        onChange={(e) => actualizarItem(item.id, { cantidad: parseFloat(e.target.value) || 0 })}
                        className={`w-full ${advertenciaStock ? 'border-orange-500 bg-orange-50' : ''}`}
                        min="0"
                        step="0.01"
                      />
                      {advertenciaStock && (
                        <div className="flex items-center text-orange-600 text-[10px] mt-1 font-semibold leading-tight">
                          <AlertTriangle className="w-3 h-3 mr-1" />
                          Stock dispo: {disponible}
                        </div>
                      )}
                      {esServicio && producto?.servicio?.por_asiento && (
                        <div className="text-xs text-gray-500 mt-1">Base</div>
                      )}
                    </TableCell>
                    <TableCell>
                      <Input
                        value={item.unidad}
                        onChange={(e) => item && actualizarItem(item.id, { unidad: e.target.value })}
                        className="w-full"
                      />
                    </TableCell>
                    <TableCell>
                      <div className="flex gap-1 items-center">
                        <Input
                          value={item.descripcion}
                          onChange={(e) => actualizarItem(item.id, { descripcion: e.target.value })}
                          className="w-full"
                          placeholder="Descripción del concepto"
                        />
                        <Button
                          type="button"
                          variant="ghost"
                          size="icon"
                          title="Mejorar descripción con IA"
                          className="h-8 w-8 shrink-0 text-purple-500 hover:text-purple-700"
                          onClick={() => mejorarDescripcionConIA(item.id)}
                          disabled={!item.descripcion.trim() || iaLoadingItemId === item.id}
                        >
                          {iaLoadingItemId === item.id
                            ? <Loader2 className="h-3.5 w-3.5 animate-spin" />
                            : <Sparkles className="h-3.5 w-3.5" />
                          }
                        </Button>
                      </div>
                      {esServicio && producto?.servicio && (
                        <div className="grid grid-cols-2 gap-2 mt-2">
                          {(producto.servicio.modo === 'unico' || producto.servicio.modo === 'hibrido') && (
                            <label className="flex items-center space-x-2">
                              <input
                                type="checkbox"
                                checked={item.incluir_setup ?? true}
                                onChange={(e) => actualizarItem(item.id, { incluir_setup: e.target.checked })}
                                className="rounded"
                              />
                              <span className="text-sm">Setup</span>
                            </label>
                          )}
                          {(producto.servicio.modo === 'suscripcion' || producto.servicio.modo === 'hibrido') && (
                            <div>
                              <Label className="text-xs">Meses</Label>
                              <Select 
                                value={String(item.meses_cobrados || 1)} 
                                onValueChange={(value) => actualizarItem(item.id, { meses_cobrados: parseInt(value) })}
                              >
                                <SelectTrigger className="h-7">
                                  <SelectValue />
                                </SelectTrigger>
                                <SelectContent>
                                  <SelectItem value="1">1</SelectItem>
                                  <SelectItem value="3">3</SelectItem>
                                  <SelectItem value="6">6</SelectItem>
                                  <SelectItem value="12">12</SelectItem>
                                </SelectContent>
                              </Select>
                            </div>
                          )}
                          {producto.servicio.por_asiento && (
                            <div>
                              <Label className="text-xs">Asientos extra</Label>
                              <Input
                                type="number"
                                value={item.asientos_extra || 0}
                                onChange={(e) => actualizarItem(item.id, { asientos_extra: parseInt(e.target.value) || 0 })}
                                className="h-7"
                                min="0"
                                step="1"
                              />
                            </div>
                          )}
                        </div>
                      )}
                    </TableCell>
                    <TableCell>
                      <Input
                        value={item.numero_proyecto || ''}
                        onChange={(e) => item && actualizarItem(item.id, { numero_proyecto: e.target.value })}
                        className="w-full"
                        placeholder="Opcional"
                      />
                    </TableCell>
                    <TableCell>
                      {esServicio ? (
                        <div className="text-sm">
                          <span className="text-gray-600">Automático</span>
                          <div className="text-xs text-gray-500">
                            {formatearMoneda(totalCalculado.subtotal)}
                          </div>
                        </div>
                      ) : (
                        <Input
                          type="number"
                          value={item.precio_unitario || 0}
                          onChange={(e) => actualizarItem(item.id, { precio_unitario: parseFloat(e.target.value) || 0 })}
                          className="w-full"
                          min="0"
                          step="0.01"
                        />
                      )}
                    </TableCell>
                    <TableCell>
                      {esServicio ? (
                        <div className="text-sm">
                          <span className="text-gray-600">Automático</span>
                          <div className="text-xs text-gray-500">
                            {formatearMoneda(totalCalculado.costoTotal)}
                          </div>
                        </div>
                      ) : (
                        <Input
                          type="number"
                          value={item.costo_unitario || 0}
                          onChange={(e) => actualizarItem(item.id, { costo_unitario: parseFloat(e.target.value) || 0 })}
                          className="w-full"
                          min="0"
                          step="0.01"
                          placeholder="0.00"
                        />
                      )}
                    </TableCell>
                    <TableCell>
                      {(() => {
                        const utilidad = totalCalculado.subtotal - totalCalculado.costoTotal;
                        return (
                          <span className={utilidad >= 0 ? 'text-green-600' : 'text-red-600'}>
                            {formatearMoneda(utilidad)}
                          </span>
                        );
                      })()}
                    </TableCell>
                    <TableCell>
                      {(() => {
                        const margen = totalCalculado.subtotal > 0 ? 
                          ((totalCalculado.subtotal - totalCalculado.costoTotal) / totalCalculado.subtotal) * 100 : 0;
                        return (
                          <span className={margen >= 0 ? 'text-green-600' : 'text-red-600'}>
                            {margen.toFixed(1)}%
                          </span>
                        );
                      })()}
                    </TableCell>
                    <TableCell>{formatearMoneda(totalCalculado.total)}</TableCell>
                    <TableCell>
                      <div className="flex gap-1">
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => item && duplicarItem(item.id)}
                        >
                          <Copy className="h-4 w-4" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => item && eliminarItem(item.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
                })}
              </TableBody>
            </Table>
            </div>
            </>
          )}
        </CardContent>
      </Card>

      {/* Totales */}
      <Card>
        <CardHeader>
          <CardTitle>Totales</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label>Subtotal</Label>
              <div className="text-lg font-medium">{formatearMoneda(totales.subtotal)}</div>
            </div>
            <div>
              <Label>IVA ({(ajustes.iva_por_defecto * 100).toFixed(0)}%)</Label>
              <div className="text-lg font-medium">{formatearMoneda(totales.iva)}</div>
            </div>
            <div>
              <Label>Total</Label>
              <div className="text-xl font-bold text-green-600">{formatearMoneda(totales.total)}</div>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Costos Indirectos y Comisiones */}
      <CostosIndirectosComponent
        costosIndirectos={formData.costos_indirectos}
        comisionesPago={formData.comisiones_pago}
        onCostosChange={(costos) => setFormData(prev => ({ ...prev, costos_indirectos: costos }))}
        onComisionesChange={(comisiones) => setFormData(prev => ({ ...prev, comisiones_pago: comisiones }))}
        subtotal={totales.subtotal}
      />

      {/* Nota */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle>Nota y Observaciones</CardTitle>
            <Button
              variant="outline"
              size="sm"
              className="text-purple-600 border-purple-200 hover:bg-purple-50"
              onClick={generarNotaConIA}
              disabled={iaLoadingNota}
            >
              {iaLoadingNota
                ? <><Loader2 className="mr-2 h-3.5 w-3.5 animate-spin" />Generando…</>
                : <><Sparkles className="mr-2 h-3.5 w-3.5" />Generar con IA</>
              }
            </Button>
          </div>
        </CardHeader>
        <CardContent>
          <Textarea
            value={formData.nota}
            onChange={(e) => setFormData(prev => ({ ...prev, nota: e.target.value }))}
            placeholder="Nota o comentarios adicionales..."
            rows={4}
          />
        </CardContent>
      </Card>

      {/* Modal: Importar desde Excel */}
      <ExcelImportModal
        open={showExcelModal}
        onOpenChange={setShowExcelModal}
        onImportar={importarDesdeExcel}
      />

      {/* Modal: Seleccionar Plantilla */}
      <Dialog open={showPlantillasModal} onOpenChange={setShowPlantillasModal}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>Usar Plantilla</DialogTitle>
            <DialogDescription>
              Selecciona una plantilla para pre-cargar los conceptos en esta cotización.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-2 py-2 max-h-80 overflow-y-auto">
            {plantillas.map(p => (
              <button
                key={p.id}
                onClick={() => aplicarPlantilla(p)}
                className="w-full text-left p-3 rounded-lg border hover:border-blue-400 hover:bg-blue-50 transition-colors"
              >
                <div className="font-medium text-gray-900">{p.nombre}</div>
                {p.descripcion && <div className="text-xs text-gray-500 mt-0.5">{p.descripcion}</div>}
                <div className="text-xs text-gray-400 mt-1">{p.items.length} concepto{p.items.length !== 1 ? 's' : ''}</div>
              </button>
            ))}
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowPlantillasModal(false)}>Cancelar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal: Guardar como Plantilla */}
      <Dialog open={showGuardarPlantillaModal} onOpenChange={setShowGuardarPlantillaModal}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle>Guardar como Plantilla</DialogTitle>
            <DialogDescription>
              Se guardarán los {formData.items.length} conceptos actuales como una plantilla reutilizable.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-4 py-2">
            <div>
              <Label>Nombre de la plantilla *</Label>
              <Input
                placeholder="Ej: Diseño de identidad corporativa"
                value={nombreNuevaPlantilla}
                onChange={e => setNombreNuevaPlantilla(e.target.value)}
              />
            </div>
            <div>
              <Label>Descripción</Label>
              <Input
                placeholder="Breve descripción"
                value={descripcionNuevaPlantilla}
                onChange={e => setDescripcionNuevaPlantilla(e.target.value)}
              />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setShowGuardarPlantillaModal(false)}>Cancelar</Button>
            <Button
              onClick={handleGuardarComoPlantilla}
              disabled={!nombreNuevaPlantilla.trim() || guardandoPlantilla}
            >
              {guardandoPlantilla ? 'Guardando…' : 'Guardar Plantilla'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

    </div>
  );
}