import React, { useState, useEffect, useCallback, useMemo } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../ui/tabs';
import { Button } from '../ui/button';
import { Calendar, Users, History, AlertCircle, Layers } from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import {
  inicioDeSemana,
  PlanTarea,
  OperarioRef,
  diasDeSemana,
} from '../../utils/planProduccion';
import { CuadriculaSemanal } from './CuadriculaSemanal';
import { FormularioTareaModal } from './FormularioTareaModal';
import { OperariosManager } from './OperariosManager';
import { TrazabilidadProduccion } from './TrazabilidadProduccion';
import { ImpresionPlanSemanal } from './ImpresionPlanSemanal';
import { EstructuraManager } from './EstructuraManager';

interface PlanSemanalMainProps {
  ordenesTrabajo?: any[];
  productos?: any[];
  session?: any;
}

export function PlanSemanalMain({
  ordenesTrabajo = [],
  productos = [],
  session,
}: PlanSemanalMainProps) {
  const [searchParams, setSearchParams] = useSearchParams();

  // Tab activo sincronizado con URL
  const tabUrl = searchParams.get('tab') || 'plan';
  const ordenIdUrl = searchParams.get('ordenId');

  const [activeTab, setActiveTab] = useState<'plan' | 'operarios' | 'trazabilidad' | 'estructura'>(
    tabUrl === 'operarios' || tabUrl === 'trazabilidad' || tabUrl === 'estructura' ? tabUrl : 'plan'
  );

  // Estados de Estructura (Áreas y Frentes)
  const [areas, setAreas] = useState<Array<{
    id: string;
    clave: string;
    nombre: string;
    frentes: Array<{ id: string; nombre: string; orden: number }>;
  }>>([]);
  const [areaSeleccionadaId, setAreaSeleccionadaId] = useState<string>('');
  const [cargandoEstructura, setCargandoEstructura] = useState(true);

  // Semana actual (iniciada al lunes de la semana en curso)
  const [lunesActual, setLunesActual] = useState<string>(() => inicioDeSemana(new Date()));
  const [mostrarSabado, setMostrarSabado] = useState(false);

  // Tareas de la semana
  const [tareas, setTareas] = useState<PlanTarea[]>([]);
  const [cargandoTareas, setCargandoTareas] = useState(false);

  // Catálogo de Operarios
  const [operarios, setOperarios] = useState<OperarioRef[]>([]);
  const [cargandoOperarios, setCargandoOperarios] = useState(false);

  // Estado del Modal de Tarea
  const [modalTareaAbierto, setModalTareaAbierto] = useState(false);
  const [tareaSeleccionada, setTareaSeleccionada] = useState<PlanTarea | null>(null);
  const [fechaInicialModal, setFechaInicialModal] = useState<string | undefined>();
  const [frenteIdInicialModal, setFrenteIdInicialModal] = useState<string | undefined>();

  // Materias primas del catálogo
  const materiasPrimas = useMemo(() => {
    return (productos || []).filter((p) => p.tipo_item === 'materia_prima' || p.tipo === 'bien');
  }, [productos]);

  // Sincronizar tab con URL
  const handleTabChange = (nuevoTab: string) => {
    const tabSeguro = nuevoTab as 'plan' | 'operarios' | 'trazabilidad' | 'estructura';
    setActiveTab(tabSeguro);
    const params = new URLSearchParams(searchParams);
    params.set('tab', tabSeguro);
    if (tabSeguro !== 'trazabilidad') {
      params.delete('ordenId');
    }
    setSearchParams(params);
  };

  // Obtener Token
  const getAuthToken = async () => {
    const { data: { session: currentSession } } = await supabase.auth.getSession();
    return currentSession?.access_token || session?.access_token;
  };

  // Cargar Estructura (Áreas y Frentes)
  const cargarEstructura = useCallback(async () => {
    try {
      setCargandoEstructura(true);
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/produccion/estructura`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al cargar estructura de producción');
      }

      const json = await res.json();
      const areasList = json.areas || [];
      setAreas(areasList);
      if (areasList.length > 0 && !areaSeleccionadaId) {
        setAreaSeleccionadaId(areasList[0].id);
      }
    } catch (err: any) {
      toast.error('Error al cargar áreas y frentes', { description: err.message });
    } finally {
      setCargandoEstructura(false);
    }
  }, [areaSeleccionadaId]);

  // Cargar Operarios
  const cargarOperarios = useCallback(async () => {
    try {
      setCargandoOperarios(true);
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/produccion/operarios`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al cargar operarios');
      }

      const json = await res.json();
      setOperarios(json.operarios || []);
    } catch (err: any) {
      toast.error('Error al cargar operarios', { description: err.message });
    } finally {
      setCargandoOperarios(false);
    }
  }, []);

  // Cargar Tareas de la Semana
  const cargarTareasSemana = useCallback(async () => {
    if (!lunesActual) return;

    try {
      setCargandoTareas(true);
      const token = await getAuthToken();
      const dias = diasDeSemana(lunesActual, { sabado: true });
      const desde = dias[0];
      const hasta = dias[dias.length - 1];

      const params = new URLSearchParams({ desde, hasta });
      if (areaSeleccionadaId) {
        params.append('area', areaSeleccionadaId);
      }

      const res = await fetch(`${BASE_URL}/produccion/plan?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al cargar tareas semanales');
      }

      const json = await res.json();
      setTareas(json.tareas || []);
    } catch (err: any) {
      toast.error('Error al cargar tareas', { description: err.message });
    } finally {
      setCargandoTareas(false);
    }
  }, [lunesActual, areaSeleccionadaId]);

  // Carga inicial
  useEffect(() => {
    cargarEstructura();
    cargarOperarios();
  }, [cargarEstructura, cargarOperarios]);

  useEffect(() => {
    if (areaSeleccionadaId) {
      cargarTareasSemana();
    }
  }, [areaSeleccionadaId, lunesActual, cargarTareasSemana]);

  // Acciones de Tarea
  const handleAbrirNuevaTarea = (dia?: string, frenteId?: string) => {
    setTareaSeleccionada(null);
    setFechaInicialModal(dia || lunesActual);
    setFrenteIdInicialModal(frenteId);
    setModalTareaAbierto(true);
  };

  const handleEditarTarea = (tarea: PlanTarea) => {
    setTareaSeleccionada(tarea);
    setModalTareaAbierto(true);
  };

  const handleGuardarTarea = async (payload: any, tareaId: string | null) => {
    const token = await getAuthToken();
    const url = tareaId ? `${BASE_URL}/produccion/tareas/${tareaId}` : `${BASE_URL}/produccion/tareas`;
    const method = tareaId ? 'PUT' : 'POST';

    const res = await fetch(url, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Error al guardar tarea');
    }

    await cargarTareasSemana();
  };

  const handleEliminarTarea = async (tareaId: string) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/produccion/tareas/${tareaId}?confirmado=1`, {
      method: 'DELETE',
      headers: { Authorization: `Bearer ${token}` },
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Error al eliminar tarea');
    }

    await cargarTareasSemana();
  };

  const handleCrearOperarioRapido = async (nombre: string, puesto?: string): Promise<OperarioRef | null> => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/produccion/operarios`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ nombre, puesto, activo: true }),
    });

    if (!res.ok) {
      const err = await res.json().catch(() => ({}));
      throw new Error(err.error || 'Error al crear operario');
    }

    const creado = await res.json();
    await cargarOperarios();
    return creado;
  };

  // Cambiar Estado de Tarea
  const handleCambiarEstado = async (
    tareaId: string,
    nuevoEstado: string,
    confirmarReapertura?: boolean
  ) => {
    try {
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/produccion/tareas/${tareaId}/estado`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          estado: nuevoEstado,
          confirmar_reapertura: !!confirmarReapertura,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al cambiar estado de la tarea');
      }

      toast.success(`Estado de tarea actualizado a: ${nuevoEstado}`);
      await cargarTareasSemana();
    } catch (err: any) {
      toast.error('Error al cambiar estado', { description: err.message });
      throw err;
    }
  };

  // Duplicar Semana
  const handleDuplicarSemana = async () => {
    const dDesde = new Date(lunesActual + 'T12:00:00Z');
    const dHasta = new Date(lunesActual + 'T12:00:00Z');
    dHasta.setDate(dHasta.getDate() + 7);
    const hastaStr = dHasta.toISOString().split('T')[0];

    const confirmar = confirm(
      `¿Deseas duplicar las tareas activas de la semana actual (${lunesActual}) a la semana siguiente (${hastaStr})?`
    );
    if (!confirmar) return;

    try {
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/produccion/plan/duplicar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          desde: lunesActual,
          hasta: hastaStr,
          area: areaSeleccionadaId,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al duplicar semana');
      }

      const json = await res.json();
      let msg = `Semana duplicada: ${json.creadas} tareas creadas, ${json.omitidas} omitidas`;
      if (json.operarios_omitidos > 0) {
        msg += ` (${json.operarios_omitidos} operarios inactivos no se copiaron)`;
      }
      toast.success(msg);
      if (json.errores && json.errores.length > 0) {
        toast.warning(`${json.errores.length} tareas tuvieron errores al duplicarse`);
      }
      // Avanzar a la semana siguiente para visualizarla
      setLunesActual(hastaStr);
    } catch (err: any) {
      toast.error('Error al duplicar semana', { description: err.message });
    }
  };

  const handleImprimir = () => {
    window.print();
  };

  const areaActiva = useMemo(() => {
    return areas.find((a) => a.id === areaSeleccionadaId) || areas[0];
  }, [areas, areaSeleccionadaId]);

  return (
    <div className="space-y-6">
      {/* Encabezado Principal */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 border-b border-border/50 pb-4 no-print">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">
            Plan Semanal de Producción
          </h1>
          <p className="text-xs text-muted-foreground mt-1">
            Gestión semanal por frentes, asignación de operarios, requerimiento de materiales y trazabilidad.
          </p>
        </div>

        {/* Pestañas de Navegación */}
        <Tabs value={activeTab} onValueChange={handleTabChange} className="w-auto">
          <TabsList className="bg-muted/50 border border-border/50">
            <TabsTrigger value="plan" className="text-xs gap-1.5 data-[state=active]:bg-card">
              <Calendar className="w-3.5 h-3.5" />
              Plan Semanal
            </TabsTrigger>
            <TabsTrigger value="operarios" className="text-xs gap-1.5 data-[state=active]:bg-card">
              <Users className="w-3.5 h-3.5" />
              Operarios
            </TabsTrigger>
            <TabsTrigger value="trazabilidad" className="text-xs gap-1.5 data-[state=active]:bg-card">
              <History className="w-3.5 h-3.5" />
              Trazabilidad
            </TabsTrigger>
            <TabsTrigger value="estructura" className="text-xs gap-1.5 data-[state=active]:bg-card">
              <Layers className="w-3.5 h-3.5" />
              Estructura
            </TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      {/* Contenido según Pestaña Activa */}
      <div className="no-print">
        {activeTab === 'plan' && (
          <CuadriculaSemanal
            areas={areas}
            areaSeleccionadaId={areaSeleccionadaId}
            onSeleccionarArea={setAreaSeleccionadaId}
            lunesActual={lunesActual}
            onCambiarLunes={setLunesActual}
            mostrarSabado={mostrarSabado}
            onToggleMostrarSabado={setMostrarSabado}
            tareas={tareas}
            cargando={cargandoTareas || cargandoEstructura}
            onNuevaTarea={handleAbrirNuevaTarea}
            onEditarTarea={handleEditarTarea}
            onCambiarEstado={handleCambiarEstado}
            onDuplicarSemana={handleDuplicarSemana}
            onImprimir={handleImprimir}
          />
        )}

        {activeTab === 'operarios' && (
          <OperariosManager
            operarios={operarios}
            tareasSemana={tareas}
            cargando={cargandoOperarios}
            onCrearOperario={async (payload) => {
              await handleCrearOperarioRapido(payload.nombre, payload.puesto);
            }}
            onActualizarOperario={async (id, payload) => {
              const token = await getAuthToken();
              const res = await fetch(`${BASE_URL}/produccion/operarios/${id}`, {
                method: 'PUT',
                headers: {
                  'Content-Type': 'application/json',
                  Authorization: `Bearer ${token}`,
                },
                body: JSON.stringify(payload),
              });
              if (!res.ok) {
                const err = await res.json().catch(() => ({}));
                throw new Error(err.error || 'Error al actualizar operario');
              }
              await cargarOperarios();
            }}
          />
        )}

        {activeTab === 'trazabilidad' && (
          <TrazabilidadProduccion
            ordenesTrabajo={ordenesTrabajo}
            operarios={operarios}
            ordenIdInicial={ordenIdUrl}
          />
        )}

        {activeTab === 'estructura' && (
          <EstructuraManager
            areas={areas}
            onRecargar={cargarEstructura}
            session={session}
          />
        )}
      </div>

      {/* Modal Formulario de Tarea */}
      <FormularioTareaModal
        open={modalTareaAbierto}
        onOpenChange={setModalTareaAbierto}
        tarea={tareaSeleccionada}
        fechaInicial={fechaInicialModal}
        frenteIdInicial={frenteIdInicialModal}
        areaIdInicial={areaSeleccionadaId}
        areas={areas}
        operariosDisponibles={operarios.filter((o) => o.activo !== false)}
        ordenesTrabajo={ordenesTrabajo}
        productosMateriaPrima={materiasPrimas}
        tareasSemana={tareas}
        onGuardar={handleGuardarTarea}
        onEliminar={handleEliminarTarea}
        onCambiarEstado={handleCambiarEstado}
        onCrearOperarioRapido={handleCrearOperarioRapido}
      />

      {/* Componente oculto visible solo al imprimir (window.print) */}
      {areaActiva && (
        <ImpresionPlanSemanal
          areaNombre={areaActiva.nombre}
          esReparaciones={areaActiva.clave === 'reparaciones' || areaActiva.nombre.toLowerCase().includes('reparaci')}
          lunes={lunesActual}
          mostrarSabado={mostrarSabado}
          frentes={areaActiva.frentes || []}
          tareas={tareas}
        />
      )}
    </div>
  );
}
