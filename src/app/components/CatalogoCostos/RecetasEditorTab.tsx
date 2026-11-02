import React, { useState, useEffect, useMemo } from 'react';
import {
  Layers,
  Copy,
  Plus,
  Trash2,
  Edit2,
  History,
  CheckCircle2,
  AlertCircle,
  Search,
  ArrowRight,
  Package,
  Wrench,
  Info
} from 'lucide-react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from '../ui/dialog';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import {
  Accordion,
  AccordionContent,
  AccordionItem,
  AccordionTrigger,
} from '../ui/accordion';

const BASE_URL = 'http://localhost:8000';

interface RecetasEditorTabProps {
  getAuthToken?: () => Promise<string | null>;
  modelos: any[];
  onModelosChange?: () => void;
}

export function RecetasEditorTab({ getAuthToken, modelos, onModelosChange }: RecetasEditorTabProps) {
  const [selectedModeloId, setSelectedModeloId] = useState<string>('');
  const [cargandoReceta, setCargandoReceta] = useState(false);
  const [datosReceta, setDatosReceta] = useState<any>(null);
  const [historial, setHistorial] = useState<any[]>([]);
  const [verHistorial, setVerHistorial] = useState(false);

  // Modal Nueva Receta Desde... (Clonar)
  const [modalClonarOpen, setModalClonarOpen] = useState(false);
  const [clonando, setClonando] = useState(false);
  const [formClonar, setFormClonar] = useState({
    modeloOrigenId: '',
    productoId: '',
    nombre: '',
    largoFt: 40,
    numEjes: 2,
  });

  // Modal Agregar/Editar Línea de Receta
  const [modalLineaOpen, setModalLineaOpen] = useState(false);
  const [guardandoLinea, setGuardandoLinea] = useState(false);
  const [lineaEditando, setLineaEditando] = useState<any | null>(null);
  const [formLinea, setFormLinea] = useState({
    faseId: '',
    materialId: '',
    cantidad: 1,
    escala: 'fija' as 'fija' | 'por_eje' | 'por_largo',
    paso: '',
    uso: '',
    seccion: 'ensamble',
    motivo: '',
  });

  // Modal Eliminar Línea
  const [modalEliminarOpen, setModalEliminarOpen] = useState(false);
  const [eliminandoLinea, setEliminandoLinea] = useState(false);
  const [lineaEliminando, setLineaEliminando] = useState<any | null>(null);

  // Catálogo de materias primas para selector
  const [productosBusqueda, setProductosBusqueda] = useState<any[]>([]);
  const [busquedaMaterial, setBusquedaMaterial] = useState('');
  const [fasesDisponibles, setFasesDisponibles] = useState<any[]>([]);

  // Notificaciones
  const [alerta, setAlerta] = useState<{ tipo: 'ok' | 'error'; mensaje: string } | null>(null);

  useEffect(() => {
    if (modelos.length > 0 && !selectedModeloId) {
      setSelectedModeloId(modelos[0].id);
    }
  }, [modelos, selectedModeloId]);

  // Cargar fases disponibles
  useEffect(() => {
    const cargarFases = async () => {
      try {
        if (!getAuthToken) return;
        const token = await getAuthToken();
        const res = await fetch(`${BASE_URL}/fases-despiece`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          const data = await res.json();
          setFasesDisponibles(data.fases || []);
        }
      } catch (err) {
        console.error('Error cargando fases:', err);
      }
    };
    cargarFases();
  }, [getAuthToken]);

  // Cargar receta del modelo seleccionado
  const cargarReceta = async (modId: string) => {
    if (!modId || !getAuthToken) return;
    setCargandoReceta(true);
    setAlerta(null);
    try {
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/recetas/${modId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const data = await res.json();
        setDatosReceta(data);
      } else {
        const err = await res.json();
        setAlerta({ tipo: 'error', mensaje: err.error || 'Error cargando receta' });
      }

      // Cargar historial
      const resHist = await fetch(`${BASE_URL}/recetas/${modId}/historial`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (resHist.ok) {
        const histData = await resHist.json();
        setHistorial(histData.historial || []);
      }
    } catch (err: any) {
      setAlerta({ tipo: 'error', mensaje: err.message || 'Error de conexión' });
    } finally {
      setCargandoReceta(false);
    }
  };

  useEffect(() => {
    if (selectedModeloId) {
      cargarReceta(selectedModeloId);
    }
  }, [selectedModeloId]);

  // Buscar materias primas
  useEffect(() => {
    if (!busquedaMaterial || busquedaMaterial.length < 2) {
      setProductosBusqueda([]);
      return;
    }
    const timer = setTimeout(async () => {
      try {
        if (!getAuthToken) return;
        const token = await getAuthToken();
        const res = await fetch(`${BASE_URL}/productos?busqueda=${encodeURIComponent(busquedaMaterial)}&tipo=materia_prima&limit=15`, {
          headers: { Authorization: `Bearer ${token}` },
        });
        if (res.ok) {
          const data = await res.json();
          setProductosBusqueda(data.productos || data || []);
        }
      } catch (err) {
        console.error('Error buscando productos:', err);
      }
    }, 250);
    return () => clearTimeout(timer);
  }, [busquedaMaterial, getAuthToken]);

  // Agrupar líneas por fase
  const lineasPorFase = useMemo(() => {
    if (!datosReceta?.lineas) return {};
    const map: Record<string, any[]> = {};
    for (const linea of datosReceta.lineas) {
      const faseKey = linea.fase?.nombre || 'Otras piezas / Sin fase asignada';
      if (!map[faseKey]) map[faseKey] = [];
      map[faseKey].push(linea);
    }
    return map;
  }, [datosReceta]);

  // Ejecutar clonación
  const handleClonar = async () => {
    if (!formClonar.modeloOrigenId || !formClonar.productoId || !formClonar.nombre) {
      setAlerta({ tipo: 'error', mensaje: 'Todos los campos son obligatorios' });
      return;
    }
    setClonando(true);
    setAlerta(null);
    try {
      if (!getAuthToken) throw new Error('No auth token');
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/recetas/clonar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          modeloOrigenId: formClonar.modeloOrigenId,
          productoId: formClonar.productoId.toUpperCase().trim(),
          nombre: formClonar.nombre.trim(),
          largoFt: Number(formClonar.largoFt),
          numEjes: Number(formClonar.numEjes),
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al clonar modelo');
      }

      setAlerta({ tipo: 'ok', mensaje: `Modelo ${formClonar.nombre} creado con éxito. Las líneas fueron clonadas.` });
      setModalClonarOpen(false);
      if (onModelosChange) onModelosChange();
      setSelectedModeloId(data.modelo_id);
    } catch (err: any) {
      setAlerta({ tipo: 'error', mensaje: err.message || 'Error al clonar' });
    } finally {
      setClonando(false);
    }
  };

  // Abrir modal de agregar/editar línea
  const handleAbrirLinea = (faseIdDefecto?: string, linea?: any) => {
    if (linea) {
      setLineaEditando(linea);
      setFormLinea({
        faseId: linea.fase_id || faseIdDefecto || '',
        materialId: linea.material_id,
        cantidad: linea.cantidad,
        escala: linea.escala || 'fija',
        paso: linea.paso || '',
        uso: linea.uso || '',
        seccion: linea.seccion || 'ensamble',
        motivo: 'Ajuste de receta',
      });
      setBusquedaMaterial(linea.nombre || linea.material_id);
    } else {
      setLineaEditando(null);
      setFormLinea({
        faseId: faseIdDefecto || (fasesDisponibles[0]?.id || ''),
        materialId: '',
        cantidad: 1,
        escala: 'fija',
        paso: '',
        uso: '',
        seccion: 'ensamble',
        motivo: 'Inclusión de nuevo material en receta',
      });
      setBusquedaMaterial('');
    }
    setModalLineaOpen(true);
  };

  // Guardar línea
  const handleGuardarLinea = async () => {
    if (!formLinea.materialId || formLinea.cantidad <= 0 || !formLinea.faseId) {
      setAlerta({ tipo: 'error', mensaje: 'Materia prima, cantidad (> 0) y fase son requeridas' });
      return;
    }
    setGuardandoLinea(true);
    setAlerta(null);
    try {
      if (!getAuthToken) throw new Error('No auth token');
      const token = await getAuthToken();
      const url = lineaEditando
        ? `${BASE_URL}/recetas/${selectedModeloId}/lineas/${lineaEditando.id}`
        : `${BASE_URL}/recetas/${selectedModeloId}/lineas`;
      const method = lineaEditando ? 'PUT' : 'POST';

      const res = await fetch(url, {
        method,
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify(formLinea),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al guardar línea');
      }

      setAlerta({ tipo: 'ok', mensaje: lineaEditando ? 'Línea actualizada con éxito' : 'Línea agregada con éxito' });
      setModalLineaOpen(false);
      cargarReceta(selectedModeloId);
    } catch (err: any) {
      setAlerta({ tipo: 'error', mensaje: err.message || 'Error al guardar línea' });
    } finally {
      setGuardandoLinea(false);
    }
  };

  // Eliminar línea
  const handleEliminarLinea = async () => {
    if (!lineaEliminando) return;
    setEliminandoLinea(true);
    setAlerta(null);
    try {
      if (!getAuthToken) throw new Error('No auth token');
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/recetas/${selectedModeloId}/lineas/${lineaEliminando.id}`, {
        method: 'DELETE',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ motivo: 'Eliminación manual desde editor de recetas' }),
      });

      if (!res.ok) {
        const err = await res.json();
        throw new Error(err.error || 'Error al eliminar línea');
      }

      setAlerta({ tipo: 'ok', mensaje: 'Línea eliminada de la receta' });
      setModalEliminarOpen(false);
      cargarReceta(selectedModeloId);
    } catch (err: any) {
      setAlerta({ tipo: 'error', mensaje: err.message || 'Error al eliminar línea' });
    } finally {
      setEliminandoLinea(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Alerta de feedback */}
      {alerta && (
        <div
          className={`flex items-center gap-3 p-4 rounded-lg border text-sm ${
            alerta.tipo === 'ok'
              ? 'bg-emerald-500/10 border-emerald-500/30 text-emerald-600 dark:text-emerald-400'
              : 'bg-rose-500/10 border-rose-500/30 text-rose-600 dark:text-rose-400'
          }`}
        >
          {alerta.tipo === 'ok' ? <CheckCircle2 className="h-5 w-5 shrink-0" /> : <AlertCircle className="h-5 w-5 shrink-0" />}
          <span>{alerta.mensaje}</span>
        </div>
      )}

      {/* Barra Superior de Control */}
      <div className="flex flex-col sm:flex-row items-stretch sm:items-center justify-between gap-4 p-4 rounded-xl border border-border bg-card shadow-sm">
        <div className="flex flex-col sm:flex-row items-start sm:items-center gap-3">
          <Label className="text-sm font-semibold shrink-0">Modelo en Edición:</Label>
          <Select value={selectedModeloId} onValueChange={setSelectedModeloId}>
            <SelectTrigger className="w-full sm:w-[320px] bg-background">
              <SelectValue placeholder="Seleccionar modelo..." />
            </SelectTrigger>
            <SelectContent>
              {modelos.map((m) => (
                <SelectItem key={m.id} value={m.id}>
                  {m.nombre || m.producto_id} ({m.tipo} - {m.largo_ft}ft / {m.num_ejes}e)
                </SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="flex items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={() => setVerHistorial(!verHistorial)}
            className="flex items-center gap-1.5"
          >
            <History className="h-4 w-4" />
            {verHistorial ? 'Ver Receta' : 'Historial de Cambios'}
          </Button>

          <Button
            size="sm"
            onClick={() => {
              setFormClonar({
                modeloOrigenId: selectedModeloId || (modelos[0]?.id || ''),
                productoId: '',
                nombre: '',
                largoFt: 40,
                numEjes: 2,
              });
              setModalClonarOpen(true);
            }}
            className="flex items-center gap-1.5 bg-primary text-primary-foreground hover:bg-primary/90"
          >
            <Copy className="h-4 w-4" />
            Nueva Receta Desde...
          </Button>
        </div>
      </div>

      {/* Ficha Resumen del Modelo Seleccionado */}
      {datosReceta?.modelo && (
        <Card className="bg-card/50 border-border">
          <CardContent className="pt-6">
            <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-6 gap-4 text-sm">
              <div>
                <span className="text-xs text-muted-foreground block">Clave Producto</span>
                <span className="font-semibold text-foreground">{datosReceta.modelo.producto_id}</span>
              </div>
              <div>
                <span className="text-xs text-muted-foreground block">Tipo</span>
                <Badge variant="outline" className="capitalize mt-0.5">
                  {datosReceta.modelo.tipo}
                </Badge>
              </div>
              <div>
                <span className="text-xs text-muted-foreground block">Largo Nominal</span>
                <span className="font-semibold text-foreground">{datosReceta.modelo.largo_ft} FT</span>
              </div>
              <div>
                <span className="text-xs text-muted-foreground block">Número de Ejes</span>
                <span className="font-semibold text-foreground">{datosReceta.modelo.num_ejes} Ejes</span>
              </div>
              <div>
                <span className="text-xs text-muted-foreground block">Total Insumos</span>
                <span className="font-semibold text-foreground">{datosReceta.lineas?.length || 0} piezas</span>
              </div>
              <div>
                <span className="text-xs text-muted-foreground block">Origen de Costos</span>
                <span className="text-xs text-foreground font-medium">
                  {datosReceta.modelo.costos_derivados_de ? 'Variante derivada' : 'Modelo Base propio'}
                </span>
              </div>
            </div>
          </CardContent>
        </Card>
      )}

      {/* VISTA 1: EDITOR POR FASES */}
      {!verHistorial ? (
        <div className="space-y-4">
          <div className="flex items-center justify-between">
            <h3 className="text-lg font-bold text-foreground flex items-center gap-2">
              <Layers className="h-5 w-5 text-primary" />
              Despiece Oficial de Fabricación por Fases
            </h3>
            <span className="text-xs text-muted-foreground">
              {Object.keys(lineasPorFase).length} fases con materiales asignados
            </span>
          </div>

          {cargandoReceta ? (
            <div className="p-12 text-center text-muted-foreground">Cargando receta del modelo...</div>
          ) : Object.keys(lineasPorFase).length === 0 ? (
            <div className="p-8 text-center border border-dashed border-border rounded-xl text-muted-foreground">
              Este modelo aún no tiene materias primas asignadas en su receta base.
            </div>
          ) : (
            <Accordion type="multiple" defaultValue={Object.keys(lineasPorFase)} className="space-y-3">
              {Object.entries(lineasPorFase).map(([faseNombre, items]: [string, any[]]) => {
                const faseId = items[0]?.fase_id;
                return (
                  <AccordionItem
                    key={faseNombre}
                    value={faseNombre}
                    className="border border-border rounded-xl bg-card overflow-hidden shadow-sm px-4"
                  >
                    <div className="flex items-center justify-between py-2">
                      <AccordionTrigger className="hover:no-underline flex-1 py-2">
                        <div className="flex items-center gap-3 text-left">
                          <span className="font-semibold text-foreground">{faseNombre}</span>
                          <Badge variant="secondary" className="text-xs">
                            {items.length} {items.length === 1 ? 'insumo' : 'insumos'}
                          </Badge>
                        </div>
                      </AccordionTrigger>
                      <Button
                        size="sm"
                        variant="ghost"
                        onClick={(e) => {
                          e.stopPropagation();
                          handleAbrirLinea(faseId);
                        }}
                        className="h-8 text-xs flex items-center gap-1 text-primary hover:text-primary hover:bg-primary/10 ml-2"
                      >
                        <Plus className="h-3.5 w-3.5" />
                        Agregar pieza
                      </Button>
                    </div>

                    <AccordionContent className="pt-2 pb-4">
                      <div className="overflow-x-auto">
                        <table className="w-full text-sm">
                          <thead>
                            <tr className="border-b border-border/60 text-xs text-muted-foreground">
                              <th className="text-left py-2 font-medium">Clave / Material</th>
                              <th className="text-center py-2 font-medium">Cantidad</th>
                              <th className="text-center py-2 font-medium">Escala</th>
                              <th className="text-left py-2 font-medium">Uso / Notas</th>
                              <th className="text-right py-2 font-medium">Costo Estimado</th>
                              <th className="text-right py-2 font-medium">Acciones</th>
                            </tr>
                          </thead>
                          <tbody className="divide-y divide-border/30">
                            {items.map((linea) => {
                              const costoUnit = Number(linea.costo || 0);
                              const subtotal = costoUnit * linea.cantidad;
                              return (
                                <tr key={linea.id} className="hover:bg-muted/30 transition-colors">
                                  <td className="py-2.5">
                                    <div className="font-medium text-foreground">{linea.nombre || linea.material_id}</div>
                                    <div className="text-xs text-muted-foreground font-mono">{linea.material_id}</div>
                                  </td>
                                  <td className="py-2.5 text-center font-semibold text-foreground">
                                    {linea.cantidad} <span className="text-xs text-muted-foreground font-normal">{linea.unidad}</span>
                                  </td>
                                  <td className="py-2.5 text-center">
                                    <Badge
                                      variant="outline"
                                      className={`text-xs ${
                                        linea.escala === 'por_largo'
                                          ? 'border-indigo-500/40 text-indigo-500'
                                          : linea.escala === 'por_eje'
                                          ? 'border-amber-500/40 text-amber-500'
                                          : 'text-muted-foreground'
                                      }`}
                                    >
                                      {linea.escala}
                                    </Badge>
                                  </td>
                                  <td className="py-2.5 text-xs text-muted-foreground max-w-[200px] truncate">
                                    {linea.uso || linea.paso || '—'}
                                  </td>
                                  <td className="py-2.5 text-right font-mono text-xs">
                                    {costoUnit > 0 ? (
                                      <div>
                                        <div className="text-foreground">${subtotal.toLocaleString('es-MX', { minimumFractionDigits: 2 })}</div>
                                        <div className="text-muted-foreground text-[10px]">(${costoUnit.toFixed(2)} c/u)</div>
                                      </div>
                                    ) : (
                                      <span className="text-amber-500 text-[11px]">Sin costo</span>
                                    )}
                                  </td>
                                  <td className="py-2.5 text-right space-x-1">
                                    <Button
                                      size="sm"
                                      variant="ghost"
                                      onClick={() => handleAbrirLinea(linea.fase_id, linea)}
                                      className="h-7 w-7 p-0 text-muted-foreground hover:text-foreground"
                                    >
                                      <Edit2 className="h-3.5 w-3.5" />
                                    </Button>
                                    <Button
                                      size="sm"
                                      variant="ghost"
                                      onClick={() => {
                                        setLineaEliminando(linea);
                                        setModalEliminarOpen(true);
                                      }}
                                      className="h-7 w-7 p-0 text-muted-foreground hover:text-rose-500"
                                    >
                                      <Trash2 className="h-3.5 w-3.5" />
                                    </Button>
                                  </td>
                                </tr>
                              );
                            })}
                          </tbody>
                        </table>
                      </div>
                    </AccordionContent>
                  </AccordionItem>
                );
              })}
            </Accordion>
          )}
        </div>
      ) : (
        /* VISTA 2: HISTORIAL DE AUDITORÍA */
        <Card className="bg-card border-border">
          <CardHeader>
            <CardTitle className="text-base flex items-center gap-2">
              <History className="h-4 w-4 text-primary" />
              Trazabilidad y Auditoría de Modificaciones de Receta
            </CardTitle>
            <CardDescription>
              Registro inmutable de quién, qué pieza y cuándo se alteró la ingeniería de este modelo.
            </CardDescription>
          </CardHeader>
          <CardContent>
            {historial.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground text-sm">
                No hay registros de modificaciones para este modelo.
              </div>
            ) : (
              <div className="divide-y divide-border/40">
                {historial.map((h) => (
                  <div key={h.id} className="py-3 flex items-start justify-between gap-4 text-sm">
                    <div className="space-y-1">
                      <div className="flex items-center gap-2">
                        <Badge
                          variant="outline"
                          className={`text-xs uppercase font-mono ${
                            h.accion === 'clonar_modelo'
                              ? 'border-emerald-500/40 text-emerald-500'
                              : h.accion === 'crear_linea'
                              ? 'border-blue-500/40 text-blue-500'
                              : h.accion === 'modificar_linea'
                              ? 'border-amber-500/40 text-amber-500'
                              : 'border-rose-500/40 text-rose-500'
                          }`}
                        >
                          {h.accion.replace('_', ' ')}
                        </Badge>
                        <span className="font-semibold text-foreground">
                          {h.material_nombre || h.material_id || 'Modelo completo'}
                        </span>
                      </div>
                      {h.motivo && <div className="text-xs text-muted-foreground">{h.motivo}</div>}
                    </div>
                    <div className="text-right text-xs text-muted-foreground whitespace-nowrap">
                      {new Date(h.created_at).toLocaleString('es-MX')}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </CardContent>
        </Card>
      )}

      {/* DIÁLOGO: NUEVA RECETA DESDE... (CLONAR) */}
      <Dialog open={modalClonarOpen} onOpenChange={setModalClonarOpen}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Copy className="h-5 w-5 text-primary" />
              Nueva Receta Desde... (Clonar)
            </DialogTitle>
            <DialogDescription>
              Copia la receta base completa, kits fijos y procesos de un modelo existente para crear una nueva variante en el catálogo.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2 text-sm">
            <div className="space-y-1.5">
              <Label>Modelo Base Origen</Label>
              <Select
                value={formClonar.modeloOrigenId}
                onValueChange={(val) => setFormClonar((prev) => ({ ...prev, modeloOrigenId: val }))}
              >
                <SelectTrigger className="bg-background">
                  <SelectValue placeholder="Seleccionar origen..." />
                </SelectTrigger>
                <SelectContent>
                  {modelos.map((m) => (
                    <SelectItem key={m.id} value={m.id}>
                      {m.nombre || m.producto_id} ({m.largo_ft}ft / {m.num_ejes}e)
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1.5">
              <Label>Clave Única de Producto (ID)</Label>
              <Input
                placeholder="Ej. REM-PLAT-47-2E"
                value={formClonar.productoId}
                onChange={(e) => setFormClonar((prev) => ({ ...prev, productoId: e.target.value }))}
                className="font-mono bg-background uppercase"
              />
            </div>

            <div className="space-y-1.5">
              <Label>Nombre Comercial</Label>
              <Input
                placeholder="Ej. PLATAFORMA 47 FT 2 EJES"
                value={formClonar.nombre}
                onChange={(e) => setFormClonar((prev) => ({ ...prev, nombre: e.target.value }))}
                className="bg-background"
              />
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Largo Nominal (Pies)</Label>
                <Input
                  type="number"
                  step="0.5"
                  value={formClonar.largoFt}
                  onChange={(e) => setFormClonar((prev) => ({ ...prev, largoFt: Number(e.target.value) }))}
                  className="bg-background"
                />
              </div>
              <div className="space-y-1.5">
                <Label>Número de Ejes</Label>
                <Input
                  type="number"
                  value={formClonar.numEjes}
                  onChange={(e) => setFormClonar((prev) => ({ ...prev, numEjes: Number(e.target.value) }))}
                  className="bg-background"
                />
              </div>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalClonarOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleClonar} disabled={clonando}>
              {clonando ? 'Clonando...' : 'Crear Variante'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* DIÁLOGO: AGREGAR O EDITAR LÍNEA */}
      <Dialog open={modalLineaOpen} onOpenChange={setModalLineaOpen}>
        <DialogContent className="max-w-lg bg-card border-border">
          <DialogHeader>
            <DialogTitle>
              {lineaEditando ? 'Modificar Materia Prima en Receta' : 'Agregar Materia Prima a Fase'}
            </DialogTitle>
            <DialogDescription>
              Configura la cantidad y el comportamiento de escala proporcional para este insumo.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2 text-sm">
            <div className="space-y-1.5">
              <Label>Fase de Despiece Destino</Label>
              <Select
                value={formLinea.faseId}
                onValueChange={(val) => setFormLinea((prev) => ({ ...prev, faseId: val }))}
              >
                <SelectTrigger className="bg-background">
                  <SelectValue placeholder="Seleccionar fase..." />
                </SelectTrigger>
                <SelectContent>
                  {fasesDisponibles.map((f) => (
                    <SelectItem key={f.id} value={f.id}>
                      {f.nombre}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1.5">
              <Label>Materia Prima / Insumo</Label>
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  placeholder="Buscar en catálogo por clave o descripción..."
                  value={busquedaMaterial}
                  onChange={(e) => setBusquedaMaterial(e.target.value)}
                  className="pl-9 bg-background"
                />
              </div>

              {productosBusqueda.length > 0 && (
                <div className="border border-border rounded-lg max-h-48 overflow-y-auto divide-y divide-border/30 bg-popover mt-1 shadow-md">
                  {productosBusqueda.map((p) => (
                    <div
                      key={p.id}
                      onClick={() => {
                        setFormLinea((prev) => ({ ...prev, materialId: p.id }));
                        setBusquedaMaterial(p.nombre);
                        setProductosBusqueda([]);
                      }}
                      className="p-2 text-xs hover:bg-muted/50 cursor-pointer flex items-center justify-between"
                    >
                      <div>
                        <div className="font-semibold text-foreground">{p.nombre}</div>
                        <div className="text-[11px] text-muted-foreground font-mono">{p.id}</div>
                      </div>
                      <Badge variant="outline">${Number(p.costo || 0).toFixed(2)}</Badge>
                    </div>
                  ))}
                </div>
              )}
            </div>

            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Cantidad</Label>
                <Input
                  type="number"
                  step="0.01"
                  value={formLinea.cantidad}
                  onChange={(e) => setFormLinea((prev) => ({ ...prev, cantidad: Number(e.target.value) }))}
                  className="bg-background"
                />
              </div>

              <div className="space-y-1.5">
                <Label>Escala Proporcional</Label>
                <Select
                  value={formLinea.escala}
                  onValueChange={(val: any) => setFormLinea((prev) => ({ ...prev, escala: val }))}
                >
                  <SelectTrigger className="bg-background">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="fija">Fija (Cantidad constante)</SelectItem>
                    <SelectItem value="por_eje">Por Eje (x número de ejes)</SelectItem>
                    <SelectItem value="por_largo">Por Largo (x largo_ft / 40)</SelectItem>
                  </SelectContent>
                </Select>
              </div>
            </div>

            <div className="space-y-1.5">
              <Label>Uso / Especificación</Label>
              <Input
                placeholder="Ej. Bastidor central, refuerzo de perno..."
                value={formLinea.uso}
                onChange={(e) => setFormLinea((prev) => ({ ...prev, uso: e.target.value }))}
                className="bg-background"
              />
            </div>

            <div className="space-y-1.5">
              <Label>Motivo del Cambio (Auditoría)</Label>
              <Input
                placeholder="Ej. Ajuste por ingeniería, corrección de medida..."
                value={formLinea.motivo}
                onChange={(e) => setFormLinea((prev) => ({ ...prev, motivo: e.target.value }))}
                className="bg-background"
              />
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalLineaOpen(false)}>
              Cancelar
            </Button>
            <Button onClick={handleGuardarLinea} disabled={guardandoLinea}>
              {guardandoLinea ? 'Guardando...' : 'Guardar Insumo'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* DIÁLOGO: CONFIRMAR ELIMINACIÓN */}
      <Dialog open={modalEliminarOpen} onOpenChange={setModalEliminarOpen}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="text-rose-500 flex items-center gap-2">
              <Trash2 className="h-5 w-5" />
              Eliminar Insumo de la Receta
            </DialogTitle>
            <DialogDescription>
              ¿Estás seguro de eliminar{' '}
              <strong>{lineaEliminando?.nombre || lineaEliminando?.material_id}</strong> de la receta base? Esta acción
              quedará registrada en la bitácora de auditoría.
            </DialogDescription>
          </DialogHeader>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalEliminarOpen(false)}>
              Cancelar
            </Button>
            <Button variant="destructive" onClick={handleEliminarLinea} disabled={eliminandoLinea}>
              {eliminandoLinea ? 'Eliminando...' : 'Confirmar Eliminación'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
