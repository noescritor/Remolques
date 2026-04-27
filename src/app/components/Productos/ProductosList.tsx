import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Skeleton } from '../ui/skeleton';
import { Alert, AlertDescription } from '../ui/alert';
import { Plus, Search, Edit, Trash2, Package, Calculator } from 'lucide-react';
import { Producto, ProductoTipo, ServicioModo, PeriodoCobro } from '../../types';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { formatearMoneda } from '../../utils/calculations';
import { CalculadoraMaterial } from './CalculadoraMaterial';

interface ProductosListProps {
  productos: Producto[];
  loading: boolean;
  onCrearProducto: (producto: Omit<Producto, 'id'>) => void;
  onActualizarProducto: (id: string, producto: Partial<Producto>) => void;
  onEliminarProducto: (id: string) => void;
}

export function ProductosList({
  productos,
  loading,
  onCrearProducto,
  onActualizarProducto,
  onEliminarProducto
}: ProductosListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [productoEditando, setProductoEditando] = useState<Producto | null>(null);
  const [productoAEliminar, setProductoAEliminar] = useState<string | null>(null);
  const [mostrarCalculadora, setMostrarCalculadora] = useState(false);
  
  const [formData, setFormData] = useState({
    tipo: 'bien' as ProductoTipo,
    nombre: '',
    descripcion: '',
    unidad: 'pz',
    precio_unitario: 0,
    costo: 0,
    tasa_iva: 0.16,
    // Campos de servicio
    servicio: {
      modo: 'unico' as ServicioModo,
      setup_precio: 0,
      setup_costo: 0,
      recur_precio: 0,
      recur_costo: 0,
      periodo: 'mensual' as PeriodoCobro,
      min_meses: 1,
      por_asiento: false,
      asientos_incluidos: 1,
      precio_por_asiento: 0
    }
  });
  
  const [errores, setErrores] = useState<string[]>([]);

  const productosFiltrados = productos.filter(producto => {
    if (!producto) return false;
    return (producto.nombre || '').toLowerCase().includes(busqueda.toLowerCase());
  });

  const validarFormulario = (): string[] => {
    const errores = [];
    
    if (!formData.nombre.trim()) {
      errores.push('El nombre del producto es requerido');
    }
    
    if (formData.tipo === 'bien') {
      if (!formData.precio_unitario || formData.precio_unitario <= 0) {
        errores.push('El precio unitario es requerido para bienes');
      }
      
      if (formData.costo && formData.costo < 0) {
        errores.push('El costo no puede ser negativo');
      }
      
      if (formData.costo && formData.precio_unitario && formData.costo > formData.precio_unitario) {
        errores.push('El costo no puede ser mayor al precio de venta');
      }
    } else if (formData.tipo === 'servicio') {
      const servicio = formData.servicio;
      
      if (!servicio.modo) {
        errores.push('El modo de servicio es requerido');
      }
      
      if (servicio.modo === 'unico' || servicio.modo === 'hibrido') {
        if (!servicio.setup_precio || servicio.setup_precio <= 0) {
          errores.push('El precio de setup es requerido para este modo');
        }
        if (servicio.setup_costo && servicio.setup_costo < 0) {
          errores.push('El costo de setup no puede ser negativo');
        }
      }
      
      if (servicio.modo === 'suscripcion' || servicio.modo === 'hibrido') {
        if (!servicio.recur_precio || servicio.recur_precio <= 0) {
          errores.push('El precio recurrente es requerido para este modo');
        }
        if (servicio.recur_costo && servicio.recur_costo < 0) {
          errores.push('El costo recurrente no puede ser negativo');
        }
        if (!servicio.periodo) {
          errores.push('El periodo de cobro es requerido');
        }
      }
      
      if (servicio.min_meses && servicio.min_meses < 1) {
        errores.push('El mínimo de meses debe ser al menos 1');
      }
      
      if (servicio.por_asiento) {
        if (!servicio.asientos_incluidos || servicio.asientos_incluidos < 1) {
          errores.push('Los asientos incluidos deben ser al menos 1');
        }
        if (!servicio.precio_por_asiento || servicio.precio_por_asiento <= 0) {
          errores.push('El precio por asiento adicional es requerido');
        }
      }
    }
    
    if (formData.tasa_iva < 0 || formData.tasa_iva > 0.5) {
      errores.push('La tasa de IVA debe estar entre 0 y 0.5');
    }
    
    return errores;
  };

  const manejarGuardarProducto = () => {
    const erroresValidacion = validarFormulario();
    if (erroresValidacion.length > 0) {
      setErrores(erroresValidacion);
      return;
    }
    
    setErrores([]);
    
    if (productoEditando) {
      onActualizarProducto(productoEditando.id, formData);
    } else {
      onCrearProducto(formData);
    }
    
    setModalOpen(false);
    setProductoEditando(null);
    resetFormData();
  };

  const resetFormData = () => {
    setFormData({
      tipo: 'bien' as ProductoTipo,
      nombre: '',
      descripcion: '',
      unidad: 'pz',
      precio_unitario: 0,
      costo: 0,
      tasa_iva: 0.16,
      servicio: {
        modo: 'unico' as ServicioModo,
        setup_precio: 0,
        setup_costo: 0,
        recur_precio: 0,
        recur_costo: 0,
        periodo: 'mensual' as PeriodoCobro,
        min_meses: 1,
        por_asiento: false,
        asientos_incluidos: 1,
        precio_por_asiento: 0
      }
    });
  };

  const abrirModalEdicion = (producto: Producto) => {
    setProductoEditando(producto);
    setFormData({
      tipo: producto.tipo || 'bien',
      nombre: producto.nombre,
      descripcion: producto.descripcion || '',
      unidad: producto.unidad,
      precio_unitario: producto.precio_unitario || 0,
      costo: producto.costo || 0,
      tasa_iva: producto.tasa_iva,
      servicio: producto.servicio || {
        modo: 'unico' as ServicioModo,
        setup_precio: 0,
        setup_costo: 0,
        recur_precio: 0,
        recur_costo: 0,
        periodo: 'mensual' as PeriodoCobro,
        min_meses: 1,
        por_asiento: false,
        asientos_incluidos: 1,
        precio_por_asiento: 0
      }
    });
    setErrores([]);
    setModalOpen(true);
  };

  const abrirModalCreacion = () => {
    setProductoEditando(null);
    resetFormData();
    setErrores([]);
    setModalOpen(true);
  };

  const aplicarCostoDesdeCalculadora = (costo: number) => {
    setFormData(prev => ({ ...prev, costo }));
    setMostrarCalculadora(false);
    setModalOpen(true);
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Productos</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle>Productos</CardTitle>
            <div className="flex flex-col sm:flex-row gap-2">
              <Button onClick={() => setMostrarCalculadora(!mostrarCalculadora)} variant="outline" className="w-full sm:w-auto">
                <Calculator className="mr-2 h-4 w-4" />
                Calculadora
              </Button>
              <Button onClick={abrirModalCreacion} className="w-full sm:w-auto">
                <Plus className="mr-2 h-4 w-4" />
                Nuevo Producto
              </Button>
            </div>
          </div>
          
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <Input
              placeholder="Buscar por nombre..."
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardHeader>
        
        {mostrarCalculadora && (
          <CardContent className="pt-6">
            <CalculadoraMaterial onAplicarCosto={aplicarCostoDesdeCalculadora} />
          </CardContent>
        )}
        
        <CardContent>
          {productosFiltrados.length === 0 ? (
            <div className="text-center py-12">
              <Package className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-4 text-lg font-medium text-gray-900">
                {busqueda ? 'No se encontraron productos' : 'No hay productos registrados'}
              </h3>
              <p className="mt-2 text-gray-500">
                {busqueda 
                  ? 'Intenta ajustar los términos de búsqueda'
                  : 'Comienza agregando tu primer producto'
                }
              </p>
              {!busqueda && (
                <Button onClick={abrirModalCreacion} className="mt-4">
                  <Plus className="mr-2 h-4 w-4" />
                  Nuevo Producto
                </Button>
              )}
            </div>
          ) : (
            <>
              {/* Vista de cards para móvil */}
              <div className="lg:hidden space-y-3">
                {productosFiltrados.map((producto) => {
                  const renderPrecioInfo = () => {
                    if (producto.tipo === 'servicio' && producto.servicio) {
                      const servicio = producto.servicio;
                      if (servicio.modo === 'unico') {
                        return formatearMoneda(servicio.setup_precio || 0);
                      } else if (servicio.modo === 'suscripcion') {
                        return `${formatearMoneda(servicio.recur_precio || 0)}/${servicio.periodo}`;
                      } else if (servicio.modo === 'hibrido') {
                        return `Setup: ${formatearMoneda(servicio.setup_precio || 0)} + ${formatearMoneda(servicio.recur_precio || 0)}/${servicio.periodo}`;
                      }
                    }
                    return formatearMoneda(producto.precio_unitario || 0);
                  };

                  const renderMargenInfo = () => {
                    if (producto.tipo === 'servicio' && producto.servicio) {
                      const servicio = producto.servicio;
                      if (servicio.modo === 'unico' && servicio.setup_precio && servicio.setup_costo) {
                        const margen = ((servicio.setup_precio - servicio.setup_costo) / servicio.setup_precio) * 100;
                        return `${margen.toFixed(1)}%`;
                      } else if (servicio.modo === 'suscripcion' && servicio.recur_precio && servicio.recur_costo) {
                        const margen = ((servicio.recur_precio - servicio.recur_costo) / servicio.recur_precio) * 100;
                        return `${margen.toFixed(1)}%`;
                      } else if (servicio.modo === 'hibrido') {
                        return 'Mixto';
                      }
                    } else if (producto.costo !== undefined && producto.precio_unitario) {
                      const margen = ((producto.precio_unitario - producto.costo) / producto.precio_unitario) * 100;
                      return `${margen.toFixed(1)}%`;
                    }
                    return '-';
                  };

                  return (
                    <div key={producto.id} className="border border-gray-200 rounded-lg p-4">
                      <div className="flex items-start justify-between mb-3">
                        <div className="flex-1">
                          <div className="font-semibold text-gray-900">{producto.nombre}</div>
                          {producto.descripcion && (
                            <div className="text-sm text-gray-600 mt-1">{producto.descripcion}</div>
                          )}
                        </div>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ml-2 ${
                          producto.tipo === 'servicio' 
                            ? 'bg-blue-100 text-blue-800' 
                            : 'bg-green-100 text-green-800'
                        }`}>
                          {producto.tipo === 'servicio' ? 'Servicio' : 'Bien'}
                        </span>
                      </div>
                      
                      <div className="space-y-2 text-sm">
                        <div className="flex justify-between">
                          <span className="text-gray-600">Precio:</span>
                          <span className="text-gray-900 font-semibold">{renderPrecioInfo()}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Margen:</span>
                          <span className="text-gray-900">{renderMargenInfo()}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">Unidad:</span>
                          <span className="text-gray-900">{producto.unidad}</span>
                        </div>
                        <div className="flex justify-between">
                          <span className="text-gray-600">IVA:</span>
                          <span className="text-gray-900">{(producto.tasa_iva * 100).toFixed(0)}%</span>
                        </div>
                      </div>
                      
                      <div className="flex gap-2 mt-4">
                        <Button
                          variant="outline"
                          size="sm"
                          className="flex-1"
                          onClick={() => abrirModalEdicion(producto)}
                        >
                          <Edit className="mr-2 h-4 w-4" />
                          Editar
                        </Button>
                        <Button
                          variant="ghost"
                          size="sm"
                          onClick={() => setProductoAEliminar(producto.id)}
                        >
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  );
                })}
              </div>

              {/* Tabla para desktop */}
              <div className="hidden lg:block overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nombre</TableHead>
                      <TableHead>Tipo</TableHead>
                      <TableHead>Unidad</TableHead>
                      <TableHead className="text-right">Precio</TableHead>
                      <TableHead className="text-right">Margen</TableHead>
                      <TableHead className="text-right">Tasa IVA</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                {productosFiltrados.map((producto) => {
                  const renderPrecioInfo = () => {
                    if (producto.tipo === 'servicio' && producto.servicio) {
                      const servicio = producto.servicio;
                      if (servicio.modo === 'unico') {
                        return formatearMoneda(servicio.setup_precio || 0);
                      } else if (servicio.modo === 'suscripcion') {
                        return `${formatearMoneda(servicio.recur_precio || 0)}/${servicio.periodo}`;
                      } else if (servicio.modo === 'hibrido') {
                        return (
                          <div className="space-y-1">
                            <div>Setup: {formatearMoneda(servicio.setup_precio || 0)}</div>
                            <div className="text-sm text-gray-500">
                              {formatearMoneda(servicio.recur_precio || 0)}/${servicio.periodo}
                            </div>
                          </div>
                        );
                      }
                    }
                    return formatearMoneda(producto.precio_unitario || 0);
                  };

                  const renderMargenInfo = () => {
                    if (producto.tipo === 'servicio' && producto.servicio) {
                      const servicio = producto.servicio;
                      if (servicio.modo === 'unico' && servicio.setup_precio && servicio.setup_costo) {
                        const margen = ((servicio.setup_precio - servicio.setup_costo) / servicio.setup_precio) * 100;
                        return `${margen.toFixed(1)}%`;
                      } else if (servicio.modo === 'suscripcion' && servicio.recur_precio && servicio.recur_costo) {
                        const margen = ((servicio.recur_precio - servicio.recur_costo) / servicio.recur_precio) * 100;
                        return `${margen.toFixed(1)}%`;
                      } else if (servicio.modo === 'hibrido') {
                        return 'Mixto';
                      }
                    } else if (producto.costo !== undefined && producto.precio_unitario) {
                      const margen = ((producto.precio_unitario - producto.costo) / producto.precio_unitario) * 100;
                      return `${margen.toFixed(1)}%`;
                    }
                    return '-';
                  };

                  return (
                    <TableRow key={producto.id}>
                      <TableCell>
                        <div>
                          <div className="font-medium">{producto.nombre}</div>
                          {producto.descripcion && (
                            <div className="text-sm text-gray-500">{producto.descripcion}</div>
                          )}
                        </div>
                      </TableCell>
                      <TableCell>
                        <span className={`inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${
                          producto.tipo === 'servicio' 
                            ? 'bg-blue-100 text-blue-800' 
                            : 'bg-green-100 text-green-800'
                        }`}>
                          {producto.tipo === 'servicio' ? 'Servicio' : 'Bien'}
                        </span>
                        {producto.tipo === 'servicio' && producto.servicio && (
                          <div className="text-xs text-gray-500 mt-1">
                            {producto.servicio.modo}
                          </div>
                        )}
                      </TableCell>
                      <TableCell>{producto.unidad}</TableCell>
                      <TableCell className="text-right">
                        {renderPrecioInfo()}
                      </TableCell>
                      <TableCell className="text-right">
                        {renderMargenInfo()}
                      </TableCell>
                      <TableCell className="text-right">{(producto.tasa_iva * 100).toFixed(0)}%</TableCell>
                      <TableCell className="text-right">
                        <div className="flex gap-1 justify-end">
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => abrirModalEdicion(producto)}
                          >
                            <Edit className="h-4 w-4" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="sm"
                            onClick={() => setProductoAEliminar(producto.id)}
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

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent>
          <DialogHeader>
            <DialogTitle>
              {productoEditando ? 'Editar Producto' : 'Nuevo Producto'}
            </DialogTitle>
            <DialogDescription>
              {productoEditando 
                ? 'Modifica la información del producto existente.' 
                : 'Completa los datos para crear un nuevo producto.'
              }
            </DialogDescription>
          </DialogHeader>
          
          <div className="space-y-4">
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

            <div>
              <Label>Tipo *</Label>
              <Select 
                value={formData.tipo} 
                onValueChange={(value: ProductoTipo) => 
                  setFormData(prev => ({ ...prev, tipo: value }))
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona el tipo" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="bien">Bien</SelectItem>
                  <SelectItem value="servicio">Servicio</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label>Nombre *</Label>
              <Input
                value={formData.nombre}
                onChange={(e) => setFormData(prev => ({ ...prev, nombre: e.target.value }))}
                placeholder="Nombre del producto o servicio"
              />
            </div>

            <div>
              <Label>Descripción</Label>
              <Input
                value={formData.descripcion}
                onChange={(e) => setFormData(prev => ({ ...prev, descripcion: e.target.value }))}
                placeholder="Descripción detallada (opcional)"
              />
            </div>

            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <Label>Unidad</Label>
                <Input
                  value={formData.unidad}
                  onChange={(e) => setFormData(prev => ({ ...prev, unidad: e.target.value }))}
                  placeholder={formData.tipo === 'bien' ? "pz, kg, hr..." : "servicio, suscripción..."}
                />
              </div>

              <div>
                <Label>Tasa IVA</Label>
                <Input
                  type="number"
                  value={formData.tasa_iva}
                  onChange={(e) => setFormData(prev => ({ ...prev, tasa_iva: parseFloat(e.target.value) || 0 }))}
                  placeholder="0.16"
                  min="0"
                  max="0.5"
                  step="0.01"
                />
              </div>
            </div>

            {formData.tipo === 'bien' ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div>
                  <Label>Costo Unitario</Label>
                  <Input
                    type="number"
                    value={formData.costo}
                    onChange={(e) => setFormData(prev => ({ ...prev, costo: parseFloat(e.target.value) || 0 }))}
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                  />
                  <p className="text-sm text-gray-500 mt-1">
                    Costo de producción o adquisición
                  </p>
                </div>

                <div>
                  <Label>Precio Unitario *</Label>
                  <Input
                    type="number"
                    value={formData.precio_unitario}
                    onChange={(e) => setFormData(prev => ({ ...prev, precio_unitario: parseFloat(e.target.value) || 0 }))}
                    placeholder="0.00"
                    min="0"
                    step="0.01"
                  />
                  <p className="text-sm text-gray-500 mt-1">
                    Precio de venta al cliente
                  </p>
                </div>
              </div>
            ) : (
              // Formulario para Servicios
              <div className="space-y-4">
                <div className="border rounded-lg p-4">
                  <h3 className="font-medium mb-4">Plan de Servicio</h3>
                  
                  <div className="space-y-4">
                    <div>
                      <Label>Modo de Servicio *</Label>
                      <Select 
                        value={formData.servicio.modo} 
                        onValueChange={(value: ServicioModo) => 
                          setFormData(prev => ({ 
                            ...prev, 
                            servicio: { ...prev.servicio, modo: value }
                          }))
                        }
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Selecciona el modo" />
                        </SelectTrigger>
                        <SelectContent>
                          <SelectItem value="unico">Pago único (Solo setup)</SelectItem>
                          <SelectItem value="suscripcion">Suscripción (Solo recurrente)</SelectItem>
                          <SelectItem value="hibrido">Híbrido (Setup + recurrente)</SelectItem>
                        </SelectContent>
                      </Select>
                    </div>

                    {(formData.servicio.modo === 'unico' || formData.servicio.modo === 'hibrido') && (
                      <div className="grid grid-cols-2 gap-4">
                        <div>
                          <Label>Precio Setup *</Label>
                          <Input
                            type="number"
                            value={formData.servicio.setup_precio}
                            onChange={(e) => setFormData(prev => ({ 
                              ...prev, 
                              servicio: { ...prev.servicio, setup_precio: parseFloat(e.target.value) || 0 }
                            }))}
                            placeholder="0.00"
                            min="0"
                            step="0.01"
                          />
                          <p className="text-sm text-gray-500 mt-1">Cargo inicial de instalación/configuración</p>
                        </div>
                        <div>
                          <Label>Costo Setup</Label>
                          <Input
                            type="number"
                            value={formData.servicio.setup_costo}
                            onChange={(e) => setFormData(prev => ({ 
                              ...prev, 
                              servicio: { ...prev.servicio, setup_costo: parseFloat(e.target.value) || 0 }
                            }))}
                            placeholder="0.00"
                            min="0"
                            step="0.01"
                          />
                        </div>
                      </div>
                    )}

                    {(formData.servicio.modo === 'suscripcion' || formData.servicio.modo === 'hibrido') && (
                      <div className="space-y-4">
                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label>Precio Recurrente *</Label>
                            <Input
                              type="number"
                              value={formData.servicio.recur_precio}
                              onChange={(e) => setFormData(prev => ({ 
                                ...prev, 
                                servicio: { ...prev.servicio, recur_precio: parseFloat(e.target.value) || 0 }
                              }))}
                              placeholder="0.00"
                              min="0"
                              step="0.01"
                            />
                          </div>
                          <div>
                            <Label>Costo Recurrente</Label>
                            <Input
                              type="number"
                              value={formData.servicio.recur_costo}
                              onChange={(e) => setFormData(prev => ({ 
                                ...prev, 
                                servicio: { ...prev.servicio, recur_costo: parseFloat(e.target.value) || 0 }
                              }))}
                              placeholder="0.00"
                              min="0"
                              step="0.01"
                            />
                          </div>
                        </div>

                        <div className="grid grid-cols-2 gap-4">
                          <div>
                            <Label>Periodo de Cobro *</Label>
                            <Select 
                              value={formData.servicio.periodo} 
                              onValueChange={(value: PeriodoCobro) => 
                                setFormData(prev => ({ 
                                  ...prev, 
                                  servicio: { ...prev.servicio, periodo: value }
                                }))
                              }
                            >
                              <SelectTrigger>
                                <SelectValue />
                              </SelectTrigger>
                              <SelectContent>
                                <SelectItem value="mensual">Mensual</SelectItem>
                                <SelectItem value="trimestral">Trimestral</SelectItem>
                                <SelectItem value="semestral">Semestral</SelectItem>
                                <SelectItem value="anual">Anual</SelectItem>
                              </SelectContent>
                            </Select>
                          </div>
                          <div>
                            <Label>Mínimo de Meses</Label>
                            <Input
                              type="number"
                              value={formData.servicio.min_meses}
                              onChange={(e) => setFormData(prev => ({ 
                                ...prev, 
                                servicio: { ...prev.servicio, min_meses: parseInt(e.target.value) || 1 }
                              }))}
                              placeholder="1"
                              min="1"
                              step="1"
                            />
                          </div>
                        </div>

                        <div className="space-y-3">
                          <div className="flex items-center space-x-2">
                            <Switch
                              checked={formData.servicio.por_asiento}
                              onCheckedChange={(checked) => setFormData(prev => ({ 
                                ...prev, 
                                servicio: { ...prev.servicio, por_asiento: checked }
                              }))}
                            />
                            <Label>Cobro por asiento</Label>
                          </div>

                          {formData.servicio.por_asiento && (
                            <div className="grid grid-cols-2 gap-4 ml-6">
                              <div>
                                <Label>Asientos Incluidos *</Label>
                                <Input
                                  type="number"
                                  value={formData.servicio.asientos_incluidos}
                                  onChange={(e) => setFormData(prev => ({ 
                                    ...prev, 
                                    servicio: { ...prev.servicio, asientos_incluidos: parseInt(e.target.value) || 1 }
                                  }))}
                                  placeholder="1"
                                  min="1"
                                  step="1"
                                />
                              </div>
                              <div>
                                <Label>Precio por Asiento Extra *</Label>
                                <Input
                                  type="number"
                                  value={formData.servicio.precio_por_asiento}
                                  onChange={(e) => setFormData(prev => ({ 
                                    ...prev, 
                                    servicio: { ...prev.servicio, precio_por_asiento: parseFloat(e.target.value) || 0 }
                                  }))}
                                  placeholder="0.00"
                                  min="0"
                                  step="0.01"
                                />
                              </div>
                            </div>
                          )}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              </div>
            )}

            {/* Resumen de márgenes */}
            {formData.tipo === 'bien' && formData.costo > 0 && formData.precio_unitario > 0 && (
              <div className="bg-gray-50 p-4 rounded-lg">
                <div className="grid grid-cols-2 gap-4 text-sm">
                  <div>
                    <span className="text-gray-600">Ganancia por unidad:</span>
                    <div className="font-medium text-green-600">
                      {formatearMoneda(formData.precio_unitario - formData.costo)}
                    </div>
                  </div>
                  <div>
                    <span className="text-gray-600">Margen de ganancia:</span>
                    <div className="font-medium text-green-600">
                      {(((formData.precio_unitario - formData.costo) / formData.precio_unitario) * 100).toFixed(1)}%
                    </div>
                  </div>
                </div>
              </div>
            )}

            <div className="flex gap-2 justify-end pt-4">
              <Button variant="outline" onClick={() => setModalOpen(false)}>
                Cancelar
              </Button>
              <Button onClick={manejarGuardarProducto}>
                {productoEditando ? 'Actualizar' : 'Crear'} Producto
              </Button>
            </div>
          </div>
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!productoAEliminar} onOpenChange={() => setProductoAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar producto?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción no se puede deshacer. Se eliminará permanentemente el producto de la base de datos.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (productoAEliminar) {
                  onEliminarProducto(productoAEliminar);
                  setProductoAEliminar(null);
                }
              }}
            >
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}