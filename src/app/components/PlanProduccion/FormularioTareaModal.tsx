import React, { useState, useEffect, useMemo } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Checkbox } from '../ui/checkbox';
import { Badge } from '../ui/badge';
import {
  AlertTriangle,
  Plus,
  Trash2,
  UserPlus,
  Clock,
  Check,
  X,
  Play,
  Pause,
  RotateCcw,
  CheckCircle2,
  XCircle,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  PlanTarea,
  EstadoPlanTarea,
  OperarioRef,
  puedeCambiarEstado,
} from '../../utils/planProduccion';

interface FormularioTareaModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  tarea: PlanTarea | null;
  fechaInicial?: string;
  frenteIdInicial?: string;
  areaIdInicial?: string;
  areas: Array<{
    id: string;
    clave: string;
    nombre: string;
    frentes: Array<{ id: string; nombre: string; orden: number }>;
  }>;
  operariosDisponibles: OperarioRef[];
  ordenesTrabajo: Array<{
    id: string;
    nomenclatura_id?: string;
    modelo?: string;
    cliente?: { nombre_razon_social?: string; nombre?: string };
    cotizacion?: { folio?: string };
  }>;
  productosMateriaPrima: Array<{
    id: string;
    nombre: string;
    unidad: string;
    costo?: number;
  }>;
  tareasSemana: PlanTarea[];
  onGuardar: (payload: any, tareaId: string | null) => Promise<void>;
  onEliminar?: (tareaId: string) => Promise<void>;
  onCambiarEstado?: (tareaId: string, nuevoEstado: EstadoPlanTarea, confirmarReapertura?: boolean) => Promise<void>;
  onCrearOperarioRapido?: (nombre: string, puesto?: string) => Promise<OperarioRef | null>;
}

const SUGERENCIAS_MOVILIDAD = ['Montacargas', 'Grúa', 'Camión', 'Patín', 'Plataforma', 'Camioneta'];

function getEstadoBadgeClass(estado: EstadoPlanTarea) {
  switch (estado) {
    case 'en_proceso':
      return 'bg-primary/10 text-primary border-primary/30';
    case 'pausada':
      return 'bg-amber-500/10 text-amber-600 border-amber-500/30';
    case 'terminada':
      return 'bg-emerald-500/10 text-emerald-600 border-emerald-500/30';
    case 'cancelada':
      return 'bg-destructive/10 text-destructive border-destructive/30';
    default:
      return 'bg-muted text-muted-foreground border-border/50';
  }
}

function calcularDuracionTexto(inicio?: string | null, fin?: string | null) {
  if (!inicio) return '--';
  const tInicio = new Date(inicio).getTime();
  const tFin = fin ? new Date(fin).getTime() : Date.now();
  const diffMs = Math.max(0, tFin - tInicio);
  const totalMin = Math.floor(diffMs / 60000);
  const horas = Math.floor(totalMin / 60);
  const mins = totalMin % 60;
  if (horas === 0) return `${mins}m`;
  return `${horas}h ${mins}m`;
}

