import { useState, useEffect, useMemo } from 'react';
import {
  DollarSign,
  Package,
  Wrench,
  TrendingUp,
  History,
  ShieldCheck,
  Search,
  Filter,
  CheckCircle2,
  AlertTriangle,
  HelpCircle,
  Edit2,
  Loader2,
  ExternalLink,
  Info
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../ui/tabs';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Switch } from '../ui/switch';
import { toast } from 'sonner';
import { supabase } from '../../utils/supabase/client';
import { BASE_URL } from '../../utils/api';
import {
  formatearMoneda,
  obtenerInsigniaFuente,
  validarOpcionEdicion,
  validarKitEdicion,
  validarProcesoEdicion,
  validarGananciaMonto,
  filtrarOpciones,
  calcularResumenCobertura
} from '../../utils/catalogoCostos';

interface CatalogoCostosProps {
  session?: any;
  organizacion?: any;
}

export function CatalogoCostosMain({ session, organizacion }: CatalogoCostosProps) {
  const [tipoModelo, setTipoModelo] = useState<'plataforma' | 'dolly' | 'gondola'>('plataforma');
  const [activeTab, setActiveTab] = useState<'opciones' | 'kits' | 'utilidad' | 'cobertura' | 'historial'>('opciones');

  const [loading, setLoading] = useState(false);
  const [opciones, setOpciones] = useState<any[]>([]);
  const [cobertura, setCobertura] = useState<any>(null);

  // Filtros de opciones
  const [busqueda, setBusqueda] = useState('');
  const [soloPendientes, setSoloPendientes] = useState(false);
  const [soloSinCosto, setSoloSinCosto] = useState(false);

  // Permisos: propietario o admin
  const [userRole, setUserRole] = useState<string>('usuario');
  const [checkingRole, setCheckingRole] = useState(true);

  // Modelos para la pestaña de Kits
  const [modelos, setModelos] = useState<any[]>([]);
  const [selectedModeloId, setSelectedModeloId] = useState<string>('');
  const [datosModelo, setDatosModelo] = useState<any>(null);
  const [loadingModelo, setLoadingModelo] = useState(false);

  // Parámetros de ganancia
  const [ganancias, setGanancias] = useState<{
    plataforma: number;
    dolly: number;
    gondola_servicios_sueldos: number;
  }>({
    plataforma: 110000,
    dolly: 65000,
    gondola_servicios_sueldos: 150000
  });
  const [savingGanancia, setSavingGanancia] = useState(false);

  // Historial
  const [historial, setHistorial] = useState<any[]>([]);
  const [loadingHistorial, setLoadingHistorial] = useState(false);

  // Catálogo de productos disponibles para ligar
  const [productosDisponibles, setProductosDisponibles] = useState<any[]>([]);

  // Modal de edición de opción
  const [modalOpcionOpen, setModalOpcionOpen] = useState(false);
  const [opcionEnEdicion, setOpcionEnEdicion] = useState<any>(null);
  const [editCosto, setEditCosto] = useState<string>('0');
  const [editCantidad, setEditCantidad] = useState<string>('1');
  const [editEscala, setEditEscala] = useState<string>('fija');
  const [editProductoId, setEditProductoId] = useState<string>('');
  const [editCostoDesdeProducto, setEditCostoDesdeProducto] = useState<boolean>(false);
  const [savingOpcion, setSavingOpcion] = useState(false);

  // Modal de edición de kit
  const [modalKitOpen, setModalKitOpen] = useState(false);
  const [kitEnEdicion, setKitEnEdicion] = useState<any>(null);
  const [kitCantidad, setKitCantidad] = useState<string>('1');
  const [kitCostoUnitario, setKitCostoUnitario] = useState<string>('0');
  const [kitConcepto, setKitConcepto] = useState<string>('');
  const [savingKit, setSavingKit] = useState(false);

  // Modal de edición de proceso
  const [modalProcesoOpen, setModalProcesoOpen] = useState(false);
  const [procesoEnEdicion, setProcesoEnEdicion] = useState<any>(null);
  const [procesoMinutos, setProcesoMinutos] = useState<string>('0');
  const [procesoTarifaHora, setProcesoTarifaHora] = useState<string>('0');
  const [savingProceso, setSavingProceso] = useState(false);

  const canEdit = useMemo(() => {
    return userRole === 'propietario' || userRole === 'admin';
  }, [userRole]);

  // 1. Cargar rol del usuario
  useEffect(() => {
    async function loadRole() {
      try {
        setCheckingRole(true);
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) {
          setUserRole('usuario');
          return;
        }

        const orgId = organizacion?.id || localStorage.getItem('org_id');
        if (!orgId) {
          setUserRole(user.user_metadata?.rol || 'usuario');
          return;
        }

        const { data, error } = await supabase
          .from('perfiles_organizacion')
          .select('rol')
          .eq('usuario_id', user.id)
          .eq('organizacion_id', orgId)
          .maybeSingle();

        if (!error && data?.rol) {
          setUserRole(data.rol);
        } else {
          setUserRole(user.user_metadata?.rol || 'usuario');
        }
      } catch (err) {
        console.error('Error fetching role:', err);
      } finally {
        setCheckingRole(false);
      }
    }
    loadRole();
  }, [organizacion?.id]);

  // 2. Cargar productos disponibles para dropdown de ligados
  useEffect(() => {
    async function loadProductos() {
      try {
        const { data } = await supabase
          .from('productos')
          .select('id, nombre, costo, tipo_item')
          .order('nombre', { ascending: true })
          .limit(500);
        setProductosDisponibles(data || []);
      } catch (err) {
        console.error('Error cargando productos:', err);
      }
    }
    loadProductos();
  }, []);

  // 3. Cargar opciones según el tipo_modelo seleccionado
  const cargarOpcionesTipo = async (tipo: string) => {
    try {
      setLoading(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const res = await fetch(`${BASE_URL}/catalogo-costos/resumen?tipo_modelo=${tipo}`, {
        headers: {
          Authorization: `Bearer ${token}`
        }
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al cargar resumen');
      }

      const json = await res.json();
      setOpciones(json.opciones || []);
      setCobertura(json.cobertura || null);
    } catch (err: any) {
      toast.error('Error al cargar opciones de costo', { description: err.message });
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarOpcionesTipo(tipoModelo);
  }, [tipoModelo]);

  // 4. Cargar lista de modelos para pestaña Kits
  useEffect(() => {
    async function loadModelos() {
      try {
        const { data: { session: currentSession } } = await supabase.auth.getSession();
        const token = currentSession?.access_token;
        const res = await fetch(`${BASE_URL}/modelos`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (res.ok) {
          const json = await res.json();
          setModelos(json || []);
          if (json && json.length > 0 && !selectedModeloId) {
            setSelectedModeloId(json[0].id);
          }
        }
      } catch (err) {
        console.error('Error cargando modelos:', err);
      }
    }
    loadModelos();
  }, []);

  // 5. Cargar datos del modelo seleccionado para pestaña Kits
  const cargarDetalleModelo = async (modId: string) => {
    if (!modId) return;
    try {
      setLoadingModelo(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;
      const res = await fetch(`${BASE_URL}/catalogo-costos/modelos/${modId}`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (!res.ok) throw new Error('Error al cargar datos del modelo');
      const json = await res.json();
      setDatosModelo(json);
    } catch (err: any) {
      toast.error('Error cargando costos del modelo', { description: err.message });
    } finally {
      setLoadingModelo(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'kits' && selectedModeloId) {
      cargarDetalleModelo(selectedModeloId);
    }
  }, [activeTab, selectedModeloId]);

  // 6. Cargar parámetros de ganancia
  useEffect(() => {
    async function loadParametros() {
      try {
        const { data: { session: currentSession } } = await supabase.auth.getSession();
        const token = currentSession?.access_token;
        const res = await fetch(`${BASE_URL}/catalogo-costos/parametros`, {
          headers: { Authorization: `Bearer ${token}` }
        });
        if (res.ok) {
          const json = await res.json();
          if (json.ganancia_factura) {
            setGanancias({
              plataforma: Number(json.ganancia_factura.plataforma) || 110000,
              dolly: Number(json.ganancia_factura.dolly) || 65000,
              gondola_servicios_sueldos: Number(json.ganancia_factura.gondola_servicios_sueldos) || 150000
            });
          }
        }
      } catch (err) {
        console.error('Error cargando parámetros:', err);
      }
    }
    if (activeTab === 'utilidad') {
      loadParametros();
    }
  }, [activeTab]);

  // 7. Cargar historial
  const cargarHistorial = async () => {
    try {
      setLoadingHistorial(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;
      const res = await fetch(`${BASE_URL}/catalogo-costos/historial?limite=100`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      if (res.ok) {
        const json = await res.json();
        setHistorial(json || []);
      }
    } catch (err) {
      console.error('Error cargando historial:', err);
    } finally {
      setLoadingHistorial(false);
    }
  };

  useEffect(() => {
    if (activeTab === 'historial') {
      cargarHistorial();
    }
  }, [activeTab]);

  // Filtrado de opciones en la pestaña 1
  const opcionesFiltradas = useMemo(() => {
    return filtrarOpciones(opciones, {
      busqueda,
      soloPendientes,
      soloSinCosto
    });
  }, [opciones, busqueda, soloPendientes, soloSinCosto]);

  // Agrupar opciones por grupo para mostrar ordenadamente
  const opcionesPorGrupo = useMemo(() => {
    const mapa = new Map<string, { grupo_clave: string; grupo_nombre: string; items: any[] }>();
    for (const opt of opcionesFiltradas) {
      if (!mapa.has(opt.grupo_id)) {
        mapa.set(opt.grupo_id, {
          grupo_clave: opt.grupo_clave,
          grupo_nombre: opt.grupo_nombre,
          items: []
        });
      }
      mapa.get(opt.grupo_id)!.items.push(opt);
    }
    return Array.from(mapa.values());
  }, [opcionesFiltradas]);

  // Acción: Abrir modal de edición de opción
  const handleEditarOpcion = (opt: any) => {
    setOpcionEnEdicion(opt);
    setEditCosto(String(opt.costo_unitario ?? 0));
    setEditCantidad(String(opt.cantidad_base ?? 1));
    setEditEscala(opt.escala || 'fija');
    setEditProductoId(opt.producto_id || '');
    setEditCostoDesdeProducto(Boolean(opt.costo_desde_producto));
    setModalOpcionOpen(true);
  };

  // Acción: Confirmar costo rápido (sin cambiar números)
  const handleConfirmarCosto = async (opt: any) => {
    if (!canEdit) {
      toast.error('No tienes permiso para editar costos');
      return;
    }

    try {
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const body = {
        tipo_modelo: tipoModelo,
        cantidad_base: Number(opt.cantidad_base) || 1,
        escala: opt.escala || 'fija',
        costo_unitario: Number(opt.costo_unitario) || 0,
        producto_id: opt.producto_id || null,
        costo_desde_producto: Boolean(opt.costo_desde_producto),
        confirmar: true
      };

      const res = await fetch(`${BASE_URL}/catalogo-costos/opciones/${opt.opcion_id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al confirmar costo');
      }

      toast.success(`Costo confirmado para ${opt.opcion_nombre}`, {
        description: 'La opción ahora tiene origen Manual (confirmado por usuario)'
      });
      cargarOpcionesTipo(tipoModelo);
    } catch (err: any) {
      toast.error('Error al confirmar costo', { description: err.message });
    }
  };

  // Guardar edición de opción desde el modal
  const handleGuardarOpcion = async () => {
    if (!canEdit) {
      toast.error('No tienes permiso para editar costos');
      return;
    }

    const val = validarOpcionEdicion({
      tipo_modelo: tipoModelo,
      cantidad_base: editCantidad,
      escala: editEscala,
      costo_unitario: editCosto
    });

    if (!val.valido) {
      toast.error('Error de validación', { description: val.error });
      return;
    }

    try {
      setSavingOpcion(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const body = {
        tipo_modelo: tipoModelo,
        cantidad_base: Number(editCantidad),
        escala: editEscala,
        costo_unitario: Number(editCosto),
        producto_id: editProductoId && editProductoId.trim() !== '' ? editProductoId : null,
        costo_desde_producto: editCostoDesdeProducto
      };

      const res = await fetch(`${BASE_URL}/catalogo-costos/opciones/${opcionEnEdicion.opcion_id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al guardar opción');
      }

      toast.success('Costo actualizado correctamente', {
        description: 'Esto afecta a las cotizaciones nuevas y a las que se vuelvan a calcular'
      });
      setModalOpcionOpen(false);
      cargarOpcionesTipo(tipoModelo);
    } catch (err: any) {
      toast.error('Error al guardar opción', { description: err.message });
    } finally {
      setSavingOpcion(false);
    }
  };

  // Guardar Kit
  const handleGuardarKit = async () => {
    if (!canEdit) return;
    const val = validarKitEdicion({ cantidad: kitCantidad, costo_unitario: kitCostoUnitario });
    if (!val.valido) {
      toast.error('Error de validación', { description: val.error });
      return;
    }

    try {
      setSavingKit(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const body = {
        cantidad: Number(kitCantidad),
        costo_unitario: Number(kitCostoUnitario),
        concepto: kitConcepto
      };

      const res = await fetch(`${BASE_URL}/catalogo-costos/modelos/${selectedModeloId}/kits/${kitEnEdicion.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al actualizar kit');
      }

      toast.success('Kit actualizado exitosamente', {
        description: 'Esto afecta a las cotizaciones nuevas y a las que se vuelvan a calcular'
      });
      setModalKitOpen(false);
      cargarDetalleModelo(selectedModeloId);
    } catch (err: any) {
      toast.error('Error guardando kit', { description: err.message });
    } finally {
      setSavingKit(false);
    }
  };

  // Guardar Proceso
  const handleGuardarProceso = async () => {
    if (!canEdit) return;
    const val = validarProcesoEdicion({ minutos: procesoMinutos, tarifa_hora: procesoTarifaHora });
    if (!val.valido) {
      toast.error('Error de validación', { description: val.error });
      return;
    }

    try {
      setSavingProceso(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const body = {
        minutos: Number(procesoMinutos),
        tarifa_hora: Number(procesoTarifaHora)
      };

      const res = await fetch(`${BASE_URL}/catalogo-costos/procesos/${procesoEnEdicion.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify(body)
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al actualizar proceso');
      }

      toast.success('Proceso actualizado exitosamente', {
        description: 'Esto afecta a las cotizaciones nuevas y a las que se vuelvan a calcular'
      });
      setModalProcesoOpen(false);
      cargarDetalleModelo(selectedModeloId);
    } catch (err: any) {
      toast.error('Error guardando proceso', { description: err.message });
    } finally {
      setSavingProceso(false);
    }
  };

  // Guardar parámetros de ganancia
  const handleGuardarGanancias = async () => {
    if (!canEdit) return;
    if (
      !validarGananciaMonto(ganancias.plataforma).valido ||
      !validarGananciaMonto(ganancias.dolly).valido ||
      !validarGananciaMonto(ganancias.gondola_servicios_sueldos).valido
    ) {
      toast.error('Todos los montos de ganancia deben ser números mayores o iguales a 0');
      return;
    }

    try {
      setSavingGanancia(true);
      const { data: { session: currentSession } } = await supabase.auth.getSession();
      const token = currentSession?.access_token;

      const res = await fetch(`${BASE_URL}/catalogo-costos/parametros`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`
        },
        body: JSON.stringify({ ganancia_factura: ganancias })
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error guardando parámetros');
      }

      toast.success('Parámetros de ganancia actualizados', {
        description: 'Esto afecta a las cotizaciones nuevas y a las que se vuelvan a calcular'
      });
    } catch (err: any) {
      toast.error('Error al guardar ganancias', { description: err.message });
    } finally {
      setSavingGanancia(false);
    }
  };

  // Producto seleccionado actualmente en el modal de edición
  const productoSeleccionadoEnModal = useMemo(() => {
    if (!editProductoId) return null;
    return productosDisponibles.find(p => p.id === editProductoId) || null;
  }, [editProductoId, productosDisponibles]);

  // Ver si el costo del producto difiere del costo de la opción
  const costoProductoDifiere = useMemo(() => {
    if (!productoSeleccionadoEnModal || productoSeleccionadoEnModal.costo === null || productoSeleccionadoEnModal.costo === undefined) return false;
    return Number(productoSeleccionadoEnModal.costo) !== Number(editCosto);
  }, [productoSeleccionadoEnModal, editCosto]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4 border-b border-border/50 pb-4">
        <div>
          <div className="flex items-center gap-3">
            <h1 className="text-2xl sm:text-3xl font-bold tracking-tight text-foreground">Catálogo de Costos</h1>
            <Badge variant="outline" className="text-xs">Sub-bloque 2R-7</Badge>
          </div>
          <p className="text-sm text-muted-foreground mt-1">
            Administra los costos unitarios del cotizador, liga opciones con inventario y consulta la trazabilidad de cambios.
          </p>
        </div>

        {/* Selector de Tipo de Remolque */}
        <div className="flex items-center gap-2">
          <Label className="text-sm font-medium text-muted-foreground whitespace-nowrap">Tipo:</Label>
          <div className="flex rounded-lg border border-border p-1 bg-muted/30">
            <Button
              type="button"
              size="sm"
              variant={tipoModelo === 'plataforma' ? 'default' : 'ghost'}
              className="text-xs h-8"
              onClick={() => setTipoModelo('plataforma')}
            >
              Plataforma
            </Button>
            <Button
              type="button"
              size="sm"
              variant={tipoModelo === 'dolly' ? 'default' : 'ghost'}
              className="text-xs h-8"
              onClick={() => setTipoModelo('dolly')}
            >
              Dolly
            </Button>
            <Button
              type="button"
              size="sm"
              variant={tipoModelo === 'gondola' ? 'default' : 'ghost'}
              className="text-xs h-8"
              onClick={() => setTipoModelo('gondola')}
            >
              Góndola
            </Button>
          </div>
        </div>
      </div>

      {/* Banner de Sólo Lectura si no es propietario/admin */}
      {!checkingRole && !canEdit && (
        <div className="flex items-center gap-3 p-4 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900 text-amber-800 dark:text-amber-300 text-sm">
          <ShieldCheck className="h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400" />
          <div>
            <span className="font-semibold">Modo solo lectura:</span> Tu rol actual ({userRole}) te permite consultar los costos. Para modificarlos, confirma con un usuario propietario o administrador.
          </div>
        </div>
      )}

      {/* Pestañas Principales */}
      <Tabs value={activeTab} onValueChange={(val: any) => setActiveTab(val)} className="space-y-4">
        <TabsList className="grid grid-cols-2 sm:grid-cols-5 w-full bg-muted/50 p-1">
          <TabsTrigger value="opciones" className="flex items-center gap-2 text-xs sm:text-sm">
            <Package className="h-4 w-4" />
            Opciones
          </TabsTrigger>
          <TabsTrigger value="kits" className="flex items-center gap-2 text-xs sm:text-sm">
            <Wrench className="h-4 w-4" />
            Kits y Mano de Obra
          </TabsTrigger>
          <TabsTrigger value="utilidad" className="flex items-center gap-2 text-xs sm:text-sm">
            <TrendingUp className="h-4 w-4" />
            Utilidad
          </TabsTrigger>
          <TabsTrigger value="cobertura" className="flex items-center gap-2 text-xs sm:text-sm">
            <CheckCircle2 className="h-4 w-4" />
            Cobertura
          </TabsTrigger>
          <TabsTrigger value="historial" className="flex items-center gap-2 text-xs sm:text-sm">
            <History className="h-4 w-4" />
            Historial
          </TabsTrigger>
        </TabsList>

        {/* ─── PESTAÑA 1: OPCIONES ──────────────────────────────────────────────── */}
        <TabsContent value="opciones" className="space-y-4">
          {/* Barra de Filtros */}
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-3 p-3 rounded-lg border border-border bg-card">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar opción, grupo o producto ligado..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="pl-9 h-9 text-sm"
              />
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <Button
                size="sm"
                variant={soloPendientes ? 'default' : 'outline'}
                className="text-xs h-9"
                onClick={() => {
                  setSoloPendientes(!soloPendientes);
                  if (!soloPendientes) setSoloSinCosto(false);
                }}
              >
                <AlertTriangle className="h-3.5 w-3.5 mr-1 text-amber-500" />
                Solo pendientes (Tarifario/Supuesto)
              </Button>
              <Button
                size="sm"
                variant={soloSinCosto ? 'destructive' : 'outline'}
                className="text-xs h-9"
                onClick={() => {
                  setSoloSinCosto(!soloSinCosto);
                  if (!soloSinCosto) setSoloPendientes(false);
                }}
              >
                <HelpCircle className="h-3.5 w-3.5 mr-1 text-red-500" />
                Solo sin costo
              </Button>
            </div>
          </div>

          {/* Tabla de Opciones agrupadas */}
          {loading ? (
            <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
              <Loader2 className="h-8 w-8 animate-spin mb-2" />
              <p className="text-sm">Cargando opciones para {tipoModelo}...</p>
            </div>
          ) : opcionesPorGrupo.length === 0 ? (
            <div className="text-center py-16 border border-dashed border-border rounded-lg text-muted-foreground">
              <p className="text-sm">No se encontraron opciones con los filtros aplicados.</p>
            </div>
          ) : (
            <div className="space-y-6">
              {opcionesPorGrupo.map((grupo) => (
                <Card key={grupo.grupo_clave} className="border-border/60 shadow-sm overflow-hidden">
                  <CardHeader className="bg-muted/30 py-3 px-4 border-b border-border/40">
                    <div className="flex items-center justify-between">
                      <CardTitle className="text-base font-semibold text-foreground">
                        {grupo.grupo_nombre}
                      </CardTitle>
                      <Badge variant="secondary" className="text-xs font-normal">
                        {grupo.items.length} {grupo.items.length === 1 ? 'opción' : 'opciones'}
                      </Badge>
                    </div>
                  </CardHeader>
                  <CardContent className="p-0">
                    <div className="overflow-x-auto">
                      <table className="w-full text-left text-sm">
                        <thead className="bg-muted/10 border-b border-border/40 text-xs text-muted-foreground uppercase">
                          <tr>
                            <th className="py-2.5 px-4 font-medium">Opción</th>
                            <th className="py-2.5 px-4 font-medium">Costo Unitario</th>
                            <th className="py-2.5 px-4 font-medium">Cantidad / Escala</th>
                            <th className="py-2.5 px-4 font-medium">Origen / Insignia</th>
                            <th className="py-2.5 px-4 font-medium">Producto Ligado</th>
                            <th className="py-2.5 px-4 font-medium">Receta</th>
                            <th className="py-2.5 px-4 text-right font-medium">Acciones</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/40">
                          {grupo.items.map((opt) => {
                            const ins = obtenerInsigniaFuente(opt.fuente, opt.costo_desde_producto);
                            return (
                              <tr key={opt.opcion_id} className="hover:bg-muted/20 transition-colors">
                                <td className="py-3 px-4">
                                  <div className="font-medium text-foreground">{opt.opcion_nombre}</div>
                                  <div className="text-xs text-muted-foreground font-mono">{opt.opcion_clave}</div>
                                </td>
                                <td className="py-3 px-4">
                                  <div className="font-semibold text-foreground">
                                    {opt.costo_desde_producto && opt.producto_costo !== null
                                      ? formatearMoneda(opt.producto_costo)
                                      : formatearMoneda(opt.costo_unitario)}
                                  </div>
                                  {opt.costo_desde_producto && (
                                    <div className="text-[11px] text-blue-600 dark:text-blue-400">
                                      Dinámico de Producto
                                    </div>
                                  )}
                                </td>
                                <td className="py-3 px-4 text-xs text-muted-foreground">
                                  <div>Base: {opt.cantidad_base}</div>
                                  <div className="capitalize">{opt.escala.replace('_', ' ')}</div>
                                </td>
                                <td className="py-3 px-4">
                                  <span
                                    title={ins.descripcion}
                                    className={`inline-flex items-center px-2 py-0.5 rounded text-xs font-medium cursor-help ${ins.colorClase}`}
                                  >
                                    {ins.texto}
                                  </span>
                                </td>
                                <td className="py-3 px-4 text-xs">
                                  {opt.producto_nombre ? (
                                    <div className="max-w-[180px]">
                                      <div className="truncate font-medium text-foreground" title={opt.producto_nombre}>
                                        {opt.producto_nombre}
                                      </div>
                                      <div className="text-muted-foreground">
                                        Costo: {formatearMoneda(opt.producto_costo)}
                                      </div>
                                    </div>
                                  ) : (
                                    <span className="text-muted-foreground italic">Sin producto</span>
                                  )}
                                </td>
                                <td className="py-3 px-4 text-xs">
                                  {opt.receta_piezas_count > 0 ? (
                                    <Badge variant="secondary" className="text-xs font-normal">
                                      {opt.receta_piezas_count} pzs
                                    </Badge>
                                  ) : (
                                    <span className="text-muted-foreground">0 pzs</span>
                                  )}
                                </td>
                                <td className="py-3 px-4 text-right space-x-1 whitespace-nowrap">
                                  {ins.esPendiente && canEdit && (
                                    <Button
                                      size="sm"
                                      variant="outline"
                                      className="h-8 text-xs text-amber-700 dark:text-amber-400 border-amber-300 dark:border-amber-800 hover:bg-amber-50 dark:hover:bg-amber-950/40"
                                      onClick={() => handleConfirmarCosto(opt)}
                                    >
                                      Confirmar
                                    </Button>
                                  )}
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    className="h-8 text-xs"
                                    disabled={!canEdit}
                                    onClick={() => handleEditarOpcion(opt)}
                                  >
                                    <Edit2 className="h-3.5 w-3.5 mr-1" />
                                    Editar
                                  </Button>
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  </CardContent>
                </Card>
              ))}
            </div>
          )}
        </TabsContent>

        {/* ─── PESTAÑA 2: KITS Y MANO DE OBRA ──────────────────────────────────── */}
        <TabsContent value="kits" className="space-y-6">
          {/* Selector de Modelo Específico */}
          <div className="flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 p-4 rounded-lg border border-border bg-card">
            <div>
              <Label className="text-sm font-semibold text-foreground">Modelo a Inspeccionar:</Label>
              <p className="text-xs text-muted-foreground">
                Selecciona la variante de remolque para ver kits fijos y tiempos de manufactura.
              </p>
            </div>
            <Select value={selectedModeloId} onValueChange={(val) => setSelectedModeloId(val)}>
              <SelectTrigger className="w-full sm:w-[320px] h-9 text-sm">
                <SelectValue placeholder="Selecciona un modelo..." />
              </SelectTrigger>
              <SelectContent>
                {modelos.map((m) => (
                  <SelectItem key={m.id} value={m.id}>
                    {m.productos?.nombre || `${m.tipo.toUpperCase()} ${m.largo_ft}ft (${m.num_ejes}e)`}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          {loadingModelo ? (
            <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
              <Loader2 className="h-8 w-8 animate-spin mb-2" />
              <p className="text-sm">Cargando desglose del modelo...</p>
            </div>
          ) : !datosModelo ? (
            <div className="text-center py-16 border border-dashed border-border rounded-lg text-muted-foreground">
              <p className="text-sm">Selecciona un modelo para consultar sus kits y mano de obra.</p>
            </div>
          ) : (
            <div className="space-y-6">
              {/* Tarjetas de Totales */}
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Total Kits Fijos</CardDescription>
                    <CardTitle className="text-2xl font-bold text-foreground">
                      {formatearMoneda(datosModelo.totales?.total_kits)}
                    </CardTitle>
                  </CardHeader>
                </Card>
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Total Mano de Obra</CardDescription>
                    <CardTitle className="text-2xl font-bold text-foreground">
                      {formatearMoneda(datosModelo.totales?.total_mano_obra)}
                    </CardTitle>
                  </CardHeader>
                </Card>
              </div>

              {/* Tabla 1: costos_modelo (Kits Fijos) */}
              <Card className="border-border/60">
                <CardHeader className="py-3 px-4 border-b border-border/40">
                  <CardTitle className="text-base font-semibold text-foreground">
                    Kits Fijos de Modelo ({datosModelo.costos_modelo?.length || 0})
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                      <thead className="bg-muted/10 border-b border-border/40 text-xs text-muted-foreground uppercase">
                        <tr>
                          <th className="py-2.5 px-4 font-medium">Sección</th>
                          <th className="py-2.5 px-4 font-medium">Concepto</th>
                          <th className="py-2.5 px-4 font-medium">Cantidad</th>
                          <th className="py-2.5 px-4 font-medium">Costo Unitario</th>
                          <th className="py-2.5 px-4 font-medium">Escala</th>
                          <th className="py-2.5 px-4 font-medium">Importe Base</th>
                          <th className="py-2.5 px-4 text-right font-medium">Acción</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border/40">
                        {datosModelo.costos_modelo?.map((k: any) => (
                          <tr key={k.id} className="hover:bg-muted/20">
                            <td className="py-2.5 px-4 text-xs font-mono capitalize">{k.seccion}</td>
                            <td className="py-2.5 px-4 font-medium text-foreground">{k.concepto}</td>
                            <td className="py-2.5 px-4 text-xs">{k.cantidad}</td>
                            <td className="py-2.5 px-4 font-semibold text-foreground">
                              {formatearMoneda(k.costo_unitario)}
                            </td>
                            <td className="py-2.5 px-4 text-xs capitalize">{k.escala.replace('_', ' ')}</td>
                            <td className="py-2.5 px-4 font-semibold text-foreground">
                              {formatearMoneda(k.cantidad * k.costo_unitario)}
                            </td>
                            <td className="py-2.5 px-4 text-right">
                              <Button
                                size="sm"
                                variant="ghost"
                                className="h-7 text-xs"
                                disabled={!canEdit}
                                onClick={() => {
                                  setKitEnEdicion(k);
                                  setKitCantidad(String(k.cantidad));
                                  setKitCostoUnitario(String(k.costo_unitario));
                                  setKitConcepto(k.concepto);
                                  setModalKitOpen(true);
                                }}
                              >
                                Editar
                              </Button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>

              {/* Tabla 2: procesos_manufactura */}
              <Card className="border-border/60">
                <CardHeader className="py-3 px-4 border-b border-border/40">
                  <CardTitle className="text-base font-semibold text-foreground">
                    Procesos de Manufactura ({datosModelo.procesos_manufactura?.length || 0})
                  </CardTitle>
                </CardHeader>
                <CardContent className="p-0">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left text-sm">
                      <thead className="bg-muted/10 border-b border-border/40 text-xs text-muted-foreground uppercase">
                        <tr>
                          <th className="py-2.5 px-4 font-medium">Orden</th>
                          <th className="py-2.5 px-4 font-medium">Proceso</th>
                          <th className="py-2.5 px-4 font-medium">Subproceso</th>
                          <th className="py-2.5 px-4 font-medium">Minutos</th>
                          <th className="py-2.5 px-4 font-medium">Tarifa / Hora</th>
                          <th className="py-2.5 px-4 font-medium">Importe</th>
                          <th className="py-2.5 px-4 text-right font-medium">Acción</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-border/40">
                        {datosModelo.procesos_manufactura?.map((p: any) => {
                          const imp = (p.minutos * p.tarifa_hora) / 60;
                          return (
                            <tr key={p.id} className="hover:bg-muted/20">
                              <td className="py-2.5 px-4 text-xs font-mono">{p.orden}</td>
                              <td className="py-2.5 px-4 font-medium text-foreground">{p.proceso}</td>
                              <td className="py-2.5 px-4 text-xs text-muted-foreground">{p.subproceso || '-'}</td>
                              <td className="py-2.5 px-4 text-xs">{p.minutos} min</td>
                              <td className="py-2.5 px-4 font-semibold text-foreground">
                                {formatearMoneda(p.tarifa_hora)}
                              </td>
                              <td className="py-2.5 px-4 font-semibold text-foreground">
                                {formatearMoneda(imp)}
                              </td>
                              <td className="py-2.5 px-4 text-right">
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-7 text-xs"
                                  disabled={!canEdit}
                                  onClick={() => {
                                    setProcesoEnEdicion(p);
                                    setProcesoMinutos(String(p.minutos));
                                    setProcesoTarifaHora(String(p.tarifa_hora));
                                    setModalProcesoOpen(true);
                                  }}
                                >
                                  Editar
                                </Button>
                              </td>
                            </tr>
                          );
                        })}
                      </tbody>
                    </table>
                  </div>
                </CardContent>
              </Card>
            </div>
          )}
        </TabsContent>

        {/* ─── PESTAÑA 3: UTILIDAD ─────────────────────────────────────────────── */}
        <TabsContent value="utilidad" className="space-y-6">
          <Card className="border-border/60 max-w-2xl">
            <CardHeader className="py-4 px-6 border-b border-border/40">
              <CardTitle className="text-lg font-semibold text-foreground">
                Parámetros de Ganancia Factura
              </CardTitle>
              <CardDescription className="text-sm">
                Hoy la ganancia del fabricante se maneja como un monto fijo en pesos por unidad vendida. El dueño aún no define si transicionará a porcentaje.
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-5 p-6">
              <div className="space-y-2">
                <Label htmlFor="ganancia-plat" className="text-sm font-medium">Plataforma (Monto Fijo MXN)</Label>
                <Input
                  id="ganancia-plat"
                  type="number"
                  disabled={!canEdit}
                  value={ganancias.plataforma}
                  onChange={(e) => setGanancias({ ...ganancias, plataforma: Number(e.target.value) })}
                  className="font-mono text-base"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="ganancia-dolly" className="text-sm font-medium">Dolly (Monto Fijo MXN)</Label>
                <Input
                  id="ganancia-dolly"
                  type="number"
                  disabled={!canEdit}
                  value={ganancias.dolly}
                  onChange={(e) => setGanancias({ ...ganancias, dolly: Number(e.target.value) })}
                  className="font-mono text-base"
                />
              </div>

              <div className="space-y-2">
                <Label htmlFor="ganancia-gondola" className="text-sm font-medium">Góndola (Servicios y Sueldos MXN)</Label>
                <Input
                  id="ganancia-gondola"
                  type="number"
                  disabled={!canEdit}
                  value={ganancias.gondola_servicios_sueldos}
                  onChange={(e) => setGanancias({ ...ganancias, gondola_servicios_sueldos: Number(e.target.value) })}
                  className="font-mono text-base"
                />
              </div>

              <div className="pt-2">
                <Button
                  onClick={handleGuardarGanancias}
                  disabled={!canEdit || savingGanancia}
                  className="w-full sm:w-auto"
                >
                  {savingGanancia ? (
                    <>
                      <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                      Guardando...
                    </>
                  ) : (
                    'Guardar Parámetros de Ganancia'
                  )}
                </Button>
              </div>
            </CardContent>
          </Card>
        </TabsContent>

        {/* ─── PESTAÑA 4: COBERTURA ────────────────────────────────────────────── */}
        <TabsContent value="cobertura" className="space-y-6">
          {cobertura ? (
            <div className="space-y-6">
              {/* Resumen de Métricas */}
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-4">
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Opciones Totales</CardDescription>
                    <CardTitle className="text-2xl font-bold text-foreground">
                      {cobertura.total_opciones}
                    </CardTitle>
                  </CardHeader>
                </Card>
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Con Costo Asignado</CardDescription>
                    <CardTitle className="text-2xl font-bold text-emerald-600 dark:text-emerald-400">
                      {cobertura.con_costo}
                    </CardTitle>
                  </CardHeader>
                </Card>
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Sin Costo</CardDescription>
                    <CardTitle className="text-2xl font-bold text-red-600 dark:text-red-400">
                      {cobertura.sin_costo}
                    </CardTitle>
                  </CardHeader>
                </Card>
                <Card className="border-border/60">
                  <CardHeader className="py-3 px-4">
                    <CardDescription className="text-xs">Con Receta de Piezas</CardDescription>
                    <CardTitle className="text-2xl font-bold text-blue-600 dark:text-blue-400">
                      {cobertura.con_receta}
                    </CardTitle>
                  </CardHeader>
                </Card>
              </div>

              {/* Opciones Faltantes de Costo */}
              <Card className="border-border/60">
                <CardHeader className="py-3 px-4 border-b border-border/40">
                  <CardTitle className="text-base font-semibold text-foreground">
                    Opciones Sin Costo en {tipoModelo} ({cobertura.sin_costo})
                  </CardTitle>
                  <CardDescription className="text-xs">
                    Estas opciones generarán aviso de opción sin costo en caso de ser elegidas en una cotización.
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-4">
                  {cobertura.opciones_sin_costo?.length === 0 ? (
                    <div className="flex items-center gap-2 text-emerald-600 dark:text-emerald-400 text-sm">
                      <CheckCircle2 className="h-5 w-5" />
                      <span>Todas las opciones activas cuentan con un registro de costo.</span>
                    </div>
                  ) : (
                    <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
                      {cobertura.opciones_sin_costo?.map((item: any) => (
                        <div
                          key={item.opcion_id}
                          className="flex items-center justify-between p-2 rounded border border-border bg-muted/20 text-xs"
                        >
                          <div>
                            <span className="font-semibold text-foreground">{item.opcion_nombre}</span>
                            <span className="text-muted-foreground ml-1">({item.grupo_clave})</span>
                          </div>
                          {canEdit && (
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-6 text-[11px] px-2"
                              onClick={() => {
                                const found = opciones.find(o => o.opcion_id === item.opcion_id);
                                if (found) handleEditarOpcion(found);
                              }}
                            >
                              Asignar
                            </Button>
                          )}
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              </Card>

              {/* Opciones Faltantes de Receta de Piezas */}
              <Card className="border-border/60">
                <CardHeader className="py-3 px-4 border-b border-border/40">
                  <CardTitle className="text-base font-semibold text-foreground">
                    Opciones Sin Piezas en Receta ({cobertura.sin_receta})
                  </CardTitle>
                  <CardDescription className="text-xs">
                    Opciones que no tienen componentes detallados en la tabla opcion_componentes.
                  </CardDescription>
                </CardHeader>
                <CardContent className="p-4">
                  <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-2">
                    {cobertura.opciones_sin_receta?.map((item: any) => (
                      <div
                        key={item.opcion_id}
                        className="p-2 rounded border border-border bg-muted/20 text-xs text-muted-foreground"
                      >
                        <span className="font-medium text-foreground">{item.opcion_nombre}</span> ({item.grupo_clave})
                      </div>
                    ))}
                  </div>
                </CardContent>
              </Card>
            </div>
          ) : (
            <div className="text-center py-16 text-muted-foreground">
              Cargando estadísticas de cobertura...
            </div>
          )}
        </TabsContent>

        {/* ─── PESTAÑA 5: HISTORIAL ────────────────────────────────────────────── */}
        <TabsContent value="historial" className="space-y-4">
          <Card className="border-border/60">
            <CardHeader className="py-3 px-4 border-b border-border/40 flex flex-row items-center justify-between">
              <div>
                <CardTitle className="text-base font-semibold text-foreground">
                  Trazabilidad de Cambios (Últimos 100)
                </CardTitle>
                <CardDescription className="text-xs">
                  Registro inmutable de modificaciones en costos, kits, procesos y utilidad.
                </CardDescription>
              </div>
              <Button size="sm" variant="outline" className="h-8 text-xs" onClick={cargarHistorial}>
                Actualizar
              </Button>
            </CardHeader>
            <CardContent className="p-0">
              {loadingHistorial ? (
                <div className="flex flex-col items-center justify-center py-20 text-muted-foreground">
                  <Loader2 className="h-8 w-8 animate-spin mb-2" />
                  <p className="text-sm">Cargando historial...</p>
                </div>
              ) : historial.length === 0 ? (
                <div className="text-center py-16 text-muted-foreground text-sm">
                  No hay cambios registrados en el historial aún.
                </div>
              ) : (
                <div className="overflow-x-auto">
                  <table className="w-full text-left text-sm">
                    <thead className="bg-muted/10 border-b border-border/40 text-xs text-muted-foreground uppercase">
                      <tr>
                        <th className="py-2.5 px-4 font-medium">Fecha</th>
                        <th className="py-2.5 px-4 font-medium">Tabla</th>
                        <th className="py-2.5 px-4 font-medium">Concepto</th>
                        <th className="py-2.5 px-4 font-medium">Campo</th>
                        <th className="py-2.5 px-4 font-medium">Antes → Después</th>
                        <th className="py-2.5 px-4 font-medium">Usuario</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/40">
                      {historial.map((h) => (
                        <tr key={h.id} className="hover:bg-muted/20">
                          <td className="py-2.5 px-4 text-xs text-muted-foreground whitespace-nowrap">
                            {new Date(h.creado_en).toLocaleString('es-MX')}
                          </td>
                          <td className="py-2.5 px-4 text-xs font-mono">{h.tabla}</td>
                          <td className="py-2.5 px-4 text-xs font-medium text-foreground">{h.concepto || '-'}</td>
                          <td className="py-2.5 px-4 text-xs font-mono">{h.campo}</td>
                          <td className="py-2.5 px-4 text-xs">
                            <span className="text-red-500 line-through mr-1">{h.valor_anterior || 'null'}</span>
                            <span className="text-muted-foreground">→</span>
                            <span className="text-emerald-600 dark:text-emerald-400 font-semibold ml-1">
                              {h.valor_nuevo || 'null'}
                            </span>
                          </td>
                          <td className="py-2.5 px-4 text-xs text-muted-foreground font-mono">
                            {h.usuario_id ? `${h.usuario_id.slice(0, 8)}...` : '-'}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* ─── MODAL DE EDICIÓN DE OPCIÓN ────────────────────────────────────────── */}
      <Dialog open={modalOpcionOpen} onOpenChange={setModalOpcionOpen}>
        <DialogContent className="sm:max-w-[540px]">
          <DialogHeader>
            <DialogTitle>Editar Costo de Opción</DialogTitle>
            <DialogDescription>
              {opcionEnEdicion?.grupo_nombre}: {opcionEnEdicion?.opcion_nombre} ({tipoModelo})
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-4">
              <div className="space-y-1.5">
                <Label htmlFor="edit-costo" className="text-xs">Costo Unitario (MXN)</Label>
                <Input
                  id="edit-costo"
                  type="number"
                  step="any"
                  value={editCosto}
                  onChange={(e) => setEditCosto(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="edit-cantidad" className="text-xs">Cantidad Base</Label>
                <Input
                  id="edit-cantidad"
                  type="number"
                  step="any"
                  value={editCantidad}
                  onChange={(e) => setEditCantidad(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
            </div>

            <div className="space-y-1.5">
              <Label htmlFor="edit-escala" className="text-xs">Escala</Label>
              <Select value={editEscala} onValueChange={(val) => setEditEscala(val)}>
                <SelectTrigger id="edit-escala" className="h-9 text-sm">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="fija">Fija (1 unidad)</SelectItem>
                  <SelectItem value="por_eje">Por Eje (multiplica num_ejes)</SelectItem>
                  <SelectItem value="por_largo">Por Largo (multiplica largo_ft / 40)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            {/* Selector de Producto Ligado */}
            <div className="space-y-2 border-t border-border/50 pt-3">
              <div className="flex items-center justify-between">
                <Label htmlFor="edit-producto" className="text-xs font-semibold text-foreground">
                  Producto Ligado (Inventario)
                </Label>
                {productoSeleccionadoEnModal && (
                  <Badge variant="outline" className="text-[11px]">
                    Costo en catálogo: {formatearMoneda(productoSeleccionadoEnModal.costo)}
                  </Badge>
                )}
              </div>

              <Select
                value={editProductoId || '__ninguno__'}
                onValueChange={(val) => setEditProductoId(val === '__ninguno__' ? '' : val)}
              >
                <SelectTrigger id="edit-producto" className="h-9 text-sm">
                  <SelectValue placeholder="Sin producto ligado" />
                </SelectTrigger>
                <SelectContent className="max-h-[220px]">
                  <SelectItem value="__ninguno__">-- Sin producto ligado --</SelectItem>
                  {productosDisponibles.map((p) => (
                    <SelectItem key={p.id} value={p.id}>
                      {p.nombre} ({formatearMoneda(p.costo)})
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>

              {/* Aviso si el costo del producto difiere del costo de la opción */}
              {costoProductoDifiere && (
                <div className="flex items-center gap-2 p-2 rounded bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-800 text-amber-800 dark:text-amber-300 text-xs">
                  <AlertTriangle className="h-4 w-4 shrink-0 text-amber-600 dark:text-amber-400" />
                  <span>
                    El costo del producto ({formatearMoneda(productoSeleccionadoEnModal?.costo)}) difiere del costo asignado a esta opción ({formatearMoneda(Number(editCosto))}).
                  </span>
                </div>
              )}

              {/* Interruptor: Usar el costo del producto */}
              {editProductoId && (
                <div className="flex items-center justify-between p-2.5 rounded bg-muted/40 border border-border/60">
                  <div className="space-y-0.5">
                    <Label htmlFor="switch-dinamico" className="text-xs font-medium cursor-pointer">
                      Usar el costo del producto dinámicamente
                    </Label>
                    <p className="text-[11px] text-muted-foreground">
                      El cotizador tomará el costo vigente del producto en el momento de costear.
                    </p>
                  </div>
                  <Switch
                    id="switch-dinamico"
                    checked={editCostoDesdeProducto}
                    onCheckedChange={setEditCostoDesdeProducto}
                  />
                </div>
              )}
            </div>

            {/* Aviso de impacto */}
            <div className="flex items-start gap-2 p-3 rounded-lg bg-blue-50 dark:bg-blue-950/30 border border-blue-200 dark:border-blue-900 text-blue-800 dark:text-blue-300 text-xs">
              <Info className="h-4 w-4 shrink-0 text-blue-600 dark:text-blue-400 mt-0.5" />
              <span>
                Cualquier cambio guardado afectará inmediatamente a las cotizaciones nuevas y a las que se vuelvan a calcular.
              </span>
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalOpcionOpen(false)}
              disabled={savingOpcion}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              onClick={handleGuardarOpcion}
              disabled={savingOpcion}
            >
              {savingOpcion ? (
                <>
                  <Loader2 className="h-4 w-4 mr-2 animate-spin" />
                  Guardando...
                </>
              ) : (
                'Guardar Cambios'
              )}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ─── MODAL DE EDICIÓN DE KIT ───────────────────────────────────────────── */}
      <Dialog open={modalKitOpen} onOpenChange={setModalKitOpen}>
        <DialogContent className="sm:max-w-[420px]">
          <DialogHeader>
            <DialogTitle>Editar Kit Fijo</DialogTitle>
            <DialogDescription>
              {kitEnEdicion?.seccion}: {kitEnEdicion?.concepto}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="space-y-1.5">
              <Label htmlFor="kit-concepto" className="text-xs">Concepto</Label>
              <Input
                id="kit-concepto"
                value={kitConcepto}
                onChange={(e) => setKitConcepto(e.target.value)}
                className="text-sm"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="kit-cantidad" className="text-xs">Cantidad</Label>
                <Input
                  id="kit-cantidad"
                  type="number"
                  step="any"
                  value={kitCantidad}
                  onChange={(e) => setKitCantidad(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="kit-costo" className="text-xs">Costo Unitario (MXN)</Label>
                <Input
                  id="kit-costo"
                  type="number"
                  step="any"
                  value={kitCostoUnitario}
                  onChange={(e) => setKitCostoUnitario(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalKitOpen(false)}
              disabled={savingKit}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              onClick={handleGuardarKit}
              disabled={savingKit}
            >
              {savingKit ? 'Guardando...' : 'Guardar Kit'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ─── MODAL DE EDICIÓN DE PROCESO ──────────────────────────────────────── */}
      <Dialog open={modalProcesoOpen} onOpenChange={setModalProcesoOpen}>
        <DialogContent className="sm:max-w-[420px]">
          <DialogHeader>
            <DialogTitle>Editar Proceso de Manufactura</DialogTitle>
            <DialogDescription>
              {procesoEnEdicion?.proceso} {procesoEnEdicion?.subproceso ? `(${procesoEnEdicion.subproceso})` : ''}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label htmlFor="proc-minutos" className="text-xs">Minutos</Label>
                <Input
                  id="proc-minutos"
                  type="number"
                  step="any"
                  value={procesoMinutos}
                  onChange={(e) => setProcesoMinutos(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
              <div className="space-y-1.5">
                <Label htmlFor="proc-tarifa" className="text-xs">Tarifa / Hora (MXN)</Label>
                <Input
                  id="proc-tarifa"
                  type="number"
                  step="any"
                  value={procesoTarifaHora}
                  onChange={(e) => setProcesoTarifaHora(e.target.value)}
                  className="font-mono text-sm"
                />
              </div>
            </div>
          </div>

          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              onClick={() => setModalProcesoOpen(false)}
              disabled={savingProceso}
            >
              Cancelar
            </Button>
            <Button
              type="button"
              onClick={handleGuardarProceso}
              disabled={savingProceso}
            >
              {savingProceso ? 'Guardando...' : 'Guardar Proceso'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
