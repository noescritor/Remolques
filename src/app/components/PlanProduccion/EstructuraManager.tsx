import React, { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import {
  Layers,
  ArrowUp,
  ArrowDown,
  Edit2,
  Plus,
  Check,
  X,
  AlertCircle,
  ToggleLeft,
  ToggleRight,
  FolderPlus,
} from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';

interface FrenteItem {
  id: string;
  nombre: string;
  orden: number;
  activo: boolean;
}

interface AreaItem {
  id: string;
  clave: string;
  nombre: string;
  orden?: number;
  activo?: boolean;
  frentes: FrenteItem[];
}

interface EstructuraManagerProps {
  areas: AreaItem[];
  onRecargar: () => Promise<void>;
  session?: any;
}

export function EstructuraManager({ areas, onRecargar, session }: EstructuraManagerProps) {
  const [areaActivaId, setAreaActivaId] = useState<string>(() => (areas[0]?.id || ''));
  const [nuevoFrenteNombre, setNuevoFrenteNombre] = useState('');
  const [guardandoFrente, setGuardandoFrente] = useState(false);

  // Estado para edición en línea de un frente
  const [editandoFrenteId, setEditandoFrenteId] = useState<string | null>(null);
  const [nombreEdicion, setNombreEdicion] = useState('');

  // Estado para alta de nueva área
  const [mostrandoNuevaArea, setMostrandoNuevaArea] = useState(false);
  const [nuevaAreaNombre, setNuevaAreaNombre] = useState('');
  const [nuevaAreaClave, setNuevaAreaClave] = useState('');
  const [guardandoArea, setGuardandoArea] = useState(false);

  const getAuthToken = async () => {
    const { data: { session: currentSession } } = await supabase.auth.getSession();
    return currentSession?.access_token || session?.access_token;
  };

  const areaSeleccionada = areas.find((a) => a.id === areaActivaId) || areas[0];

  // Renombrar frente
  const handleIniciarEdicion = (frente: FrenteItem) => {
    setEditandoFrenteId(frente.id);
    setNombreEdicion(frente.nombre);
  };

  const handleCancelarEdicion = () => {
    setEditandoFrenteId(null);
    setNombreEdicion('');
  };

  const handleGuardarRenombrar = async (frenteId: string) => {
    const nombreLimpio = nombreEdicion.trim();
    if (!nombreLimpio) {
      toast.error('El nombre del frente no puede estar vacío');
      return;
    }

    try {
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/produccion/frentes/${frenteId}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ nombre: nombreLimpio }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al renombrar frente');
      }

      toast.success('Frente renombrado correctamente');
      setEditandoFrenteId(null);
      await onRecargar();
    } catch (err: any) {
      toast.error('No se pudo renombrar el frente', { description: err.message });
    }
  };

  // Alternar activo / inactivo de un frente
  const handleToggleActivo = async (frente: FrenteItem) => {
    try {
      const token = await getAuthToken();
      const nuevoEstado = !frente.activo;
      const res = await fetch(`${BASE_URL}/produccion/frentes/${frente.id}`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ activo: nuevoEstado }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al actualizar estado del frente');
      }

      toast.success(
        nuevoEstado
          ? `Frente "${frente.nombre}" activado`
          : `Frente "${frente.nombre}" desactivado`
      );
      await onRecargar();
    } catch (err: any) {
      toast.error('No se pudo cambiar el estado', { description: err.message });
    }
  };

  // Reordenar frentes (Subir o Bajar)
  const handleMoverFrente = async (frente: FrenteItem, direccion: 'arriba' | 'abajo') => {
    if (!areaSeleccionada) return;
    const frentesOrdenados = [...areaSeleccionada.frentes].sort((a, b) => a.orden - b.orden);
    const idx = frentesOrdenados.findIndex((f) => f.id === frente.id);
    if (idx === -1) return;

    const swapIdx = direccion === 'arriba' ? idx - 1 : idx + 1;
    if (swapIdx < 0 || swapIdx >= frentesOrdenados.length) return;

    const vecino = frentesOrdenados[swapIdx];

    try {
      const token = await getAuthToken();
      // Intercambiar ordenes
      const res1 = await fetch(`${BASE_URL}/produccion/frentes/${frente.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ orden: vecino.orden }),
      });
      const res2 = await fetch(`${BASE_URL}/produccion/frentes/${vecino.id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ orden: frente.orden }),
      });

      if (!res1.ok || !res2.ok) {
        throw new Error('Error al actualizar posiciones de los frentes');
      }

      await onRecargar();
    } catch (err: any) {
      toast.error('No se pudo reordenar', { description: err.message });
    }
  };

  // Agregar nuevo frente al área
  const handleCrearFrente = async (e: React.FormEvent) => {
    e.preventDefault();
    const nombreLimpio = nuevoFrenteNombre.trim();
    if (!nombreLimpio || !areaSeleccionada) return;

    try {
      setGuardandoFrente(true);
      const token = await getAuthToken();
      const maxOrden = areaSeleccionada.frentes.reduce((acc, f) => Math.max(acc, f.orden || 0), 0);

      const res = await fetch(`${BASE_URL}/produccion/frentes`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          area_id: areaSeleccionada.id,
          nombre: nombreLimpio,
          orden: maxOrden + 1,
          activo: true,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al crear frente');
      }

      toast.success(`Frente "${nombreLimpio}" creado con éxito`);
      setNuevoFrenteNombre('');
      await onRecargar();
    } catch (err: any) {
      toast.error('No se pudo crear el frente', { description: err.message });
    } finally {
      setGuardandoFrente(false);
    }
  };

  // Crear nueva área
  const handleCrearArea = async (e: React.FormEvent) => {
    e.preventDefault();
    const nombreLimpio = nuevaAreaNombre.trim();
    if (!nombreLimpio) return;

    try {
      setGuardandoArea(true);
      const token = await getAuthToken();
      const claveLimpia = (nuevaAreaClave || nombreLimpio.toLowerCase().replace(/[^a-z0-9]/g, '_')).slice(0, 50);

      const res = await fetch(`${BASE_URL}/produccion/areas`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          nombre: nombreLimpio,
          clave: claveLimpia,
          orden: areas.length + 1,
          activo: true,
        }),
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al crear área');
      }

      const areaCreada = await res.json();
      toast.success(`Área "${nombreLimpio}" creada con éxito`);
      setNuevaAreaNombre('');
      setNuevaAreaClave('');
      setMostrandoNuevaArea(false);
      await onRecargar();
      if (areaCreada?.id) {
        setAreaActivaId(areaCreada.id);
      }
    } catch (err: any) {
      toast.error('No se pudo crear el área', { description: err.message });
    } finally {
      setGuardandoArea(false);
    }
  };

  const frentes = areaSeleccionada?.frentes || [];

  return (
    <div className="space-y-6">
      {/* Cabecera y Aviso explicativo */}
      <div className="bg-card border border-border/60 rounded-xl p-4 shadow-sm flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h2 className="text-base font-bold text-foreground flex items-center gap-2">
            <Layers className="w-5 h-5 text-primary" />
            Estructura de Producción: Áreas y Frentes de Trabajo
          </h2>
          <p className="text-xs text-muted-foreground mt-1">
            Personaliza las columnas del plan semanal. Puedes agregar frentes, renombrarlos (ej. cambiar &quot;CHASIS 6&quot; a &quot;CHASIS 3&quot;), reordenarlos o desactivarlos.
          </p>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() => setMostrandoNuevaArea(!mostrandoNuevaArea)}
          className="gap-1.5 text-xs self-start md:self-auto border-border"
        >
          <FolderPlus className="w-4 h-4 text-primary" />
          <span>{mostrandoNuevaArea ? 'Cancelar' : 'Nueva Área'}</span>
        </Button>
      </div>

      {/* Alerta de Desactivación */}
      <div className="bg-muted/40 border border-border/70 rounded-lg p-3 text-xs text-muted-foreground flex items-start gap-2.5">
        <AlertCircle className="w-4 h-4 text-primary shrink-0 mt-0.5" />
        <div>
          <span className="font-semibold text-foreground">Regla de trazabilidad:</span> Desactivar un frente no borra ninguna tarea. El frente seguirá mostrándose en las semanas donde tenga tareas históricas registradas, pero dejará de aparecer en semanas nuevas.
        </div>
      </div>

      {/* Formulario de Nueva Área (Desplegable) */}
      {mostrandoNuevaArea && (
        <form onSubmit={handleCrearArea} className="bg-card border border-primary/30 rounded-xl p-4 space-y-3 shadow-xs">
          <div className="text-xs font-bold text-foreground flex items-center gap-2">
            <FolderPlus className="w-4 h-4 text-primary" />
            Crear Nueva Área de Producción
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
            <div>
              <Label className="text-xs">Nombre del Área *</Label>
              <Input
                value={nuevaAreaNombre}
                onChange={(e) => setNuevaAreaNombre(e.target.value)}
                placeholder="Ej. NAVE DE SOLDADURA"
                className="bg-background mt-1 text-xs"
                required
              />
            </div>
            <div>
              <Label className="text-xs">Clave Identificadora (opcional)</Label>
              <Input
                value={nuevaAreaClave}
                onChange={(e) => setNuevaAreaClave(e.target.value)}
                placeholder="Ej. soldadura (se genera auto si está vacío)"
                className="bg-background mt-1 text-xs"
              />
            </div>
          </div>
          <div className="flex justify-end gap-2 pt-1">
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setMostrandoNuevaArea(false)}
              className="text-xs"
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              size="sm"
              disabled={guardandoArea || !nuevaAreaNombre.trim()}
              className="text-xs gap-1"
            >
              <Check className="w-3.5 h-3.5" />
              <span>Guardar Área</span>
            </Button>
          </div>
        </form>
      )}

      {/* Pestañas de Áreas */}
      <div className="flex items-center gap-2 overflow-x-auto pb-1 scrollbar-none border-b border-border/60">
        {areas.map((a) => {
          const esActiva = a.id === areaActivaId || (!areaActivaId && a.id === areas[0]?.id);
          const totalFrentes = a.frentes?.length || 0;
          const frentesActivos = a.frentes?.filter((f) => f.activo)?.length || 0;

          return (
            <button
              key={a.id}
              type="button"
              onClick={() => setAreaActivaId(a.id)}
              className={`px-3.5 py-2 rounded-t-lg text-xs font-semibold whitespace-nowrap transition-colors border-t border-x -mb-px flex items-center gap-2 ${
                esActiva
                  ? 'bg-card text-foreground border-border/70 border-b-transparent shadow-xs'
                  : 'bg-muted/30 text-muted-foreground hover:text-foreground border-transparent hover:bg-muted/60'
              }`}
            >
              <span>{a.nombre}</span>
              <Badge
                variant="outline"
                className={`text-[10px] px-1.5 py-0 ${
                  esActiva ? 'bg-primary/10 text-primary border-primary/20' : 'bg-muted text-muted-foreground border-border/40'
                }`}
              >
                {frentesActivos}/{totalFrentes} frentes
              </Badge>
            </button>
          );
        })}
      </div>

      {/* Contenido del Área Seleccionada */}
      {areaSeleccionada ? (
        <div className="bg-card border border-border/60 rounded-xl p-4 shadow-sm space-y-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-border/40">
            <div>
              <div className="text-sm font-bold text-foreground">
                Frentes de Trabajo de &quot;{areaSeleccionada.nombre}&quot;
              </div>
              <div className="text-xs text-muted-foreground">
                Columnas visibles en la cuadrícula de trabajo de esta área (de izquierda a derecha).
              </div>
            </div>

            {/* Agregar nuevo frente */}
            <form onSubmit={handleCrearFrente} className="flex items-center gap-2">
              <Input
                value={nuevoFrenteNombre}
                onChange={(e) => setNuevoFrenteNombre(e.target.value)}
                placeholder="Nombre del nuevo frente..."
                className="bg-background text-xs h-8 w-56"
              />
              <Button
                type="submit"
                size="sm"
                disabled={guardandoFrente || !nuevoFrenteNombre.trim()}
                className="text-xs h-8 gap-1"
              >
                <Plus className="w-3.5 h-3.5" />
                <span>Agregar</span>
              </Button>
            </form>
          </div>

          {/* Tabla de Frentes */}
          <div className="overflow-x-auto border border-border/50 rounded-lg">
            <table className="w-full text-xs text-left">
              <thead className="bg-muted/40 border-b border-border/50 text-muted-foreground uppercase font-semibold text-[11px]">
                <tr>
                  <th className="p-2.5 w-16 text-center">Orden</th>
                  <th className="p-2.5">Nombre del Frente (Columna)</th>
                  <th className="p-2.5 w-28 text-center">Estado</th>
                  <th className="p-2.5 w-44 text-right">Acciones</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border/40">
                {frentes.length === 0 ? (
                  <tr>
                    <td colSpan={4} className="p-6 text-center text-muted-foreground italic">
                      No hay frentes configurados en esta área. Agrega uno arriba.
                    </td>
                  </tr>
                ) : (
                  frentes.map((frente, index) => {
                    const esEditando = editandoFrenteId === frente.id;

                    return (
                      <tr
                        key={frente.id}
                        className={`hover:bg-muted/20 transition-colors ${
                          !frente.activo ? 'opacity-60 bg-muted/10' : ''
                        }`}
                      >
                        {/* Orden */}
                        <td className="p-2.5 text-center font-mono font-bold text-muted-foreground">
                          {index + 1}
                        </td>

                        {/* Nombre del Frente */}
                        <td className="p-2.5">
                          {esEditando ? (
                            <div className="flex items-center gap-2">
                              <Input
                                value={nombreEdicion}
                                onChange={(e) => setNombreEdicion(e.target.value)}
                                className="bg-background text-xs h-7 max-w-xs"
                                autoFocus
                              />
                              <Button
                                type="button"
                                size="icon"
                                variant="default"
                                onClick={() => handleGuardarRenombrar(frente.id)}
                                className="h-7 w-7 text-xs"
                                title="Guardar"
                              >
                                <Check className="w-3.5 h-3.5" />
                              </Button>
                              <Button
                                type="button"
                                size="icon"
                                variant="ghost"
                                onClick={handleCancelarEdicion}
                                className="h-7 w-7 text-xs"
                                title="Cancelar"
                              >
                                <X className="w-3.5 h-3.5" />
                              </Button>
                            </div>
                          ) : (
                            <div className="flex items-center gap-2">
                              <span className="font-semibold text-foreground">{frente.nombre}</span>
                              {frente.nombre.includes('CHASIS 6') && (
                                <Badge variant="outline" className="text-[10px] bg-primary/10 text-primary border-primary/20">
                                  Editable a CHASIS 3
                                </Badge>
                              )}
                            </div>
                          )}
                        </td>

                        {/* Estado */}
                        <td className="p-2.5 text-center">
                          <button
                            type="button"
                            onClick={() => handleToggleActivo(frente)}
                            className="inline-flex items-center gap-1.5 focus:outline-none"
                            title={frente.activo ? 'Clic para desactivar' : 'Clic para activar'}
                          >
                            {frente.activo ? (
                              <>
                                <ToggleRight className="w-5 h-5 text-primary" />
                                <Badge variant="outline" className="text-[10px] bg-primary/10 text-primary border-primary/20">
                                  Activo
                                </Badge>
                              </>
                            ) : (
                              <>
                                <ToggleLeft className="w-5 h-5 text-muted-foreground" />
                                <Badge variant="outline" className="text-[10px] bg-muted text-muted-foreground border-border/40">
                                  Inactivo
                                </Badge>
                              </>
                            )}
                          </button>
                        </td>

                        {/* Acciones */}
                        <td className="p-2.5 text-right">
                          <div className="flex items-center justify-end gap-1">
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              disabled={index === 0}
                              onClick={() => handleMoverFrente(frente, 'arriba')}
                              className="h-7 w-7 text-muted-foreground hover:text-foreground"
                              title="Subir (mover a la izquierda)"
                            >
                              <ArrowUp className="w-3.5 h-3.5" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              disabled={index === frentes.length - 1}
                              onClick={() => handleMoverFrente(frente, 'abajo')}
                              className="h-7 w-7 text-muted-foreground hover:text-foreground"
                              title="Bajar (mover a la derecha)"
                            >
                              <ArrowDown className="w-3.5 h-3.5" />
                            </Button>
                            <Button
                              type="button"
                              variant="ghost"
                              size="icon"
                              onClick={() => handleIniciarEdicion(frente)}
                              className="h-7 w-7 text-muted-foreground hover:text-foreground"
                              title="Renombrar frente"
                            >
                              <Edit2 className="w-3.5 h-3.5" />
                            </Button>
                          </div>
                        </td>
                      </tr>
                    );
                  })
                )}
              </tbody>
            </table>
          </div>
        </div>
      ) : null}
    </div>
  );
}