export function FormularioTareaModal({
  open,
  onOpenChange,
  tarea,
  fechaInicial,
  frenteIdInicial,
  areaIdInicial,
  areas,
  operariosDisponibles,
  ordenesTrabajo,
  productosMateriaPrima,
  tareasSemana,
  onGuardar,
  onEliminar,
  onCambiarEstado,
  onCrearOperarioRapido,
}: FormularioTareaModalProps) {
  const [fecha, setFecha] = useState('');
  const [areaId, setAreaId] = useState('');
  const [frenteId, setFrenteId] = useState('');
  const [ordenTrabajoId, setOrdenTrabajoId] = useState<string>('ninguna');
  const [descripcion, setDescripcion] = useState('');
  const [movilidad, setMovilidad] = useState('');
  const [observaciones, setObservaciones] = useState('');
  const [materialFaltante, setMaterialFaltante] = useState(false);
  const [estadoActual, setEstadoActual] = useState<EstadoPlanTarea>('planeada');
  const [inicioReal, setInicioReal] = useState<string | null>(null);
  const [finReal, setFinReal] = useState<string | null>(null);
  const [cambiandoEstado, setCambiandoEstado] = useState(false);
  const [operariosSeleccionados, setOperariosSeleccionados] = useState<string[]>([]);
  const [materiales, setMateriales] = useState<Array<{
    producto_id?: string | null;
    descripcion: string;
    cantidad: number;
    unidad: string;
    notas?: string;
  }>>([]);

  const [guardando, setGuardando] = useState(false);
  const [eliminando, setEliminando] = useState(false);
  const [busquedaOperario, setBusquedaOperario] = useState('');
  const [busquedaProducto, setBusquedaProducto] = useState('');
  const [productoSeleccionadoId, setProductoSeleccionadoId] = useState<string>('');

  // Sub-modal alta rápida de operario
  const [modalNuevoOp, setModalNuevoOp] = useState(false);
  const [nuevoOpNombre, setNuevoOpNombre] = useState('');
  const [nuevoOpPuesto, setNuevoOpPuesto] = useState('');
  const [creandoOp, setCreandoOp] = useState(false);

  // Inicialización al abrir o cambiar de tarea
  useEffect(() => {
    if (!open) return;

    if (tarea) {
      setFecha(tarea.fecha ? tarea.fecha.split('T')[0] : '');
      setFrenteId(tarea.frente_id || '');
      // Encontrar área del frente
      let aId = '';
      for (const a of areas) {
        if ((a.frentes || []).some((f) => f.id === tarea.frente_id)) {
          aId = a.id;
          break;
        }
      }
      setAreaId(aId || areas[0]?.id || '');
      setOrdenTrabajoId(tarea.orden_trabajo_id || 'ninguna');
      setDescripcion(tarea.descripcion || '');
      setMovilidad(tarea.movilidad || '');
      setObservaciones(tarea.observaciones || '');
      setMaterialFaltante(Boolean(tarea.material_faltante));
      setEstadoActual(tarea.estado || 'planeada');
      setInicioReal(tarea.inicio_real || null);
      setFinReal(tarea.fin_real || null);

      const opIds = (tarea.operarios || [])
        .map((o: any) => (typeof o === 'string' ? o : o.id))
        .filter(Boolean);
      setOperariosSeleccionados(opIds);

      const mats = (tarea.materiales || []).map((m) => ({
        producto_id: m.producto_id || null,
        descripcion: m.descripcion || '',
        cantidad: Number(m.cantidad) || 1,
        unidad: m.unidad || 'PZA',
        notas: m.notas || '',
      }));
      setMateriales(mats);
    } else {
      setFecha(fechaInicial || new Date().toISOString().split('T')[0]);
      const aId = areaIdInicial || areas[0]?.id || '';
      setAreaId(aId);
      const frentesArea = areas.find((a) => a.id === aId)?.frentes || [];
      setFrenteId(frenteIdInicial || frentesArea[0]?.id || '');
      setOrdenTrabajoId('ninguna');
      setDescripcion('');
      setMovilidad('');
      setObservaciones('');
      setMaterialFaltante(false);
      setEstadoActual('planeada');
      setInicioReal(null);
      setFinReal(null);
      setOperariosSeleccionados([]);
      setMateriales([]);
    }
    setBusquedaOperario('');
    setBusquedaProducto('');
    setProductoSeleccionadoId('');
  }, [open, tarea, fechaInicial, frenteIdInicial, areaIdInicial, areas]);

  // Frentes correspondientes al área seleccionada
  const frentesDisponibles = useMemo(() => {
    const areaSel = areas.find((a) => a.id === areaId);
    return areaSel?.frentes || [];
  }, [areas, areaId]);

  // Si cambia el área, ajustar frente si el actual no pertenece a esa área
  const handleAreaChange = (nuevaAreaId: string) => {
    setAreaId(nuevaAreaId);
    const areaSel = areas.find((a) => a.id === nuevaAreaId);
    const frentes = areaSel?.frentes || [];
    if (!frentes.some((f) => f.id === frenteId)) {
      setFrenteId(frentes[0]?.id || '');
    }
  };

  const esReparaciones = useMemo(() => {
    const areaSel = areas.find((a) => a.id === areaId);
    return areaSel?.clave === 'reparaciones' || areaSel?.nombre.toLowerCase().includes('reparaci');
  }, [areas, areaId]);

  // Conflictos de operarios en la misma fecha
  const conflictosDetectados = useMemo(() => {
    if (!fecha || operariosSeleccionados.length === 0) return [];
    const conflictos: Array<{ operarioId: string; nombre: string; tareaId: string }> = [];

    for (const t of tareasSemana) {
      if (t.id === tarea?.id) continue; // Ignorar la tarea actual que se está editando
      if (t.fecha?.split('T')[0] !== fecha) continue;
      if (t.estado === 'cancelada') continue;

      const opsEnTarea = (t.operarios || [])
        .map((o: any) => (typeof o === 'string' ? o : o.id))
        .filter(Boolean);

      for (const opId of operariosSeleccionados) {
        if (opsEnTarea.includes(opId)) {
          const opObj = operariosDisponibles.find((o) => o.id === opId);
          conflictos.push({
            operarioId: opId,
            nombre: opObj?.nombre || 'Operario',
            tareaId: t.id,
          });
        }
      }
    }
    return conflictos;
  }, [fecha, operariosSeleccionados, tareasSemana, tarea, operariosDisponibles]);

  // Manejo de operarios
  const toggleOperario = (opId: string) => {
    setOperariosSeleccionados((prev) =>
      prev.includes(opId) ? prev.filter((id) => id !== opId) : [...prev, opId]
    );
  };

  // Agregar material
  const handleAgregarMaterial = () => {
    if (!productoSeleccionadoId) {
      toast.error('Selecciona un material o escribe su descripción');
      return;
    }
    if (productoSeleccionadoId === 'libre') {
      const desc = busquedaProducto.trim();
      if (!desc) {
        toast.error('Escribe la descripción del material');
        return;
      }
      setMateriales((prev) => [
        ...prev,
        {
          producto_id: null,
          descripcion: desc,
          cantidad: 1,
          unidad: 'PZA',
        },
      ]);
      setBusquedaProducto('');
      setProductoSeleccionadoId('');
      return;
    }

    const prod = productosMateriaPrima.find((p) => p.id === productoSeleccionadoId);
    if (!prod) return;

    setMateriales((prev) => [
      ...prev,
      {
        producto_id: prod.id,
        descripcion: prod.nombre,
        cantidad: 1,
        unidad: prod.unidad || 'PZA',
      },
    ]);
    setBusquedaProducto('');
    setProductoSeleccionadoId('');
  };

  const handleEliminarMaterial = (index: number) => {
    setMateriales((prev) => prev.filter((_, i) => i !== index));
  };

  const handleActualizarMaterial = (index: number, campo: string, valor: any) => {
    setMateriales((prev) => {
      const copia = [...prev];
      copia[index] = { ...copia[index], [campo]: valor };
      return copia;
    });
  };

  // Crear operario rápido
  const handleGuardarNuevoOperario = async () => {
    if (!nuevoOpNombre.trim()) {
      toast.error('El nombre del operario es obligatorio');
      return;
    }
    if (!onCrearOperarioRapido) return;

    try {
      setCreandoOp(true);
      const creado = await onCrearOperarioRapido(nuevoOpNombre.trim(), nuevoOpPuesto.trim() || undefined);
      if (creado) {
        toast.success(`Operario "${creado.nombre}" dado de alta`);
        setOperariosSeleccionados((prev) => [...prev, creado.id]);
        setModalNuevoOp(false);
        setNuevoOpNombre('');
        setNuevoOpPuesto('');
      }
    } catch (err: any) {
      toast.error('Error al registrar operario', { description: err.message });
    } finally {
      setCreandoOp(false);
    }
  };

  // Guardar tarea
  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!fecha) {
      toast.error('La fecha es obligatoria');
      return;
    }
    if (!frenteId) {
      toast.error('El frente de trabajo es obligatorio');
      return;
    }
    if (esReparaciones && !descripcion.trim()) {
      toast.error('La descripción de la labor es obligatoria en Reparaciones');
      return;
    }

    for (const m of materiales) {
      if (!m.descripcion.trim()) {
        toast.error('Todos los materiales deben tener una descripción');
        return;
      }
      if (!m.cantidad || m.cantidad <= 0) {
        toast.error(`La cantidad de "${m.descripcion}" debe ser mayor a 0`);
        return;
      }
    }

    try {
      setGuardando(true);
      const payload = {
        fecha,
        frente_id: frenteId,
        orden_trabajo_id: ordenTrabajoId === 'ninguna' ? null : ordenTrabajoId,
        descripcion: descripcion.trim() || null,
        movilidad: movilidad.trim() || null,
        observaciones: observaciones.trim() || null,
        material_faltante: materialFaltante,
        operarios: operariosSeleccionados,
        materiales: materiales.map((m) => ({
          producto_id: m.producto_id || null,
          descripcion: m.descripcion.trim(),
          cantidad: Number(m.cantidad),
          unidad: m.unidad.trim() || 'PZA',
          notas: m.notas || null,
        })),
      };

      await onGuardar(payload, tarea ? tarea.id : null);
      toast.success(tarea ? 'Tarea actualizada con éxito' : 'Tarea creada con éxito');
      onOpenChange(false);
    } catch (err: any) {
      toast.error('Error al guardar tarea', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  const handleEjecutarCambioEstado = async (nuevoEstado: EstadoPlanTarea, requiereConfirmacion?: boolean) => {
    if (!tarea || !onCambiarEstado) return;
    if (requiereConfirmacion) {
      const ok = confirm(`Reabrir una tarea terminada reiniciará su seguimiento a "en proceso". ¿Deseas continuar?`);
      if (!ok) return;
    }
    try {
      setCambiandoEstado(true);
      await onCambiarEstado(tarea.id, nuevoEstado, requiereConfirmacion);
      setEstadoActual(nuevoEstado);
      if (nuevoEstado === 'en_proceso' && !inicioReal) {
        setInicioReal(new Date().toISOString());
      }
      if (nuevoEstado === 'terminada') {
        setFinReal(new Date().toISOString());
      }
    } catch (err: any) {
      // Notificado en el llamador
    } finally {
      setCambiandoEstado(false);
    }
  };

  const accionesEstadoDisponibles = useMemo(() => {
    if (!tarea) return [];
    const candidatos: Array<{
      nuevoEstado: EstadoPlanTarea;
      etiqueta: string;
      variante: 'default' | 'outline' | 'destructive' | 'secondary';
      icono: React.ReactNode;
      requiereConfirmacion?: boolean;
    }> = [];

    const todos: EstadoPlanTarea[] = ['planeada', 'en_proceso', 'pausada', 'terminada', 'cancelada'];
    for (const st of todos) {
      if (st === estadoActual) continue;
      const res = puedeCambiarEstado(estadoActual, st, { confirmarReapertura: true });
      if (res.valido) {
        let etiqueta = st.replace('_', ' ');
        let variante: 'default' | 'outline' | 'destructive' | 'secondary' = 'outline';
        let icono: React.ReactNode = null;
        let requiereConfirmacion = false;

        if (st === 'en_proceso') {
          if (estadoActual === 'planeada') {
            etiqueta = 'Iniciar labor';
            variante = 'default';
            icono = <Play className="w-3.5 h-3.5 mr-1" />;
          } else if (estadoActual === 'pausada') {
            etiqueta = 'Reanudar labor';
            variante = 'default';
            icono = <Play className="w-3.5 h-3.5 mr-1" />;
          } else if (estadoActual === 'terminada') {
            etiqueta = 'Reabrir labor';
            variante = 'secondary';
            icono = <RotateCcw className="w-3.5 h-3.5 mr-1" />;
            requiereConfirmacion = true;
          }
        } else if (st === 'pausada') {
          etiqueta = 'Pausar labor';
          variante = 'outline';
          icono = <Pause className="w-3.5 h-3.5 mr-1 text-amber-500" />;
        } else if (st === 'terminada') {
          etiqueta = 'Terminar labor';
          variante = 'default';
          icono = <CheckCircle2 className="w-3.5 h-3.5 mr-1 text-emerald-500" />;
        } else if (st === 'cancelada') {
          etiqueta = 'Cancelar labor';
          variante = 'destructive';
          icono = <XCircle className="w-3.5 h-3.5 mr-1" />;
        }

        candidatos.push({
          nuevoEstado: st,
          etiqueta,
          variante,
          icono,
          requiereConfirmacion,
        });
      }
    }
    return candidatos;
  }, [tarea, estadoActual]);

  const handleEliminarClick = async () => {
    if (!tarea || !onEliminar) return;
    if (!confirm('¿Estás seguro de que deseas eliminar esta tarea del plan? La trazabilidad guardará constancia de la eliminación.')) {
      return;
    }
    try {
      setEliminando(true);
      await onEliminar(tarea.id);
      toast.success('Tarea eliminada del plan');
      onOpenChange(false);
    } catch (err: any) {
      toast.error('Error al eliminar tarea', { description: err.message });
    } finally {
      setEliminando(false);
    }
  };

  const operariosFiltrados = useMemo(() => {
    const q = busquedaOperario.toLowerCase().trim();
    if (!q) return operariosDisponibles;
    return operariosDisponibles.filter(
      (o) =>
        o.nombre?.toLowerCase().includes(q) ||
        o.puesto?.toLowerCase().includes(q)
    );
  }, [operariosDisponibles, busquedaOperario]);

  const productosFiltrados = useMemo(() => {
    const q = busquedaProducto.toLowerCase().trim();
    if (!q) return productosMateriaPrima.slice(0, 30);
    return productosMateriaPrima
      .filter((p) => p.nombre.toLowerCase().includes(q))
      .slice(0, 30);
  }, [productosMateriaPrima, busquedaProducto]);

  return (
    <>
      <Dialog open={open} onOpenChange={onOpenChange}>
        <DialogContent className="max-w-3xl max-h-[90vh] overflow-y-auto bg-card border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-xl font-bold flex items-center justify-between">
              <span>{tarea ? 'Editar Tarea de Producción' : 'Nueva Tarea de Producción'}</span>
              {tarea && (
                <Badge variant="outline" className="text-xs uppercase">
                  {tarea.estado}
                </Badge>
              )}
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              Define los operarios, frente de trabajo, orden del remolque y materiales requeridos.
            </DialogDescription>
          </DialogHeader>

          {/* Aviso de Conflicto en Operarios */}
          {conflictosDetectados.length > 0 && (
            <div className="bg-accent-yellow/15 border border-accent-yellow/30 text-accent-yellow rounded-lg p-3 text-xs flex items-start gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0 mt-0.5" />
              <div>
                <p className="font-bold">Aviso de duplicidad de operario en el mismo día:</p>
                <ul className="list-disc list-inside mt-1 space-y-0.5">
                  {conflictosDetectados.map((c, i) => (
                    <li key={i}>
                      <span className="font-semibold">{c.nombre}</span> ya cuenta con otra tarea asignada para la fecha {fecha}.
                    </li>
                  ))}
                </ul>
                <p className="mt-1 text-[11px] text-muted-foreground">
                  Puedes continuar guardando; este aviso no bloquea la planeación.
                </p>
              </div>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-4 text-xs">
            {/* Fila 1: Fecha, Área, Frente */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div>
                <Label className="text-xs font-semibold">Fecha de Ejecución *</Label>
                <Input
                  type="date"
                  value={fecha}
                  onChange={(e) => setFecha(e.target.value)}
                  className="bg-background mt-1 text-xs"
                  required
                />
              </div>

              <div>
                <Label className="text-xs font-semibold">Área *</Label>
                <Select value={areaId} onValueChange={handleAreaChange}>
                  <SelectTrigger className="bg-background mt-1 text-xs">
                    <SelectValue placeholder="Seleccionar área" />
                  </SelectTrigger>
                  <SelectContent>
                    {areas.map((a) => (
                      <SelectItem key={a.id} value={a.id} className="text-xs">
                        {a.nombre}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div>
                <Label className="text-xs font-semibold">Frente de Trabajo *</Label>
                <Select value={frenteId} onValueChange={setFrenteId}>
                  <SelectTrigger className="bg-background mt-1 text-xs">
                    <SelectValue placeholder="Seleccionar frente" />
                  </SelectTrigger>
                  <SelectContent>
                    {frentesDisponibles.map((f) => (
                      <SelectItem key={f.id} value={f.id} className="text-xs">
                        {f.nombre}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Fila 2: Orden de Trabajo (opcional) y Estado */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-3">
              <div className="md:col-span-2">
                <Label className="text-xs font-semibold">Orden de Trabajo (Remolque)</Label>
                <Select value={ordenTrabajoId} onValueChange={setOrdenTrabajoId}>
                  <SelectTrigger className="bg-background mt-1 text-xs">
                    <SelectValue placeholder="Sin orden vinculada (tarea general)" />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="ninguna" className="text-xs italic text-muted-foreground">
                      -- Sin orden de trabajo (labor general) --
                    </SelectItem>
                    {ordenesTrabajo.map((ot) => {
                      const clienteNom = ot.cliente?.nombre_razon_social || ot.cliente?.nombre || 'Cliente';
                      const folio = ot.nomenclatura_id || ot.cotizacion?.folio || ot.modelo || 'OT';
                      return (
                        <SelectItem key={ot.id} value={ot.id} className="text-xs">
                          {folio} — {clienteNom} {ot.modelo ? `(${ot.modelo})` : ''}
                        </SelectItem>
                      );
                    })}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1">
                <Label className="text-xs font-semibold">Estado de la Tarea</Label>
                <div className="mt-1 flex items-center gap-2">
                  <Badge
                    variant="outline"
                    className={`text-xs px-2.5 py-1 font-semibold capitalize border ${getEstadoBadgeClass(estadoActual)}`}
                  >
                    {estadoActual.replace('_', ' ')}
                  </Badge>
                  {!tarea && (
                    <span className="text-[11px] text-muted-foreground italic">
                      (Toda tarea inicia como &quot;planeada&quot;)
                    </span>
                  )}
                </div>
              </div>
            </div>

            {/* Panel de Control de Estados y Tiempos Reales (solo al editar tarea existente) */}
            {tarea && (
              <div className="bg-muted/30 border border-border/70 rounded-xl p-3.5 space-y-3">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div>
                    <span className="text-xs font-bold text-foreground">Acciones de Estado</span>
                    <p className="text-[11px] text-muted-foreground">
                      Cambios auditados con registro de inicio y fin real.
                    </p>
                  </div>
                  <div className="flex flex-wrap items-center gap-1.5">
                    {accionesEstadoDisponibles.length === 0 ? (
                      <span className="text-xs text-muted-foreground italic">
                        {estadoActual === 'cancelada' ? 'Tarea cancelada (sin transiciones)' : 'Sin acciones disponibles'}
                      </span>
                    ) : (
                      accionesEstadoDisponibles.map((accion) => (
                        <Button
                          key={accion.nuevoEstado}
                          type="button"
                          size="sm"
                          variant={accion.variante as any}
                          disabled={cambiandoEstado}
                          onClick={() => handleEjecutarCambioEstado(accion.nuevoEstado, accion.requiereConfirmacion)}
                          className="text-xs h-7"
                        >
                          {accion.icono}
                          <span>{accion.etiqueta}</span>
                        </Button>
                      ))
                    )}
                  </div>
                </div>

                {/* Tiempos Reales y Duración */}
                {(inicioReal || finReal) && (
                  <div className="pt-2 border-t border-border/40 grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                    <div>
                      <span className="text-muted-foreground text-[10px] block">Inicio Real:</span>
                      <span className="font-mono font-medium text-foreground">
                        {inicioReal ? new Date(inicioReal).toLocaleString('es-MX', { dateStyle: 'short', timeStyle: 'short' }) : 'No iniciado'}
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground text-[10px] block">Fin Real:</span>
                      <span className="font-mono font-medium text-foreground">
                        {finReal ? new Date(finReal).toLocaleString('es-MX', { dateStyle: 'short', timeStyle: 'short' }) : (inicioReal ? 'En curso' : 'Pendiente')}
                      </span>
                    </div>
                    <div>
                      <span className="text-muted-foreground text-[10px] block">Duración:</span>
                      <span className="font-mono font-semibold text-primary">
                        {calcularDuracionTexto(inicioReal, finReal)}
                      </span>
                    </div>
                  </div>
                )}
              </div>
            )}

            {/* Fila 3: Descripción / Labor */}
            <div>
              <div className="flex justify-between items-center">
                <Label className="text-xs font-semibold">
                  Labor / Descripción de la Tarea {esReparaciones ? '*' : '(Opcional)'}
                </Label>
                {esReparaciones && (
                  <span className="text-[11px] text-accent-red">Obligatorio en Reparaciones</span>
                )}
              </div>
              <Input
                value={descripcion}
                onChange={(e) => setDescripcion(e.target.value)}
                placeholder="Ej. Armado de perchas, corte de solera, soldadura de bordas..."
                className="bg-background mt-1 text-xs"
                required={esReparaciones}
              />
            </div>

            {/* Fila 4: Operarios Asignados (Multi-selección con buscador y alta rápida) */}
            <div className="border border-border/60 rounded-lg p-3 bg-muted/20">
              <div className="flex justify-between items-center mb-2">
                <Label className="text-xs font-semibold">
                  Operarios Asignados ({operariosSeleccionados.length})
                </Label>
                {onCrearOperarioRapido && (
                  <Button
                    type="button"
                    variant="ghost"
                    size="sm"
                    onClick={() => setModalNuevoOp(true)}
                    className="h-7 text-xs text-primary gap-1"
                  >
                    <UserPlus className="w-3.5 h-3.5" />
                    + Alta rápida
                  </Button>
                )}
              </div>

              {/* Chips de seleccionados */}
              <div className="flex flex-wrap gap-1.5 mb-2">
                {operariosSeleccionados.map((opId) => {
                  const op = operariosDisponibles.find((o) => o.id === opId);
                  return (
                    <Badge
                      key={opId}
                      variant="secondary"
                      className="text-xs bg-primary/10 text-primary border border-primary/20 flex items-center gap-1 pl-2 pr-1 py-0.5"
                    >
                      <span>{op?.nombre || 'Operario'}</span>
                      <button
                        type="button"
                        onClick={() => toggleOperario(opId)}
                        className="hover:bg-primary/20 rounded p-0.5"
                      >
                        <X className="w-3 h-3" />
                      </button>
                    </Badge>
                  );
                })}
                {operariosSeleccionados.length === 0 && (
                  <span className="text-xs text-muted-foreground italic">
                    Sin operarios seleccionados
                  </span>
                )}
              </div>

              {/* Buscador de operarios */}
              <Input
                value={busquedaOperario}
                onChange={(e) => setBusquedaOperario(e.target.value)}
                placeholder="Buscar operario por nombre o puesto..."
                className="bg-background text-xs h-8 mb-2"
              />

              {/* Lista compacta con checkboxes */}
              <div className="max-h-28 overflow-y-auto grid grid-cols-2 md:grid-cols-3 gap-1.5 border border-border/40 rounded p-1.5 bg-background">
                {operariosFiltrados.map((op) => {
                  const seleccionado = operariosSeleccionados.includes(op.id);
                  return (
                    <button
                      key={op.id}
                      type="button"
                      onClick={() => toggleOperario(op.id)}
                      className={`flex items-center gap-2 p-1.5 rounded text-left transition-colors text-xs ${
                        seleccionado
                          ? 'bg-primary/15 font-semibold text-primary'
                          : 'hover:bg-muted text-foreground'
                      }`}
                    >
                      <div
                        className={`w-3.5 h-3.5 rounded border flex items-center justify-center shrink-0 ${
                          seleccionado
                            ? 'bg-primary border-primary text-primary-foreground'
                            : 'border-border'
                        }`}
                      >
                        {seleccionado && <Check className="w-2.5 h-2.5" />}
                      </div>
                      <span className="truncate">{op.nombre}</span>
                      {op.puesto && (
                        <span className="text-[10px] text-muted-foreground truncate">
                          ({op.puesto})
                        </span>
                      )}
                    </button>
                  );
                })}
                {operariosFiltrados.length === 0 && (
                  <div className="col-span-3 text-center text-xs text-muted-foreground py-2">
                    No se encontraron operarios
                  </div>
                )}
              </div>
            </div>

            {/* Fila 5: Movilidad con sugerencias rápidas */}
            <div>
              <Label className="text-xs font-semibold">Movilidad (Vehículo o equipo de apoyo)</Label>
              <div className="flex gap-1 flex-wrap mt-1 mb-1.5">
                {SUGERENCIAS_MOVILIDAD.map((sug) => (
                  <button
                    key={sug}
                    type="button"
                    onClick={() => setMovilidad(sug)}
                    className={`text-[11px] px-2 py-0.5 rounded border transition-colors ${
                      movilidad === sug
                        ? 'bg-primary text-primary-foreground border-primary'
                        : 'bg-muted/50 hover:bg-muted text-muted-foreground border-border/50'
                    }`}
                  >
                    {sug}
                  </button>
                ))}
              </div>
              <Input
                value={movilidad}
                onChange={(e) => setMovilidad(e.target.value)}
                placeholder="Ej. Montacargas 1, Grúa viajera, Camión de volteo..."
                className="bg-background text-xs"
              />
            </div>

            {/* Fila 6: Materiales Requeridos */}
            <div className="border border-border/60 rounded-lg p-3 bg-muted/20">
              <Label className="text-xs font-semibold mb-2 block">
                Materiales Requeridos ({materiales.length})
              </Label>

              {/* Selector de material a agregar */}
              <div className="grid grid-cols-1 md:grid-cols-4 gap-2 mb-2">
                <div className="md:col-span-3">
                  <Input
                    value={busquedaProducto}
                    onChange={(e) => {
                      setBusquedaProducto(e.target.value);
                      if (e.target.value) setProductoSeleccionadoId('libre');
                    }}
                    placeholder="Buscar materia prima del catálogo o escribir texto libre..."
                    className="bg-background text-xs h-8"
                  />
                  {busquedaProducto && productosFiltrados.length > 0 && (
                    <div className="max-h-32 overflow-y-auto border border-border rounded mt-1 bg-card shadow-lg p-1 space-y-0.5 z-10 relative">
                      <div
                        onClick={() => {
                          setProductoSeleccionadoId('libre');
                        }}
                        className="p-1 hover:bg-muted rounded cursor-pointer text-xs font-medium text-primary flex items-center justify-between"
                      >
                        <span>Usar como material libre: "{busquedaProducto}"</span>
                        <span className="text-[10px] text-muted-foreground">(Sin ID)</span>
                      </div>
                      {productosFiltrados.map((p) => (
                        <div
                          key={p.id}
                          onClick={() => {
                            setProductoSeleccionadoId(p.id);
                            setBusquedaProducto(p.nombre);
                          }}
                          className={`p-1 hover:bg-muted rounded cursor-pointer text-xs flex items-center justify-between ${
                            productoSeleccionadoId === p.id ? 'bg-primary/10 font-bold' : ''
                          }`}
                        >
                          <span className="truncate">{p.nombre}</span>
                          <span className="text-[10px] text-muted-foreground shrink-0 ml-2">
                            {p.unidad}
                          </span>
                        </div>
                      ))}
                    </div>
                  )}
                </div>

                <Button
                  type="button"
                  variant="secondary"
                  size="sm"
                  onClick={handleAgregarMaterial}
                  className="h-8 text-xs gap-1"
                >
                  <Plus className="w-3.5 h-3.5" />
                  Agregar
                </Button>
              </div>

              {/* Lista de materiales añadidos */}
              {materiales.length > 0 ? (
                <div className="space-y-1.5 max-h-36 overflow-y-auto">
                  {materiales.map((m, idx) => (
                    <div
                      key={idx}
                      className="flex items-center gap-2 bg-background p-1.5 rounded border border-border/50 text-xs"
                    >
                      <div className="flex-1 font-medium truncate" title={m.descripcion}>
                        {m.descripcion}
                        {m.producto_id && (
                          <span className="text-[10px] text-primary/70 ml-1.5 font-mono">
                            [Catálogo]
                          </span>
                        )}
                      </div>
                      <div className="w-20">
                        <Input
                          type="number"
                          step="0.01"
                          min="0.01"
                          value={m.cantidad}
                          onChange={(e) =>
                            handleActualizarMaterial(idx, 'cantidad', parseFloat(e.target.value) || 0)
                          }
                          className="h-7 text-xs text-right bg-background"
                        />
                      </div>
                      <div className="w-16">
                        <Input
                          type="text"
                          value={m.unidad}
                          onChange={(e) =>
                            handleActualizarMaterial(idx, 'unidad', e.target.value.toUpperCase())
                          }
                          className="h-7 text-xs bg-background uppercase font-mono"
                        />
                      </div>
                      <Button
                        type="button"
                        variant="ghost"
                        size="icon"
                        onClick={() => handleEliminarMaterial(idx)}
                        className="h-7 w-7 text-muted-foreground hover:text-accent-red"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </Button>
                    </div>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-muted-foreground italic text-center py-2">
                  No se han registrado materiales requeridos para esta tarea
                </p>
              )}
            </div>

            {/* Fila 7: Observaciones y Checkbox Falta Material */}
            <div>
              <Label className="text-xs font-semibold">Observaciones</Label>
              <Textarea
                value={observaciones}
                onChange={(e) => setObservaciones(e.target.value)}
                placeholder="Comentarios adicionales, notas de seguimiento, avances..."
                className="bg-background mt-1 text-xs h-16 resize-none"
              />
            </div>

            <div className="flex items-center justify-between border-t border-border/50 pt-3">
              <div className="flex items-center space-x-2">
                <Checkbox
                  id="chk-material-faltante"
                  checked={materialFaltante}
                  onCheckedChange={(checked) => setMaterialFaltante(Boolean(checked))}
                />
                <label
                  htmlFor="chk-material-faltante"
                  className="text-xs font-medium leading-none cursor-pointer flex items-center gap-1.5"
                >
                  <AlertTriangle className="w-3.5 h-3.5 text-accent-yellow" />
                  <span>Reportar Material Faltante (Alerta visual en cuadrícula)</span>
                </label>
              </div>

              {/* Tiempos reales si existen */}
              {tarea && (tarea.inicio_real || tarea.fin_real) && (
                <div className="text-[11px] text-muted-foreground flex items-center gap-3">
                  {tarea.inicio_real && (
                    <span className="flex items-center gap-1">
                      <Clock className="w-3 h-3" /> Inicio: {new Date(tarea.inicio_real).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  )}
                  {tarea.fin_real && (
                    <span className="flex items-center gap-1">
                      <Check className="w-3 h-3 text-accent-green" /> Fin: {new Date(tarea.fin_real).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </span>
                  )}
                </div>
              )}
            </div>

            <DialogFooter className="flex items-center justify-between gap-2 pt-2">
              <div>
                {tarea && onEliminar && (
                  <Button
                    type="button"
                    variant="ghost"
                    onClick={handleEliminarClick}
                    disabled={guardando || eliminando}
                    className="text-accent-red hover:bg-accent-red/10 text-xs h-8"
                  >
                    <Trash2 className="w-3.5 h-3.5 mr-1" />
                    Eliminar Tarea
                  </Button>
                )}
              </div>
              <div className="flex gap-2">
                <Button
                  type="button"
                  variant="outline"
                  onClick={() => onOpenChange(false)}
                  disabled={guardando || eliminando}
                  className="text-xs h-8"
                >
                  Cancelar
                </Button>
                <Button
                  type="submit"
                  disabled={guardando || eliminando}
                  className="text-xs h-8 bg-primary text-primary-foreground font-semibold"
                >
                  {guardando ? 'Guardando...' : tarea ? 'Actualizar Tarea' : 'Crear Tarea'}
                </Button>
              </div>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>

      {/* Sub-diálogo para dar de alta un operario rápidamente */}
      <Dialog open={modalNuevoOp} onOpenChange={setModalNuevoOp}>
        <DialogContent className="max-w-md bg-card border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-base font-bold flex items-center gap-2">
              <UserPlus className="w-4 h-4 text-primary" />
              Alta Rápida de Operario
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              Registra un nuevo operario de taller sin salir de la tarea.
            </DialogDescription>
          </DialogHeader>
          <div className="space-y-3 py-2 text-xs">
            <div>
              <Label className="text-xs font-semibold">Nombre Completo *</Label>
              <Input
                value={nuevoOpNombre}
                onChange={(e) => setNuevoOpNombre(e.target.value)}
                placeholder="Ej. Juan Manuel Ramos"
                className="bg-background mt-1 text-xs"
                autoFocus
              />
            </div>
            <div>
              <Label className="text-xs font-semibold">Puesto o Especialidad</Label>
              <Input
                value={nuevoOpPuesto}
                onChange={(e) => setNuevoOpPuesto(e.target.value)}
                placeholder="Ej. Soldador / Armador / Pintor"
                className="bg-background mt-1 text-xs"
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => setModalNuevoOp(false)}
              disabled={creandoOp}
              className="text-xs h-8"
            >
              Cancelar
            </Button>
            <Button
              type="button"
              size="sm"
              onClick={handleGuardarNuevoOperario}
              disabled={creandoOp || !nuevoOpNombre.trim()}
              className="text-xs h-8 bg-primary text-primary-foreground"
            >
              {creandoOp ? 'Guardando...' : 'Registrar Operario'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </>
  );
}
