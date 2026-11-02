import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Card, CardContent, CardHeader, CardTitle, CardDescription, CardFooter } from '../ui/card';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Badge } from '../ui/badge';
import { BASE_URL } from '../../utils/api';
import { Plus, Search, Edit, Trash2, Package, FolderPlus, Tag, Layers, RefreshCw, AlertCircle, CheckCircle2 } from 'lucide-react';
import { Producto, ProductoTipo, ServicioModo, PeriodoCobro, CategoriaProducto } from '../../types';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Switch } from '../ui/switch';
import { formatearMoneda } from '../../utils/calculations';
import {
  calcularCategoriasConConteo,
  filtrarProductosCatalogo,
  esProductoSinCosto,
} from '../../utils/catalogoProductos';

interface ProductosListProps {
  productos: Producto[];
  categorias?: CategoriaProducto[];
  loading: boolean;
  onCrearProducto: (producto: Omit<Producto, 'id'>) => Promise<any> | void;
  onActualizarProducto: (id: string, producto: Partial<Producto>) => void;
  onEliminarProducto: (id: string) => void;
  onCrearCategoria?: (categoria: Omit<CategoriaProducto, 'id' | 'organizacion_id'>) => Promise<any>;
  onActualizarCategoria?: (id: string, categoria: Partial<CategoriaProducto>) => Promise<any>;
  onEliminarCategoria?: (id: string) => Promise<any>;
}

interface CatalogoCotizadorData {
  aceros: any[];
  opciones: any[];
  total_aceros: number;
  total_opciones: number;
  fuentes_disponibles: string[];
}

