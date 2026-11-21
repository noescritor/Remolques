import React, { useEffect, useState } from 'react';
import {
  AlertTriangle,
  ArrowDown,
  ArrowUp,
  CheckCircle2,
  ClipboardPaste,
  Eye,
  Loader2,
  Plus,
  Save,
  Trash2,
  Upload,
} from 'lucide-react';
import { toast } from 'sonner';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Badge } from '../ui/badge';
import { Switch } from '../ui/switch';
import { calidadApi } from './calidadApi';
import { CalidadImpresion } from './CalidadImpresion';
import {
  PlantillaCalidad,
  PlantillaGrupoCalidad,
  PlantillaItemCalidad,
  normalizarConfigPlantilla,
  parsearLineasActividades,
} from './calidadUtils';

interface CalidadPlantillaEditorModalProps {
  plantillaId: string | null;
  open: boolean;
  ajustes?: any;
  onClose: () => void;
  onGuardado?: () => void;
}

export function CalidadPlantillaEditorModal({
  plantillaId,
  open,
  ajustes,
  onClose,
  onGuardado,
}: CalidadPlantillaEditorModalProps) {
  const [loading, setLoading] = useState(false);
  const [guardando, setGuardando] = useState(false);
  const [publicando, setPublicando] = useState(false);
  const [plantilla, setPlantilla] = useState<PlantillaCalidad | null>(null);

  const [nombre, setNombre] = useState('');
  const [revisionFormato, setRevisionFormato] = useState('');
  const [fechaRevisionFormato, setFechaRevisionFormato] = useState('');
  const [unidades, setUnidades] = useState<string[]>(['Única']);
  const [etqConforme, setEtqConforme] = useState('√');
  const [etqNoConforme, setEtqNoConforme] = useState('X');
  const [bloqueaLiberacion, setBloqueaLiberacion] = useState(false);
  const [grupos, setGrupos] = useState<PlantillaGrupoCalidad[]>([]);

  const [pegarGrupoIdx, setPegarGrupoIdx] = useState<number | null>(null);
  const [textoPegar, setTextoPegar] = useState('');
  const [confirmPublicar, setConfirmPublicar] = useState(false);
  const [vistaPreviaOpen, setVistaPreviaOpen] = useState(false);

  const cargar = async () => {
    if (!plantillaId) return;
    setLoading(true);
    try {
      const pl = await calidadApi.obtenerPlantilla(plantillaId);
      setPlantilla(pl);
      setNombre(pl.nombre || '');
      setRevisionFormato(pl.revision_formato || '');
      setFechaRevisionFormato(pl.fecha_revision_formato || '');
      const cfg = normalizarConfigPlantilla(pl.config);
      setUnidades(cfg.unidades);
      setEtqConforme(cfg.etiquetas_resultado.conforme);
      setEtqNoConforme(cfg.etiquetas_resultado.no_conforme);
      setBloqueaLiberacion(cfg.bloquea_liberacion);
      setGrupos(
        (pl.grupos || []).map((g) => ({
          ...g,
          items: [...(g.items || [])].sort((a, b) => a.orden - b.orden),
        })),
      );
    } catch (e: any) {
      toast.error(e.message || 'No se pudo cargar la plantilla');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && plantillaId) {
      cargar();
    }
  }, [open, plantillaId]);

  const esBorrador = plantilla?.estado === 'borrador';

  const renumerarItems = (listaGrupos: PlantillaGrupoCalidad[]): PlantillaGrupoCalidad[] => {
    let consecutivo = 1;
    return listaGrupos.map((g, gi) => ({
      ...g,
      orden: gi + 1,
      items: (g.items || []).map((it, ii) => ({
        ...it,
        orden: ii + 1,
        numero: consecutivo++,
      })),
    }));
  };

  const moverGrupo = (idx: number, dir: -1 | 1) => {
    const dest = idx + dir;
    if (dest < 0 || dest >= grupos.length) return;
    const copia = [...grupos];
    const [item] = copia.splice(idx, 1);
    copia.splice(dest, 0, item);
    setGrupos(renumerarItems(copia));
  };

  const agregarGrupo = () => {
    const nuevo: PlantillaGrupoCalidad = {
      orden: grupos.length + 1,
      nombre: `Nuevo grupo ${grupos.length + 1}`,
      numero_original: String(grupos.length + 1),
      fase_orden: null,
      fase_confirmada: true,
      items: [],
    };
    setGrupos(renumerarItems([...grupos, nuevo]));
  };

  const eliminarGrupo = (idx: number) => {
    const copia = grupos.filter((_, i) => i !== idx);
    setGrupos(renumerarItems(copia));
  };

  const moverActividad = (gIdx: number, iIdx: number, dir: -1 | 1) => {
    const items = [...(grupos[gIdx].items || [])];
    const dest = iIdx + dir;
    if (dest < 0 || dest >= items.length) return;
    const [mov] = items.splice(iIdx, 1);
    items.splice(dest, 0, mov);
    const copia = grupos.map((g, idx) => (idx === gIdx ? { ...g, items } : g));
    setGrupos(renumerarItems(copia));
  };

  const agregarActividad = (gIdx: number) => {
    const copia = grupos.map((g, idx) =>
      idx === gIdx
        ? {
            ...g,
            items: [
              ...(g.items || []),
              { orden: (g.items?.length || 0) + 1, numero: 1, texto: 'Nueva actividad', aplica_si: null },
            ],
          }
        : g,
    );
    setGrupos(renumerarItems(copia));
  };

  const eliminarActividad = (gIdx: number, iIdx: number) => {
    const copia = grupos.map((g, idx) =>
      idx === gIdx ? { ...g, items: g.items.filter((_, ii) => ii !== iIdx) } : g,
    );
    setGrupos(renumerarItems(copia));
  };

  const aplicarPegado = () => {
    if (pegarGrupoIdx === null) return;
    const nuevas = parsearLineasActividades(textoPegar, 1);
    if (nuevas.length === 0) {
      setPegarGrupoIdx(null);
      return;
    }
    const copia = grupos.map((g, idx) =>
      idx === pegarGrupoIdx ? { ...g, items: [...(g.items || []), ...nuevas] } : g,
    );
    setGrupos(renumerarItems(copia));
    setPegarGrupoIdx(null);
    setTextoPegar('');
    toast.success(`${nuevas.length} actividades agregadas`);
  };

  const armarPayload = () => ({
    nombre: nombre.trim() || plantilla?.nombre,
    revision_formato: revisionFormato.trim() || null,
    fecha_revision_formato: fechaRevisionFormato || null,
    config: {
      unidades: unidades.map((u) => u.trim() || 'Unidad'),
      etiquetas_resultado: {
        conforme: etqConforme.trim() || '√',
        no_conforme: etqNoConforme.trim() || 'X',
      },
      bloquea_liberacion: bloqueaLiberacion,
    },
    grupos: grupos.map((g, gi) => ({
      orden: gi + 1,
      nombre: g.nombre.trim() || `Grupo ${gi + 1}`,
      numero_original: g.numero_original || null,
      fase_orden: g.fase_orden ?? null,
      fase_confirmada: g.fase_confirmada !== false,
      items: (g.items || []).map((it, ii) => ({
        orden: ii + 1,
        numero: it.numero,
        texto: it.texto.trim() || 'Actividad',
        aplica_si: it.aplica_si?.trim() || null,
      })),
    })),
  });

  const handleGuardar = async (): Promise<boolean> => {
    if (!plantillaId || !esBorrador) return false;
    setGuardando(true);
    try {
      const act = await calidadApi.guardarPlantilla(plantillaId, armarPayload());
      setPlantilla(act);
      toast.success('Borrador guardado');
      onGuardado?.();
      return true;
    } catch (e: any) {
      toast.error(e.message || 'Error al guardar borrador');
      return false;
    } finally {
      setGuardando(false);
    }
  };

  const handlePublicar = async () => {
    if (!plantillaId) return;
    setPublicando(true);
    try {
      if (esBorrador) {
        const ok = await handleGuardar();
        if (!ok) return;
      }
      await calidadApi.publicarPlantilla(plantillaId);
      setConfirmPublicar(false);
      toast.success('Plantilla publicada como activa');
      onGuardado?.();
      onClose();
    } catch (e: any) {
      toast.error(e.message || 'No se pudo publicar la plantilla');
    } finally {
      setPublicando(false);
    }
  };

  const plantillaParaPreview: PlantillaCalidad | null = plantilla
    ? {
        ...plantilla,
        nombre,
        revision_formato: revisionFormato || null,
        fecha_revision_formato: fechaRevisionFormato || null,
        config: {
          unidades,
          etiquetas_resultado: { conforme: etqConforme, no_conforme: etqNoConforme },
          bloquea_liberacion: bloqueaLiberacion,
        },
        grupos,
      }
    : null;

  return (
    <>
      <Dialog open={open} onOpenChange={(v) => { if (!v) onClose(); }}>
        <DialogContent className="w-[96vw] max-w-5xl h-[92vh] flex flex-col p-0 overflow-hidden bg-card border-border">
          <DialogHeader className="px-6 pt-4 pb-3 border-b border-border shrink-0">
            <div className="flex items-center justify-between gap-2 pr-8 flex-wrap">
              <div>
                <DialogTitle className="flex items-center gap-2">
                  <span>Editor de Plantilla</span>
                  {plantilla && (
                    <>
                      <Badge variant="outline">v{plantilla.version}</Badge>
                      <Badge variant="outline">{plantilla.linea?.nombre || 'Línea'}</Badge>
                      <Badge variant="outline">
                        {plantilla.formato === 'control_total' ? 'Control Total' : 'Entrega'}
                      </Badge>
                      <Badge
                        className={
                          esBorrador
                            ? 'bg-amber-500/15 text-amber-600 border-amber-500/30'
                            : 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                        }
                      >
                        {plantilla.estado}
                      </Badge>
                    </>
                  )}
                </DialogTitle>
                <DialogDescription className="text-xs mt-1">
                  {esBorrador
                    ? 'Edita los datos, grupos y actividades de este borrador antes de publicarlo.'
                    : 'Solo los borradores son editables. Crea una nueva versión desde la lista para modificarla.'}
                </DialogDescription>
              </div>
            </div>
          </DialogHeader>

          <div className="flex-1 overflow-y-auto px-6 py-4 space-y-5">
            {loading ? (
              <div className="flex items-center justify-center py-16 text-muted-foreground">
                <Loader2 className="h-6 w-6 animate-spin mr-2" /> Cargando plantilla...
              </div>
            ) : (
              <>
                {/* Metadatos y configuración */}
                <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 p-4 rounded-lg border border-border bg-background">
                  <div className="sm:col-span-2 lg:col-span-1">
                    <Label className="text-xs">Nombre de la plantilla</Label>
                    <Input value={nombre} disabled={!esBorrador} onChange={(e) => setNombre(e.target.value)} />
                  </div>
                  <div>
                    <Label className="text-xs">Revisión del formato</Label>
                    <Input
                      value={revisionFormato}
                      disabled={!esBorrador}
                      placeholder="Ej. REV. 02"
                      onChange={(e) => setRevisionFormato(e.target.value)}
                    />
                  </div>
                  <div>
                    <Label className="text-xs">Fecha de revisión</Label>
                    <Input
                      type="date"
                      value={fechaRevisionFormato}
                      disabled={!esBorrador}
                      onChange={(e) => setFechaRevisionFormato(e.target.value)}
                    />
                  </div>

                  {/* Unidades (1 o 2) */}
                  <div>
                    <Label className="text-xs">Columnas de unidades</Label>
                    <div className="flex items-center gap-2 mt-1">
                      <Button
                        type="button"
                        size="sm"
                        variant={unidades.length === 1 ? 'default' : 'outline'}
                        disabled={!esBorrador}
                        onClick={() => setUnidades([unidades[0] || 'Única'])}
                      >
                        1 unidad
                      </Button>
                      <Button
                        type="button"
                        size="sm"
                        variant={unidades.length === 2 ? 'default' : 'outline'}
                        disabled={!esBorrador}
                        onClick={() => setUnidades([unidades[0] || 'Unidad 1', unidades[1] || 'Unidad 2'])}
                      >
                        2 unidades
                      </Button>
                    </div>
                  </div>
                  {unidades.map((u, ui) => (
                    <div key={ui}>
                      <Label className="text-xs">Nombre unidad {ui + 1}</Label>
                      <Input
                        value={u}
                        disabled={!esBorrador}
                        onChange={(e) => {
                          const copia = [...unidades];
                          copia[ui] = e.target.value;
                          setUnidades(copia);
                        }}
                      />
                    </div>
                  ))}

                  {/* Etiquetas */}
                  <div>
                    <Label className="text-xs">Etiqueta Conforme</Label>
                    <Input
                      value={etqConforme}
                      disabled={!esBorrador}
                      onChange={(e) => setEtqConforme(e.target.value)}
                    />
                  </div>
                  <div>
                    <Label className="text-xs">Etiqueta No conforme</Label>
                    <Input
                      value={etqNoConforme}
                      disabled={!esBorrador}
                      onChange={(e) => setEtqNoConforme(e.target.value)}
                    />
                  </div>

                  {/* Bloquea liberación */}
                  <div className="sm:col-span-2 lg:col-span-3 flex items-center justify-between gap-4 pt-2 border-t border-border/60">
                    <div>
                      <div className="text-sm font-medium text-foreground">Bloquear liberación si hay no conformes</div>
                      <p className="text-xs text-muted-foreground">
                        Por defecto permanece apagado: un no conforme solo avisa y nunca bloquea la entrega.
                      </p>
                    </div>
                    <Switch
                      checked={bloqueaLiberacion}
                      disabled={!esBorrador}
                      onCheckedChange={setBloqueaLiberacion}
                    />
                  </div>
                </div>

                {/* Grupos y actividades */}
                <div className="space-y-4">
                  <div className="flex items-center justify-between">
                    <h3 className="text-sm font-semibold text-foreground">
                      Grupos y actividades ({grupos.reduce((a, g) => a + g.items.length, 0)} puntos)
                    </h3>
                    {esBorrador && (
                      <Button size="sm" variant="outline" onClick={agregarGrupo}>
                        <Plus className="h-4 w-4 mr-1" /> Agregar grupo
                      </Button>
                    )}
                  </div>

                  {grupos.map((g, gIdx) => (
                    <div key={g.id || gIdx} className="border border-border rounded-lg bg-background overflow-hidden">
                      <div className="bg-muted/50 px-3 py-2.5 border-b border-border flex flex-wrap items-center gap-2">
                        <Input
                          value={g.numero_original || ''}
                          disabled={!esBorrador}
                          placeholder="#"
                          onChange={(e) => {
                            const val = e.target.value;
                            setGrupos((prev) =>
                              prev.map((gr, idx) => (idx === gIdx ? { ...gr, numero_original: val } : gr)),
                            );
                          }}
                          className="w-14 h-8 text-xs font-mono"
                          title="Número original del proceso"
                        />
                        <Input
                          value={g.nombre}
                          disabled={!esBorrador}
                          onChange={(e) => {
                            const val = e.target.value;
                            setGrupos((prev) =>
                              prev.map((gr, idx) => (idx === gIdx ? { ...gr, nombre: val } : gr)),
                            );
                          }}
                          className="flex-1 min-w-[180px] h-8 text-sm font-semibold"
                        />
                        {plantilla?.formato === 'control_total' && (
                          <div className="flex items-center gap-1.5">
                            <Input
                              type="number"
                              value={g.fase_orden ?? ''}
                              disabled={!esBorrador}
                              placeholder="Fase #"
                              onChange={(e) => {
                                const val = e.target.value ? Number(e.target.value) : null;
                                setGrupos((prev) =>
                                  prev.map((gr, idx) =>
                                    idx === gIdx ? { ...gr, fase_orden: val, fase_confirmada: true } : gr,
                                  ),
                                );
                              }}
                              className="w-20 h-8 text-xs"
                              title="Orden de fase del tablero"
                            />
                            {g.fase_confirmada === false && (
                              <Badge variant="outline" className="text-[11px] text-amber-600 border-amber-500/40">
                                Por confirmar
                              </Badge>
                            )}
                          </div>
                        )}
                        {esBorrador && (
                          <div className="flex items-center gap-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-8 w-8 p-0"
                              onClick={() => moverGrupo(gIdx, -1)}
                              disabled={gIdx === 0}
                              title="Subir grupo"
                            >
                              <ArrowUp className="h-3.5 w-3.5" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-8 w-8 p-0"
                              onClick={() => moverGrupo(gIdx, 1)}
                              disabled={gIdx === grupos.length - 1}
                              title="Bajar grupo"
                            >
                              <ArrowDown className="h-3.5 w-3.5" />
                            </Button>
                            <Button
                              size="sm"
                              variant="ghost"
                              className="h-8 w-8 p-0 text-destructive"
                              onClick={() => eliminarGrupo(gIdx)}
                              title="Eliminar grupo"
                            >
                              <Trash2 className="h-3.5 w-3.5" />
                            </Button>
                          </div>
                        )}
                      </div>

                      <div className="divide-y divide-border/50 p-2 space-y-1.5">
                        {g.items.map((it: PlantillaItemCalidad, iIdx: number) => (
                          <div key={it.id || iIdx} className="flex flex-wrap sm:flex-nowrap items-center gap-2 pt-1.5 first:pt-0">
                            <span className="font-mono text-xs text-muted-foreground w-8 text-right shrink-0">
                              {it.numero}
                            </span>
                            <Input
                              value={it.texto}
                              disabled={!esBorrador}
                              onChange={(e) => {
                                const val = e.target.value;
                                setGrupos((prev) =>
                                  prev.map((gr, gi) =>
                                    gi === gIdx
                                      ? {
                                          ...gr,
                                          items: gr.items.map((item, ii) =>
                                            ii === iIdx ? { ...item, texto: val } : item,
                                          ),
                                        }
                                      : gr,
                                  ),
                                );
                              }}
                              className="flex-1 min-w-[200px] h-8 text-xs"
                            />
                            <Input
                              value={it.aplica_si || ''}
                              disabled={!esBorrador}
                              placeholder="En caso de... (opcional)"
                              onChange={(e) => {
                                const val = e.target.value;
                                setGrupos((prev) =>
                                  prev.map((gr, gi) =>
                                    gi === gIdx
                                      ? {
                                          ...gr,
                                          items: gr.items.map((item, ii) =>
                                            ii === iIdx ? { ...item, aplica_si: val } : item,
                                          ),
                                        }
                                      : gr,
                                  ),
                                );
                              }}
                              className="w-44 h-8 text-xs"
                            />
                            {esBorrador && (
                              <div className="flex items-center gap-0.5 shrink-0">
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-7 w-7 p-0"
                                  onClick={() => moverActividad(gIdx, iIdx, -1)}
                                  disabled={iIdx === 0}
                                >
                                  <ArrowUp className="h-3 w-3" />
                                </Button>
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-7 w-7 p-0"
                                  onClick={() => moverActividad(gIdx, iIdx, 1)}
                                  disabled={iIdx === g.items.length - 1}
                                >
                                  <ArrowDown className="h-3 w-3" />
                                </Button>
                                <Button
                                  size="sm"
                                  variant="ghost"
                                  className="h-7 w-7 p-0 text-destructive"
                                  onClick={() => eliminarActividad(gIdx, iIdx)}
                                >
                                  <Trash2 className="h-3 w-3" />
                                </Button>
                              </div>
                            )}
                          </div>
                        ))}

                        {esBorrador && (
                          <div className="pt-2 flex flex-wrap gap-2">
                            <Button size="sm" variant="outline" className="h-7 text-xs" onClick={() => agregarActividad(gIdx)}>
                              <Plus className="h-3.5 w-3.5 mr-1" /> Agregar actividad
                            </Button>
                            <Button
                              size="sm"
                              variant="outline"
                              className="h-7 text-xs"
                              onClick={() => {
                                setPegarGrupoIdx(gIdx);
                                setTextoPegar('');
                              }}
                            >
                              <ClipboardPaste className="h-3.5 w-3.5 mr-1" /> Pegar varias líneas
                            </Button>
                          </div>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              </>
            )}
          </div>

          <DialogFooter className="px-6 py-3 border-t border-border shrink-0 flex flex-wrap items-center justify-between gap-2 bg-card">
            <Button
              variant="outline"
              size="sm"
              disabled={!plantillaParaPreview}
              onClick={() => setVistaPreviaOpen(true)}
            >
              <Eye className="h-4 w-4 mr-1.5" /> Vista previa de impresión
            </Button>

            <div className="flex items-center gap-2">
              <Button variant="ghost" size="sm" onClick={onClose}>
                Cerrar
              </Button>
              {esBorrador && (
                <>
                  <Button variant="outline" size="sm" onClick={handleGuardar} disabled={guardando}>
                    {guardando ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : <Save className="h-4 w-4 mr-1.5" />}
                    Guardar borrador
                  </Button>
                  <Button size="sm" onClick={() => setConfirmPublicar(true)} disabled={guardando || publicando}>
                    <Upload className="h-4 w-4 mr-1.5" /> Publicar
                  </Button>
                </>
              )}
            </div>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Pegar varias líneas */}
      <Dialog open={pegarGrupoIdx !== null} onOpenChange={(v) => { if (!v) setPegarGrupoIdx(null); }}>
        <DialogContent className="max-w-lg bg-card border-border">
          <DialogHeader>
            <DialogTitle>Pegar varias actividades</DialogTitle>
            <DialogDescription>
              Escribe o pega una actividad por línea. Se agregarán numeradas automáticamente al grupo.
            </DialogDescription>
          </DialogHeader>
          <Textarea
            rows={8}
            placeholder={"Revisar soldadura de chasis\nVerificar nivelado\nLimpieza de escoria"}
            value={textoPegar}
            onChange={(e) => setTextoPegar(e.target.value)}
          />
          <DialogFooter>
            <Button variant="outline" onClick={() => setPegarGrupoIdx(null)}>Cancelar</Button>
            <Button onClick={aplicarPegado}>Agregar actividades</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmación de publicación */}
      <Dialog open={confirmPublicar} onOpenChange={setConfirmPublicar}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle>Publicar plantilla v{plantilla?.version}</DialogTitle>
            <DialogDescription>
              La versión activa anterior quedará archivada. Las inspecciones ya realizadas conservarán exactamente su plantilla original y no cambiarán.
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmPublicar(false)} disabled={publicando}>
              Cancelar
            </Button>
            <Button onClick={handlePublicar} disabled={publicando}>
              {publicando ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : <CheckCircle2 className="h-4 w-4 mr-1.5" />}
              Confirmar publicación
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Vista previa de impresión en blanco */}
      {vistaPreviaOpen && plantillaParaPreview && (
        <CalidadImpresion
          plantilla={plantillaParaPreview}
          ajustes={ajustes}
          enBlanco={true}
          onCerrar={() => setVistaPreviaOpen(false)}
        />
      )}
    </>
  );
}
