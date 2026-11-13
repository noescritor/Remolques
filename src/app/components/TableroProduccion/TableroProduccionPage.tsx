import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import {
  fetchMatrizProduccion,
  actualizarFaseOrden,
  actualizarPlaneacionOrden,
  sembrarTableroProduccion,
  MatrizRespuesta,
  FilaMatriz,
} from '../../utils/tableroApi';
import {
  obtenerHoyMexico,
  formatearFechaHoyCompleta,
  filtrarFilasMatriz,
  aplicarCambioOptimistaFase,
  FiltroChip,
  EstadoFase,
} from '../../utils/tableroProduccion';
import { MatrizProduccionView } from './MatrizProduccionView';
import { OrdenTrabajoDetalleSheet } from './OrdenTrabajoDetalleSheet';
import { VistaPorFase } from './VistaPorFase';
import { NuevoEquipoModal } from './NuevoEquipoModal';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Badge } from '../ui/badge';
import {
  Search,
  RefreshCw,
  Plus,
  LayoutGrid,
  Kanban,
  AlertTriangle,
  Clock,
  PackageX,
  PauseCircle,
  Database,
} from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '../ui/utils';

interface TableroProduccionPageProps {
  session?: any;
}

const LINEAS_TABLERO = [
  { clave: 'plataforma', nombre: 'Plataforma' },
  { clave: 'gondola', nombre: 'Góndola' },
  { clave: 'dolly', nombre: 'Dolly' },
  { clave: 'traila', nombre: 'Traila' },
];