export function ProductosList({
  productos,
  categorias = [],
  loading,
  onCrearProducto,
  onActualizarProducto,
  onEliminarProducto,
  onCrearCategoria,
}: ProductosListProps) {
  // Vista principal: productos generales vs catálogo del cotizador
  const [vistaPrincipal, setVistaPrincipal] = useState<'productos' | 'cotizador'>('productos');

  // Filtros de productos
  const [busqueda, setBusqueda] = useState('');
  const [categoriaActiva, setCategoriaActiva] = useState('todas');
  const [soloSinCosto, setSoloSinCosto] = useState(false);

  // Modals
  const [modalOpen, setModalOpen] = useState(false);
  const [modalCatOpen, setModalCatOpen] = useState(false);
  const [productoEditando, setProductoEditando] = useState<Producto | null>(null);
  const [productoAEliminar, setProductoAEliminar] = useState<string | null>(null);

  // Form Producto
  const [formData, setFormData] = useState({
    tipo: 'bien' as ProductoTipo,
    nombre: '',
    descripcion: '',
    unidad: 'pz',
    precio_unitario: 0,
    costo: 0,
    tasa_iva: 0.16,
    categoria_id: 'ninguna',
    tipo_item: undefined as string | undefined,
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
      precio_por_asiento: 0,
    },
  });
  const [errores, setErrores] = useState<string[]>([]);

  // Form Categoria
  const [materialesBOM, setMaterialesBOM] = useState<any[]>([]);
  const [loadingBOM] = useState(false);
  const [catFormData, setCatFormData] = useState({ nombre: '', color: '#3b82f6' });

  // Estado del catálogo del cotizador
  const [catalogoCotizador, setCatalogoCotizador] = useState<CatalogoCotizadorData | null>(null);
  const [cargandoCotizador, setCargandoCotizador] = useState(false);
  const [errorCotizador, setErrorCotizador] = useState<string | null>(null);
  const [busquedaCotizador, setBusquedaCotizador] = useState('');
  const [subpestanaCotizador, setSubpestanaCotizador] = useState<'aceros' | 'opciones'>('aceros');

  // Conteos puros y categorías con conteo
  const { categoriasConDatos, sinCategoriaCount, todasCount, sinCostoCount } = calcularCategoriasConConteo(
    productos as any,
    categorias as any
  );

  // Filtrado de productos
  const productosFiltrados = filtrarProductosCatalogo(productos, {
    busqueda,
    categoriaActiva,
    soloSinCosto,
  });

  // Cargar catálogo del cotizador bajo demanda
  const cargarCatalogoCotizador = async (forzar = false) => {
    if (!forzar && catalogoCotizador) return;
    setCargandoCotizador(true);
    setErrorCotizador(null);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');
      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/catalogo-cotizador`, { headers });
      if (!res.ok) {
        throw new Error(`Error ${res.status}: ${res.statusText}`);
      }
      const data = await res.json();
      setCatalogoCotizador(data);
    } catch (err: any) {
      console.error('Error cargando catalogo cotizador:', err);
      setErrorCotizador(err.message || 'Error al cargar catálogo del cotizador');
    } finally {
      setCargandoCotizador(false);
    }
  };

  useEffect(() => {
    if (vistaPrincipal === 'cotizador' && !catalogoCotizador) {
      cargarCatalogoCotizador();
    }
  }, [vistaPrincipal]);

  const handleSubmitCategoria = async () => {
    if (!catFormData.nombre.trim()) return;
    if (onCrearCategoria) {
      await onCrearCategoria(catFormData);
      setModalCatOpen(false);
      setCatFormData({ nombre: '', color: '#3b82f6' });
    }
  };

  const handleEditar = (producto: Producto) => {
    setProductoEditando(producto);
    setFormData({
      tipo: producto.tipo || 'bien',
      nombre: producto.nombre || '',
      descripcion: producto.descripcion || '',
      unidad: producto.unidad || 'pz',
      precio_unitario: producto.precio_unitario || 0,
      costo: producto.costo || 0,
      tasa_iva: producto.tasa_iva || 0.16,
      categoria_id: producto.categoria_id || 'ninguna',
      tipo_item: (producto as any).tipo_item || undefined,
      servicio: {
        modo: producto.servicio?.modo || 'unico',
        setup_precio: producto.servicio?.setup_precio || 0,
        setup_costo: producto.servicio?.setup_costo || 0,
        recur_precio: producto.servicio?.recur_precio || 0,
        recur_costo: producto.servicio?.recur_costo || 0,
        periodo: producto.servicio?.periodo || 'mensual',
        min_meses: producto.servicio?.min_meses || 1,
        por_asiento: producto.servicio?.por_asiento || false,
        asientos_incluidos: producto.servicio?.asientos_incluidos || 1,
        precio_por_asiento: producto.servicio?.precio_por_asiento || 0,
      },
    });
    setModalOpen(true);
  };

  const handleGuardar = async () => {
    if (!formData.nombre.trim()) {
      setErrores(['El nombre es requerido']);
      return;
    }
    setErrores([]);

    const productPayload: any = {
      tipo: formData.tipo,
      nombre: formData.nombre,
      descripcion: formData.descripcion,
      unidad: formData.unidad,
      precio_unitario: formData.precio_unitario,
      costo: formData.costo,
      tasa_iva: formData.tasa_iva,
      categoria_id: formData.categoria_id === 'ninguna' ? null : formData.categoria_id,
    };

    if (formData.tipo === 'servicio') {
      productPayload.servicio = formData.servicio;
    }

    if (formData.tipo_item) {
      productPayload.tipo_item = formData.tipo_item;
    }

    let targetId = productoEditando?.id;
    if (productoEditando) {
      onActualizarProducto(productoEditando.id, productPayload);
    } else {
      const result: any = await onCrearProducto(productPayload);
      if (result && result.id) targetId = result.id;
    }

    // Guardar materiales BOM si es producto terminado
    if (targetId && productPayload.tipo_item === 'producto_terminado') {
      try {
        const { supabase: supa } = await import('../../utils/supabase/client');
        const session = (await supa.auth.getSession()).data.session;
        const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');
        const token = session?.access_token;
        await fetch(`${BASE_URL}/productos/${targetId}/materiales`, {
          method: 'PUT',
          headers: {
            Authorization: `Bearer ${token}`,
            'x-org-id': orgId || '',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(materialesBOM.map((m) => ({ material_id: m.material_id, cantidad: m.cantidad }))),
        });
      } catch (e) {
        console.error('Error guardando materiales', e);
      }
    }

    setModalOpen(false);
  };

  if (loading) {
    return (
      <div className="grid gap-6 grid-cols-2 md:grid-cols-3 lg:grid-cols-4 animate-pulse">
        {[...Array(8)].map((_, i) => (
          <div key={i} className="h-48 bg-muted rounded-xl" />
        ))}
      </div>
    );
  }

  // Filtrado para la vista del cotizador
  const acerosFiltrados = (catalogoCotizador?.aceros || []).filter((a) => {
    if (!busquedaCotizador) return true;
    const term = busquedaCotizador.toLowerCase();
    return (
      (a.nombre || '').toLowerCase().includes(term) ||
      (a.tipo_material || '').toLowerCase().includes(term) ||
      (a.dimensiones_texto || '').toLowerCase().includes(term)
    );
  });

  const opcionesFiltradas = (catalogoCotizador?.opciones || []).filter((o) => {
    if (!busquedaCotizador) return true;
    const term = busquedaCotizador.toLowerCase();
    return (
      (o.nombre || '').toLowerCase().includes(term) ||
      (o.grupo_nombre || '').toLowerCase().includes(term) ||
      (o.clave || '').toLowerCase().includes(term)
    );
  });

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      {/* Encabezado con Switcher de Vistas */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-3xl font-bold font-sans">Productos y Catálogo</h1>
            <Badge variant="outline" className="border-border text-xs">
              {vistaPrincipal === 'productos' ? `${todasCount} productos` : 'Cotizador'}
            </Badge>
          </div>
          <p className="text-muted-foreground mt-1">
            Gestión de catálogo general, recetas de producción y listas de precios del cotizador
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Alternar Vista */}
          <div className="bg-muted p-1 rounded-lg flex items-center border border-border">
            <Button
              size="sm"
              variant={vistaPrincipal === 'productos' ? 'default' : 'ghost'}
              className="text-xs h-8"
              onClick={() => setVistaPrincipal('productos')}
            >
              <Package className="mr-1.5 h-3.5 w-3.5" /> General ({todasCount})
            </Button>
            <Button
              size="sm"
              variant={vistaPrincipal === 'cotizador' ? 'default' : 'ghost'}
              className="text-xs h-8"
              onClick={() => setVistaPrincipal('cotizador')}
            >
              <Layers className="mr-1.5 h-3.5 w-3.5" /> Catálogo Cotizador
            </Button>
          </div>

          {vistaPrincipal === 'productos' && (
            <>
              <Button
                variant="outline"
                onClick={() => setModalCatOpen(true)}
                className="border-border hover:bg-muted/20"
              >
                <FolderPlus className="mr-2 h-4 w-4" /> Categoría
              </Button>
              <Button
                onClick={() => {
                  setProductoEditando(null);
                  setFormData({
                    tipo: 'bien',
                    nombre: '',
                    descripcion: '',
                    unidad: 'pz',
                    precio_unitario: 0,
                    costo: 0,
                    tasa_iva: 0.16,
                    categoria_id: 'ninguna',
                    tipo_item: undefined,
                    servicio: {
                      modo: 'unico',
                      setup_precio: 0,
                      setup_costo: 0,
                      recur_precio: 0,
                      recur_costo: 0,
                      periodo: 'mensual',
                      min_meses: 1,
                      por_asiento: false,
                      asientos_incluidos: 1,
                      precio_por_asiento: 0,
                    },
                  });
                  setModalOpen(true);
                }}
                className="bg-primary text-primary-foreground hover:bg-primary/90"
              >
                <Plus className="mr-2 h-4 w-4" /> Nuevo Producto
              </Button>
            </>
          )}
        </div>
      </div>

      {/* VISTA 1: PRODUCTOS GENERALES */}
      {vistaPrincipal === 'productos' && (
        <>
          {/* Barra de Filtros: Búsqueda, Switch sin costo y Pestañas de Categoría */}
          <div className="flex flex-col gap-4 bg-card/50 p-4 rounded-lg border border-border/50">
            <div className="flex flex-col sm:flex-row gap-4 justify-between items-stretch sm:items-center">
              <div className="relative w-full sm:w-96">
                <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                <Input
                  placeholder="Buscar por nombre o descripción..."
                  value={busqueda}
                  onChange={(e) => setBusqueda(e.target.value)}
                  className="pl-10 bg-transparent border-border"
                />
              </div>

              {/* Toggle: Solo sin costo */}
              <div className="flex items-center gap-3 bg-background/50 px-3 py-1.5 rounded-md border border-border self-start sm:self-auto">
                <Switch
                  id="solo-sin-costo"
                  checked={soloSinCosto}
                  onCheckedChange={setSoloSinCosto}
                />
                <Label htmlFor="solo-sin-costo" className="text-xs cursor-pointer flex items-center gap-1.5">
                  <AlertCircle className="w-3.5 h-3.5 text-amber-500" />
                  <span>Solo sin costo cargado</span>
                  <Badge variant="secondary" className="text-[10px] h-5 px-1.5 bg-amber-500/20 text-amber-500 border-none">
                    {sinCostoCount}
                  </Badge>
                </Label>
              </div>
            </div>

            {/* Pestañas de categorías con badges */}
            <div className="border-t border-border/40 pt-3">
              <Tabs
                value={categoriaActiva}
                onValueChange={setCategoriaActiva}
                className="w-full overflow-x-auto"
              >
                <TabsList className="bg-transparent border border-border flex flex-wrap h-auto p-1 gap-1 justify-start">
                  <TabsTrigger value="todas" className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground text-xs">
                    Todas
                    <Badge variant="secondary" className="ml-1.5 text-[10px] h-4 px-1">
                      {todasCount}
                    </Badge>
                  </TabsTrigger>

                  {categoriasConDatos.map((cat) => (
                    <TabsTrigger
                      key={cat.id}
                      value={cat.id}
                      className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground text-xs"
                    >
                      <div
                        className="w-2 h-2 rounded-full mr-1.5"
                        style={{ backgroundColor: cat.color || '#3b82f6' }}
                      />
                      {cat.nombre}
                      <Badge variant="secondary" className="ml-1.5 text-[10px] h-4 px-1">
                        {cat.count}
                      </Badge>
                    </TabsTrigger>
                  ))}

                  {/* Pestaña Sin categoría siempre visible si hay productos sin categoría */}
                  {sinCategoriaCount > 0 && (
                    <TabsTrigger
                      value="sin_categoria"
                      className="data-[state=active]:bg-primary data-[state=active]:text-primary-foreground text-xs"
                    >
                      <span className="text-muted-foreground mr-1.5">○</span>
                      Sin categoría
                      <Badge variant="secondary" className="ml-1.5 text-[10px] h-4 px-1 bg-muted">
                        {sinCategoriaCount}
                      </Badge>
                    </TabsTrigger>
                  )}
                </TabsList>
              </Tabs>
            </div>
          </div>

          {/* Grilla de Productos */}
          {productosFiltrados.length === 0 ? (
            <div className="text-center py-20 bg-card/50 rounded-xl border border-border/50">
              <Package className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
              <h3 className="text-lg font-medium text-foreground mb-2">No se encontraron productos</h3>
              <p className="text-muted-foreground text-sm max-w-md mx-auto">
                {soloSinCosto
                  ? 'No hay productos sin costo cargado en la categoría seleccionada.'
                  : 'Prueba con otra búsqueda o selecciona una categoría diferente.'}
              </p>
            </div>
          ) : (
            <div className="grid gap-6 grid-cols-1 sm:grid-cols-2 md:grid-cols-3 xl:grid-cols-4">
              {productosFiltrados.map((producto) => {
                const cat = categorias.find((c) => c.id === producto.categoria_id);
                const sinCosto = esProductoSinCosto(producto);

                return (
                  <Card
                    key={producto.id}
                    className="bg-card/50 border-border/50 hover:bg-muted/30 transition-all flex flex-col group overflow-hidden"
                  >
                    <div
                      className="h-2 w-full"
                      style={{
                        backgroundColor: cat?.color || 'rgba(150, 150, 150, 0.3)',
                      }}
                    />
                    <CardHeader className="pb-2">
                      <div className="flex justify-between items-start">
                        <div className="flex flex-wrap gap-1">
                          <Badge variant="outline" className="text-[10px] bg-background/50">
                            {producto.tipo === 'bien' ? 'Producto' : 'Servicio'}
                          </Badge>
                          {(producto as any).tipo_item && (
                            <Badge variant="secondary" className="text-[10px]">
                              {(producto as any).tipo_item === 'producto_terminado'
                                ? 'Terminado'
                                : (producto as any).tipo_item === 'materia_prima'
                                ? 'Materia Prima'
                                : (producto as any).tipo_item}
                            </Badge>
                          )}
                        </div>
                        <div className="opacity-0 group-hover:opacity-100 transition-opacity flex gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7 text-muted-foreground hover:text-foreground"
                            onClick={() => handleEditar(producto)}
                          >
                            <Edit className="h-3.5 w-3.5" />
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            className="h-7 w-7 text-muted-foreground hover:text-destructive"
                            onClick={() => setProductoAEliminar(producto.id)}
                          >
                            <Trash2 className="h-3.5 w-3.5" />
                          </Button>
                        </div>
                      </div>
                      <CardTitle className="text-base text-foreground line-clamp-1 mt-1">
                        {producto.nombre}
                      </CardTitle>
                      <CardDescription className="line-clamp-2 text-xs min-h-[32px]">
                        {producto.descripcion || 'Sin descripción'}
                      </CardDescription>
                    </CardHeader>

                    <CardContent className="flex-1">
                      <div className="mt-2 flex items-end justify-between">
                        <div>
                          <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-mono mb-0.5">
                            Precio Unit.
                          </p>
                          <p className="text-lg font-bold font-mono text-primary">
                            {formatearMoneda(producto.precio_unitario || 0)}
                          </p>
                        </div>

                        <div className="text-right">
                          <p className="text-[10px] text-muted-foreground uppercase tracking-widest font-mono mb-0.5">
                            Costo
                          </p>
                          {sinCosto ? (
                            <Badge
                              variant="outline"
                              className="border-amber-500/50 text-amber-500 bg-amber-500/10 text-[10px] font-mono px-1.5 py-0.5"
                            >
                              Sin costo cargado
                            </Badge>
                          ) : (
                            <p className="text-sm font-mono text-muted-foreground">
                              {formatearMoneda(producto.costo)}
                            </p>
                          )}
                        </div>
                      </div>
                    </CardContent>

                    <CardFooter className="bg-muted/30 py-2.5 px-4 border-t border-border/50 flex justify-between items-center">
                      <span className="text-xs text-muted-foreground flex items-center truncate max-w-[70%]">
                        <Tag className="w-3 h-3 mr-1 shrink-0" />
                        <span className="truncate">{cat?.nombre || 'Sin categoría'}</span>
                      </span>
                      <span className="text-xs text-muted-foreground font-mono uppercase">
                        {producto.unidad || 'pz'}
                      </span>
                    </CardFooter>
                  </Card>
                );
              })}
            </div>
          )}
        </>
      )}

      {/* VISTA 2: CATÁLOGO DEL COTIZADOR */}
      {vistaPrincipal === 'cotizador' && (
        <div className="space-y-6">
          <Card className="bg-card/50 border-border/50">
            <CardHeader className="pb-3">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
                <div>
                  <CardTitle className="text-xl flex items-center gap-2">
                    <Layers className="h-5 w-5 text-primary" />
                    Catálogo de Materiales y Opciones del Cotizador
                  </CardTitle>
                  <CardDescription className="mt-1">
                    Elementos que alimentan el cotizador de remolques (Aceros con peso/precio por kg y opciones configurables con costo de referencia).
                  </CardDescription>
                </div>
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => cargarCatalogoCotizador(true)}
                  disabled={cargandoCotizador}
                  className="self-start sm:self-auto"
                >
                  <RefreshCw className={`h-4 w-4 mr-2 ${cargandoCotizador ? 'animate-spin' : ''}`} />
                  Actualizar
                </Button>
              </div>
            </CardHeader>

            <CardContent>
              {errorCotizador && (
                <div className="p-4 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-sm mb-4 flex items-center gap-2">
                  <AlertCircle className="h-4 w-4 shrink-0" />
                  <span>{errorCotizador}</span>
                </div>
              )}

              {cargandoCotizador && !catalogoCotizador ? (
                <div className="py-20 text-center">
                  <RefreshCw className="h-8 w-8 animate-spin mx-auto text-primary mb-2" />
                  <p className="text-sm text-muted-foreground">Cargando catálogo del cotizador...</p>
                </div>
              ) : (
                <div className="space-y-4">
                  {/* Buscador y selector de subpestaña */}
                  <div className="flex flex-col sm:flex-row gap-4 justify-between items-center">
                    <div className="relative w-full sm:w-96">
                      <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 text-muted-foreground h-4 w-4" />
                      <Input
                        placeholder="Buscar material u opción..."
                        value={busquedaCotizador}
                        onChange={(e) => setBusquedaCotizador(e.target.value)}
                        className="pl-10 bg-transparent border-border"
                      />
                    </div>

                    <Tabs
                      value={subpestanaCotizador}
                      onValueChange={(v) => setSubpestanaCotizador(v as any)}
                      className="w-full sm:w-auto"
                    >
                      <TabsList className="bg-transparent border border-border">
                        <TabsTrigger value="aceros" className="text-xs">
                          Aceros y Materiales ({catalogoCotizador?.total_aceros || 0})
                        </TabsTrigger>
                        <TabsTrigger value="opciones" className="text-xs">
                          Opciones Configurables ({catalogoCotizador?.total_opciones || 0})
                        </TabsTrigger>
                      </TabsList>
                    </Tabs>
                  </div>

                  {/* Tabla Aceros */}
                  {subpestanaCotizador === 'aceros' && (
                    <div className="rounded-lg border border-border overflow-x-auto">
                      <table className="w-full text-xs text-left">
                        <thead className="bg-muted/50 text-muted-foreground uppercase tracking-wider font-mono border-b border-border">
                          <tr>
                            <th className="p-3">Material</th>
                            <th className="p-3">Tipo</th>
                            <th className="p-3">Dimensiones / Calibre</th>
                            <th className="p-3 text-right">Peso (kg/m o kg/pz)</th>
                            <th className="p-3 text-right">Precio / kg</th>
                            <th className="p-3 text-right">Precio / metro</th>
                            <th className="p-3">Fuente</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/50">
                          {acerosFiltrados.length === 0 ? (
                            <tr>
                              <td colSpan={7} className="p-8 text-center text-muted-foreground">
                                No se encontraron aceros o materiales
                              </td>
                            </tr>
                          ) : (
                            acerosFiltrados.map((a, idx) => (
                              <tr key={a.id || idx} className="hover:bg-muted/20">
                                <td className="p-3 font-medium text-foreground">{a.nombre}</td>
                                <td className="p-3 text-muted-foreground uppercase">{a.tipo_material}</td>
                                <td className="p-3 font-mono">{a.dimensiones_texto || a.espesor_in || '-'}</td>
                                <td className="p-3 font-mono text-right">{a.peso_kg_m ? `${a.peso_kg_m} kg` : '-'}</td>
                                <td className="p-3 font-mono text-right font-medium text-primary">
                                  {a.precio_por_kg ? formatearMoneda(a.precio_por_kg) : '-'}
                                </td>
                                <td className="p-3 font-mono text-right">
                                  {a.precio_por_metro ? formatearMoneda(a.precio_por_metro) : '-'}
                                </td>
                                <td className="p-3">
                                  <Badge variant="outline" className="text-[10px]">
                                    {a.fuente || 'catálogo'}
                                  </Badge>
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}

                  {/* Tabla Opciones */}
                  {subpestanaCotizador === 'opciones' && (
                    <div className="rounded-lg border border-border overflow-x-auto">
                      <table className="w-full text-xs text-left">
                        <thead className="bg-muted/50 text-muted-foreground uppercase tracking-wider font-mono border-b border-border">
                          <tr>
                            <th className="p-3">Grupo</th>
                            <th className="p-3">Opción</th>
                            <th className="p-3 text-right">Precio Venta</th>
                            <th className="p-3 text-right">Costo Referencia</th>
                            <th className="p-3">Fuente Costo</th>
                            <th className="p-3">Escala</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/50">
                          {opcionesFiltradas.length === 0 ? (
                            <tr>
                              <td colSpan={6} className="p-8 text-center text-muted-foreground">
                                No se encontraron opciones configurables
                              </td>
                            </tr>
                          ) : (
                            opcionesFiltradas.map((o, idx) => (
                              <tr key={o.id || idx} className="hover:bg-muted/20">
                                <td className="p-3 text-muted-foreground font-mono">
                                  {o.grupo_nombre || o.grupo_clave}
                                </td>
                                <td className="p-3 font-medium text-foreground">{o.nombre}</td>
                                <td className="p-3 font-mono text-right font-medium text-primary">
                                  {o.precio_venta ? formatearMoneda(o.precio_venta) : '-'}
                                </td>
                                <td className="p-3 font-mono text-right">
                                  {o.costo_referencia != null && o.costo_referencia > 0 ? (
                                    <span className="text-muted-foreground font-medium">
                                      {formatearMoneda(o.costo_referencia)}
                                    </span>
                                  ) : (
                                    <Badge
                                      variant="outline"
                                      className="border-amber-500/50 text-amber-500 bg-amber-500/10 text-[10px]"
                                    >
                                      Sin costo
                                    </Badge>
                                  )}
                                </td>
                                <td className="p-3 text-muted-foreground">
                                  <Badge variant="outline" className="text-[10px]">
                                    {o.fuente_costo || 'manual'}
                                  </Badge>
                                </td>
                                <td className="p-3 text-muted-foreground font-mono">
                                  {o.tipo_escala || 'fijo'}
                                </td>
                              </tr>
                            ))
                          )}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      {/* Modal Producto */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="sm:max-w-[600px] max-h-[90vh] overflow-y-auto bg-background border-border">
          <DialogHeader>
            <DialogTitle>{productoEditando ? 'Editar Producto' : 'Nuevo Producto'}</DialogTitle>
          </DialogHeader>

          {errores.length > 0 && (
            <div className="p-3 rounded-md bg-destructive/10 text-destructive text-sm">
              {errores.join(', ')}
            </div>
          )}

          <div className="grid gap-4 py-4">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Tipo</Label>
                <Select
                  value={formData.tipo}
                  onValueChange={(v: ProductoTipo) => setFormData({ ...formData, tipo: v })}
                >
                  <SelectTrigger className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="bien">Bien Físico</SelectItem>
                    <SelectItem value="servicio">Servicio</SelectItem>
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-2">
                <Label>Categoría</Label>
                <Select
                  value={formData.categoria_id}
                  onValueChange={(v) => setFormData({ ...formData, categoria_id: v })}
                >
                  <SelectTrigger className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ninguna">Sin categoría</SelectItem>
                    {categorias.map((c) => (
                      <SelectItem key={c.id} value={c.id}>
                        {c.nombre}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-2">
              <Label>Tipo de Ítem</Label>
              <Select
                value={formData.tipo_item || 'ninguno'}
                onValueChange={(v) =>
                  setFormData({ ...formData, tipo_item: v === 'ninguno' ? undefined : v })
                }
              >
                <SelectTrigger className="border-border">
                  <SelectValue placeholder="General (Sin tipo)" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="ninguno">General (Sin tipo)</SelectItem>
                  <SelectItem value="producto_terminado">Producto Terminado (Lleva BOM)</SelectItem>
                  <SelectItem value="materia_prima">Materia Prima / Refacción</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-2">
                <Label>Nombre</Label>
                <Input
                  value={formData.nombre}
                  onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                  className="border-border"
                />
              </div>
              <div className="space-y-2">
                <Label>Descripción</Label>
                <Input
                  value={formData.descripcion}
                  onChange={(e) => setFormData({ ...formData, descripcion: e.target.value })}
                  className="border-border"
                />
              </div>
            </div>

            <div className="grid grid-cols-3 gap-4">
              <div className="space-y-2">
                <Label>Unidad</Label>
                <Input
                  value={formData.unidad}
                  onChange={(e) => setFormData({ ...formData, unidad: e.target.value })}
                  placeholder="pz, m2, hrs..."
                  className="border-border"
                />
              </div>
              <div className="space-y-2">
                <Label>Precio Unitario</Label>
                <Input
                  type="number"
                  value={formData.precio_unitario || ''}
                  onChange={(e) =>
                    setFormData({ ...formData, precio_unitario: Number(e.target.value) })
                  }
                  className="border-border"
                />
              </div>
              <div className="space-y-2">
                <Label>Costo (opcional)</Label>
                <Input
                  type="number"
                  value={formData.costo || ''}
                  onChange={(e) => setFormData({ ...formData, costo: Number(e.target.value) })}
                  className="border-border"
                />
              </div>
            </div>

            {formData.tipo_item === 'producto_terminado' && (
              <div className="col-span-2 mt-4 border-t border-border pt-4">
                <div className="flex justify-between items-center mb-2">
                  <Label>Materiales (BOM)</Label>
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() =>
                      setMaterialesBOM([...materialesBOM, { material_id: '', cantidad: 1 }])
                    }
                  >
                    + Agregar Material
                  </Button>
                </div>
                {loadingBOM ? (
                  <div>Cargando...</div>
                ) : (
                  <div className="space-y-2">
                    {materialesBOM.map((mat, idx) => (
                      <div key={idx} className="flex gap-2">
                        <Select
                          value={mat.material_id}
                          onValueChange={(v) => {
                            const newM = [...materialesBOM];
                            newM[idx].material_id = v;
                            setMaterialesBOM(newM);
                          }}
                        >
                          <SelectTrigger className="flex-1 border-border">
                            <SelectValue placeholder="Seleccione material" />
                          </SelectTrigger>
                          <SelectContent>
                            {productos
                              .filter((p: any) => p.tipo_item === 'materia_prima')
                              .map((p) => (
                                <SelectItem key={p.id} value={p.id}>
                                  {p.nombre}
                                </SelectItem>
                              ))}
                          </SelectContent>
                        </Select>
                        <Input
                          type="number"
                          min="1"
                          step="0.01"
                          className="w-24 border-border"
                          value={mat.cantidad}
                          onChange={(e) => {
                            const newM = [...materialesBOM];
                            newM[idx].cantidad = parseFloat(e.target.value);
                            setMaterialesBOM(newM);
                          }}
                        />
                        <Button
                          variant="ghost"
                          className="text-destructive"
                          onClick={() => setMaterialesBOM(materialesBOM.filter((_, i) => i !== idx))}
                        >
                          <Trash2 className="w-4 h-4" />
                        </Button>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleGuardar}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Categoría */}
      <Dialog open={modalCatOpen} onOpenChange={setModalCatOpen}>
        <DialogContent className="sm:max-w-[400px] bg-background border-border">
          <DialogHeader>
            <DialogTitle>Nueva Categoría</DialogTitle>
          </DialogHeader>
          <div className="grid gap-4 py-4">
            <div className="space-y-2">
              <Label>Nombre</Label>
              <Input
                value={catFormData.nombre}
                onChange={(e) => setCatFormData({ ...catFormData, nombre: e.target.value })}
                className="border-border"
              />
            </div>
            <div className="space-y-2">
              <Label>Color Identificador</Label>
              <div className="flex gap-2">
                <Input
                  type="color"
                  className="w-16 h-10 p-1 border-border"
                  value={catFormData.color}
                  onChange={(e) => setCatFormData({ ...catFormData, color: e.target.value })}
                />
                <Input
                  type="text"
                  className="flex-1 border-border"
                  value={catFormData.color}
                  onChange={(e) => setCatFormData({ ...catFormData, color: e.target.value })}
                />
              </div>
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setModalCatOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleSubmitCategoria}>Guardar</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Confirmar Eliminar */}
      <AlertDialog
        open={!!productoAEliminar}
        onOpenChange={(o) => !o && setProductoAEliminar(null)}
      >
        <AlertDialogContent className="bg-background border-border">
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar producto?</AlertDialogTitle>
            <AlertDialogDescription>Esta acción no se puede deshacer.</AlertDialogDescription>
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
              Sí, eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