export function TableroProduccionPage({ session }: TableroProduccionPageProps) {
  const [searchParams, setSearchParams] = useSearchParams();

  // Línea activa sincronizada con URL (?linea=plataforma|gondola|dolly|traila)
  const lineaUrl = searchParams.get('linea')?.toLowerCase() || 'plataforma';
  const lineaActiva = LINEAS_TABLERO.some((l) => l.clave === lineaUrl)
    ? lineaUrl
    : 'plataforma';

  // Vista activa sincronizada con URL (?vista=matriz|fase)
  const vistaUrl = searchParams.get('vista')?.toLowerCase() || 'matriz';
  const vistaActiva = vistaUrl === 'fase' ? 'fase' : 'matriz';

  // Filtro de chips y búsqueda
  const [filtroChip, setFiltroChip] = useState<FiltroChip>('todos');
  const [busqueda, setBusqueda] = useState<string>('');

  // Datos de la matriz
  const [datosMatriz, setDatosMatriz] = useState<MatrizRespuesta | null>(null);
  const [cargando, setCargando] = useState<boolean>(true);
  const [refrescando, setRefrescando] = useState<boolean>(false);
  const [errorCarga, setErrorCarga] = useState<string | null>(null);

  // Orden seleccionada para panel de detalle (Bloque 2 paso 3)
  const [ordenSeleccionada, setOrdenSeleccionada] = useState<FilaMatriz | null>(null);
  // Modal nuevo equipo (Bloque 2 paso 4)
  const [modalNuevoEquipoAbierto, setModalNuevoEquipoAbierto] = useState<boolean>(false);

  const hoy = useMemo(() => obtenerHoyMexico(), []);
  const fechaHoyFormateada = useMemo(() => formatearFechaHoyCompleta(hoy), [hoy]);

  // Cambiar línea en URL
  const cambiarLinea = (nuevaLinea: string) => {
    setSearchParams(
      (prev) => {
        const p = new URLSearchParams(prev);
        p.set('linea', nuevaLinea);
        return p;
      },
      { replace: true }
    );
  };

  // Cambiar vista en URL
  const cambiarVista = (nuevaVista: 'matriz' | 'fase') => {
    setSearchParams(
      (prev) => {
        const p = new URLSearchParams(prev);
        p.set('vista', nuevaVista);
        return p;
      },
      { replace: true }
    );
  };

  // Carga de datos
  const cargarMatriz = useCallback(
    async (silent: boolean = false) => {
      try {
        if (!silent) setCargando(true);
        else setRefrescando(true);
        setErrorCarga(null);

        const res = await fetchMatrizProduccion(lineaActiva, session?.access_token);
        setDatosMatriz(res);
      } catch (err: any) {
        console.error('[TableroProduccionPage] Error al cargar matriz:', err);
        setErrorCarga(err.message || 'Error al conectar con el servidor de producción');
        if (silent) {
          toast.error('No se pudo refrescar el tablero', { description: err.message });
        }
      } finally {
        setCargando(false);
        setRefrescando(false);
      }
    },
    [lineaActiva, session?.access_token]
  );

  // Carga al montar o cambiar línea
  useEffect(() => {
    cargarMatriz(false);
  }, [cargarMatriz]);

  // Refresco automático: cada 60s y al recuperar foco en ventana
  useEffect(() => {
    const handleFocus = () => {
      if (!document.hidden) {
        cargarMatriz(true);
      }
    };

    window.addEventListener('focus', handleFocus);

    const timer = setInterval(() => {
      if (!document.hidden) {
        cargarMatriz(true);
      }
    }, 60000);

    return () => {
      window.removeEventListener('focus', handleFocus);
      clearInterval(timer);
    };
  }, [cargarMatriz]);

  // Sembrar líneas si la base está limpia
  const handleSembrar = async () => {
    try {
      setCargando(true);
      await sembrarTableroProduccion(session?.access_token);
      toast.success('Tablero configurado con 4 líneas y 55 fases');
      await cargarMatriz(false);
    } catch (err: any) {
      toast.error('Error al sembrar líneas', { description: err.message });
      setCargando(false);
    }
  };

  // Actualización de celda de fase con optimismo y rollback
  const handleCambiarFase = async (
    ordenId: string,
    faseId: string,
    cambio: {
      estado: EstadoFase;
      fecha_propuesta?: string | null;
      fecha_fin?: string | null;
      nota?: string | null;
    }
  ) => {
    if (!datosMatriz) return;

    // 1. Aplicación optimista en memoria
    const { filasActualizadas, filaAnterior } = aplicarCambioOptimistaFase(
      datosMatriz.filas,
      ordenId,
      faseId,
      cambio,
      datosMatriz.fases,
      hoy
    );

    setDatosMatriz((prev) => (prev ? { ...prev, filas: filasActualizadas } : null));

    try {
      // 2. Llamada real al API
      const resp = await actualizarFaseOrden(
        ordenId,
        faseId,
        cambio,
        session?.access_token
      );

      // Si el servidor emitió avisos (e.g. subproceso tina), mostrarlos en toast warning
      if (resp.avisos && resp.avisos.length > 0) {
        for (const aviso of resp.avisos) {
          toast.warning(aviso, { duration: 6000 });
        }
      }
    } catch (err: any) {
      // 3. Rollback en caso de error
      console.error('[TableroProduccionPage] Error al actualizar fase:', err);
      if (filaAnterior) {
        setDatosMatriz((prev) => {
          if (!prev) return null;
          const revertidas = prev.filas.map((f) =>
            f.orden_id === ordenId ? filaAnterior : f
          );
          return { ...prev, filas: revertidas };
        });
      }
      toast.error('Error al actualizar fase', { description: err.message });
    }
  };

  // Guardar planeación (material faltante, compromiso, etc.)
  const handleGuardarPlaneacion = async (
    ordenId: string,
    cambios: {
      fecha_compromiso?: string | null;
      etiqueta?: string | null;
      material_faltante?: string | null;
    }
  ) => {
    if (!datosMatriz) return;

    // Optimista
    const filaPrevia = datosMatriz.filas.find((f) => f.orden_id === ordenId);
    setDatosMatriz((prev) => {
      if (!prev) return null;
      const actualizadas = prev.filas.map((f) =>
        f.orden_id === ordenId ? { ...f, ...cambios } : f
      );
      return { ...prev, filas: actualizadas };
    });

    try {
      await actualizarPlaneacionOrden(ordenId, cambios, session?.access_token);
    } catch (err: any) {
      // Rollback
      if (filaPrevia) {
        setDatosMatriz((prev) => {
          if (!prev) return null;
          const revertidas = prev.filas.map((f) =>
            f.orden_id === ordenId ? filaPrevia : f
          );
          return { ...prev, filas: revertidas };
        });
      }
      toast.error('Error al guardar planeación', { description: err.message });
    }
  };

  // Filas filtradas por chips y buscador de texto
  const filasFiltradas = useMemo(() => {
    if (!datosMatriz) return [];
    return filtrarFilasMatriz(datosMatriz.filas, filtroChip, busqueda);
  }, [datosMatriz, filtroChip, busqueda]);

  const resumen = datosMatriz?.resumen || {
    en_planta: 0,
    atrasados: 0,
    con_material: 0,
    con_pausa: 0,
    wip_por_fase: {},
  };

  // Callback al crear nuevo equipo en planta
  const handleEquipoCreado = async (orden: any) => {
    // Recargar datos actualizados
    await cargarMatriz(false);

    // Abrir de inmediato su panel de detalle para capturar notas o fechas
    setOrdenSeleccionada({
      orden_id: orden.id,
      etiqueta: orden.etiqueta || 'Nuevo equipo',
      cliente_nombre: orden.cliente?.nombre || orden.etiqueta || 'Inventario',
      cotizacion_folio: orden.cotizacion?.folio || null,
      modelo: orden.modelo,
      tipo_equipo: orden.tipo_equipo,
      origen: 'manual',
      fecha_compromiso: orden.fecha_compromiso,
      fecha_inicio: orden.fecha_inicio,
      material_faltante: orden.material_faltante,
      estado: orden.estado || 'Pendiente',
      estado_kanban: 'pendiente',
      semaforo: 'en_tiempo',
      avance: { terminadas: 0, total: 12 },
      tina: orden.tipo_equipo === '03' ? { terminadas: 0, total: 10 } : null,
      celdas: {},
    });
  };

  return (
    <div className="flex flex-col gap-4 p-4 md:p-6 min-h-[calc(100vh-80px)] max-w-full">
      {/* 1. CABECERA SUPERIOR */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-2 border-b border-border/60">
        <div>
          <div className="flex items-center gap-2">
            <h1 className="text-2xl font-bold tracking-tight text-foreground">
              Tablero de producción
            </h1>
            <Button
              type="button"
              variant="ghost"
              size="icon"
              className="h-8 w-8 text-muted-foreground hover:text-foreground"
              onClick={() => cargarMatriz(true)}
              disabled={refrescando || cargando}
              title="Refrescar tablero"
            >
              <RefreshCw
                className={cn('w-4 h-4', (refrescando || cargando) && 'animate-spin text-primary')}
              />
            </Button>
          </div>
          <p className="text-xs text-muted-foreground capitalize mt-0.5">
            {fechaHoyFormateada}
          </p>
        </div>

        {/* Buscador y Botón Nuevo Equipo */}
        <div className="flex items-center gap-2.5 flex-wrap">
          <div className="relative w-full sm:w-64">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              type="search"
              placeholder="Buscar cliente o folio..."
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="pl-8 h-9 text-xs"
            />
          </div>

          <Button
            type="button"
            variant="default"
            size="sm"
            onClick={() => setModalNuevoEquipoAbierto(true)}
            className="h-9 text-xs font-semibold bg-primary text-primary-foreground hover:bg-primary/90 shadow-xs"
          >
            <Plus className="w-4 h-4 mr-1.5" />
            Nuevo equipo en planta
          </Button>
        </div>
      </div>

      {/* 2. BARRA DE CONTROL: PESTAÑAS DE LÍNEA, SELECTOR DE VISTA Y CHIPS */}
      <div className="flex flex-col gap-3">
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 flex-wrap">
          {/* Pestañas de Línea */}
          <div className="flex items-center gap-1.5 p-1 bg-muted/50 rounded-lg border border-border/60 overflow-x-auto">
            {LINEAS_TABLERO.map((l) => (
              <button
                key={l.clave}
                type="button"
                onClick={() => cambiarLinea(l.clave)}
                className={cn(
                  'px-3 py-1.5 rounded-md text-xs font-medium transition-colors cursor-pointer shrink-0',
                  lineaActiva === l.clave
                    ? 'bg-card text-foreground shadow-xs font-semibold'
                    : 'text-muted-foreground hover:text-foreground hover:bg-card/50'
                )}
              >
                {l.nombre}
              </button>
            ))}
          </div>

          {/* Selector de vista: Matriz / Por fase */}
          <div className="flex items-center gap-1 p-1 bg-muted/50 rounded-lg border border-border/60">
            <button
              type="button"
              onClick={() => cambiarVista('matriz')}
              className={cn(
                'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-colors cursor-pointer',
                vistaActiva === 'matriz'
                  ? 'bg-card text-foreground shadow-xs font-semibold'
                  : 'text-muted-foreground hover:text-foreground'
              )}
            >
              <LayoutGrid className="w-3.5 h-3.5" />
              Matriz
            </button>

            <button
              type="button"
              onClick={() => cambiarVista('fase')}
              className={cn(
                'flex items-center gap-1.5 px-3 py-1.5 rounded-md text-xs font-medium transition-colors cursor-pointer',
                vistaActiva === 'fase'
                  ? 'bg-card text-foreground shadow-xs font-semibold'
                  : 'text-muted-foreground hover:text-foreground'
              )}
            >
              <Kanban className="w-3.5 h-3.5" />
              Por fase
            </button>
          </div>
        </div>

        {/* Chips de filtro */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            onClick={() => setFiltroChip('todos')}
            className={cn(
              'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors flex items-center gap-1.5 cursor-pointer',
              filtroChip === 'todos'
                ? 'bg-primary text-primary-foreground border-primary font-semibold'
                : 'bg-card text-muted-foreground hover:text-foreground border-border/60 hover:bg-muted'
            )}
          >
            Todos
            <Badge variant="secondary" className="px-1.5 py-0 text-[10px] h-4">
              {resumen.en_planta}
            </Badge>
          </button>

          <button
            type="button"
            onClick={() => setFiltroChip('atrasados')}
            className={cn(
              'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors flex items-center gap-1.5 cursor-pointer',
              filtroChip === 'atrasados'
                ? 'bg-destructive text-destructive-foreground border-destructive font-semibold'
                : resumen.atrasados > 0
                ? 'bg-destructive/10 text-destructive border-destructive/30 hover:bg-destructive/20'
                : 'bg-card text-muted-foreground hover:text-foreground border-border/60 hover:bg-muted'
            )}
          >
            <Clock className="w-3 h-3" />
            Atrasados
            <Badge
              variant="secondary"
              className={cn(
                'px-1.5 py-0 text-[10px] h-4',
                resumen.atrasados > 0 && 'bg-destructive/20 text-destructive'
              )}
            >
              {resumen.atrasados}
            </Badge>
          </button>

          <button
            type="button"
            onClick={() => setFiltroChip('con_material')}
            className={cn(
              'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors flex items-center gap-1.5 cursor-pointer',
              filtroChip === 'con_material'
                ? 'bg-destructive text-destructive-foreground border-destructive font-semibold'
                : resumen.con_material > 0
                ? 'bg-destructive/10 text-destructive border-destructive/30 hover:bg-destructive/20'
                : 'bg-card text-muted-foreground hover:text-foreground border-border/60 hover:bg-muted'
            )}
          >
            <PackageX className="w-3 h-3" />
            Con material
            <Badge
              variant="secondary"
              className={cn(
                'px-1.5 py-0 text-[10px] h-4',
                resumen.con_material > 0 && 'bg-destructive/20 text-destructive'
              )}
            >
              {resumen.con_material}
            </Badge>
          </button>

          <button
            type="button"
            onClick={() => setFiltroChip('con_pausa')}
            className={cn(
              'px-2.5 py-1 rounded-full text-xs font-medium border transition-colors flex items-center gap-1.5 cursor-pointer',
              filtroChip === 'con_pausa'
                ? 'bg-amber-500 text-white border-amber-500 font-semibold'
                : resumen.con_pausa > 0
                ? 'bg-amber-500/10 text-amber-700 dark:text-amber-300 border-amber-500/30 hover:bg-amber-500/20'
                : 'bg-card text-muted-foreground hover:text-foreground border-border/60 hover:bg-muted'
            )}
          >
            <PauseCircle className="w-3 h-3" />
            Con pausa
            <Badge
              variant="secondary"
              className={cn(
                'px-1.5 py-0 text-[10px] h-4',
                resumen.con_pausa > 0 && 'bg-amber-500/20 text-amber-700 dark:text-amber-300'
              )}
            >
              {resumen.con_pausa}
            </Badge>
          </button>
        </div>
      </div>

      {/* 3. CONTENIDO PRINCIPAL */}
      {cargando ? (
        <div className="flex flex-col items-center justify-center py-24 gap-3 bg-card/40 rounded-xl border border-border/50">
          <RefreshCw className="w-8 h-8 animate-spin text-primary" />
          <p className="text-sm text-muted-foreground">Cargando tablero de producción...</p>
        </div>
      ) : errorCarga ? (
        <div className="p-8 text-center bg-card rounded-xl border border-destructive/30 space-y-3">
          <AlertTriangle className="w-10 h-10 mx-auto text-destructive" />
          <h3 className="text-base font-semibold text-foreground">
            Error al consultar la línea de producción
          </h3>
          <p className="text-xs text-muted-foreground max-w-md mx-auto">{errorCarga}</p>
          <div className="pt-2 flex justify-center gap-2">
            <Button size="sm" variant="outline" onClick={() => cargarMatriz(false)}>
              Reintentar
            </Button>
            <Button size="sm" variant="default" onClick={handleSembrar}>
              <Database className="w-3.5 h-3.5 mr-1.5" />
              Preparar tablero
            </Button>
          </div>
        </div>
      ) : !datosMatriz || datosMatriz.fases.length === 0 ? (
        <div className="p-12 text-center bg-card rounded-xl border border-border space-y-4">
          <Database className="w-12 h-12 mx-auto text-muted-foreground" />
          <div>
            <h3 className="text-base font-bold text-foreground">Tablero no configurado</h3>
            <p className="text-xs text-muted-foreground mt-1 max-w-md mx-auto">
              No se encontraron líneas de producto ni fases sembradas en la organización.
            </p>
          </div>
          <Button size="sm" variant="default" onClick={handleSembrar}>
            <Database className="w-4 h-4 mr-1.5" />
            Preparar tablero (Sembrar catálogo)
          </Button>
        </div>
      ) : vistaActiva === 'fase' ? (
        <VistaPorFase
          filas={filasFiltradas}
          fases={datosMatriz.fases}
          hoy={hoy}
          onCambiarFase={handleCambiarFase}
          onSeleccionarOrden={(fila) => setOrdenSeleccionada(fila)}
        />
      ) : (
        <MatrizProduccionView
          lineaClave={lineaActiva}
          fases={datosMatriz.fases}
          filas={filasFiltradas}
          resumen={resumen}
          hoy={hoy}
          onCambiarFase={handleCambiarFase}
          onGuardarPlaneacion={handleGuardarPlaneacion}
          onSeleccionarOrden={(fila) => setOrdenSeleccionada(fila)}
        />
      )}

      {/* Panel lateral de detalle del equipo e historial */}
      <OrdenTrabajoDetalleSheet
        fila={ordenSeleccionada}
        open={!!ordenSeleccionada}
        onOpenChange={(abierto) => {
          if (!abierto) setOrdenSeleccionada(null);
        }}
        token={session?.access_token}
        onGuardarPlaneacion={handleGuardarPlaneacion}
      />

      {/* Modal para registrar nuevo equipo en planta */}
      <NuevoEquipoModal
        open={modalNuevoEquipoAbierto}
        onOpenChange={setModalNuevoEquipoAbierto}
        lineaDefecto={lineaActiva}
        token={session?.access_token}
        onEquipoCreado={handleEquipoCreado}
      />
    </div>
  );
}
