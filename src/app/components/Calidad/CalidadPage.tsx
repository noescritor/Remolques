import React, { useEffect, useMemo, useState } from 'react';
import {
  AlertTriangle,
  CheckCircle2,
  ClipboardCheck,
  Copy,
  Edit,
  FilePlus,
  Loader2,
  Plus,
  RotateCcw,
  Trash2,
  Upload,
} from 'lucide-react';
import { toast } from 'sonner';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { calidadApi, CalidadApiError } from './calidadApi';
import { CalidadInspeccionModal } from './CalidadInspeccionModal';
import { CalidadPlantillaEditorModal } from './CalidadPlantillaEditorModal';
import {
  FormatoCalidad,
  PlantillaCalidad,
  normalizarConfigPlantilla,
  resolverPlantillaSugerida,
} from './calidadUtils';

interface CalidadPageProps {
  ordenesTrabajo?: any[];
  lineasProducto?: any[];
  ajustes?: any;
  tabInicial?: 'inspecciones' | 'plantillas';
}

export function CalidadPage({
  ordenesTrabajo = [],
  lineasProducto = [],
  ajustes,
  tabInicial = 'inspecciones',
}: CalidadPageProps) {
  const [tab, setTab] = useState<'inspecciones' | 'plantillas'>(tabInicial);
  const [loading, setLoading] = useState(true);
  const [inspecciones, setInspecciones] = useState<any[]>([]);
  const [plantillas, setPlantillas] = useState<PlantillaCalidad[]>([]);

  // Filtros de inspecciones
  const [filtroFormato, setFiltroFormato] = useState<string>('todos');
  const [filtroEstado, setFiltroEstado] = useState<string>('todos');
  const [filtroLinea, setFiltroLinea] = useState<string>('todas');
  const [soloNoConformes, setSoloNoConformes] = useState(false);

  // Modales
  const [inspeccionAbiertaId, setInspeccionAbiertaId] = useState<string | null>(null);
  const [editorPlantillaId, setEditorPlantillaId] = useState<string | null>(null);

  // Nueva inspección
  const [nuevaInspOpen, setNuevaInspOpen] = useState(false);
  const [selOrdenId, setSelOrdenId] = useState('');
  const [selFormato, setSelFormato] = useState<FormatoCalidad>('control_total');
  const [selPlantillaId, setSelPlantillaId] = useState('');
  const [creandoInsp, setCreandoInsp] = useState(false);
  const [yaExisteId, setYaExisteId] = useState<string | null>(null);

  // Nueva / Duplicar plantilla
  const [nuevaPlOpen, setNuevaPlOpen] = useState(false);
  const [duplicarDe, setDuplicarDe] = useState<PlantillaCalidad | null>(null);
  const [plNombre, setPlNombre] = useState('');
  const [plLineaClave, setPlLineaClave] = useState('dolly');
  const [plFormato, setPlFormato] = useState<FormatoCalidad>('control_total');
  const [creandoPl, setCreandoPl] = useState(false);

  // Confirmar publicar / restaurar / eliminar
  const [confirmAccionPl, setConfirmAccionPl] = useState<{
    tipo: 'publicar' | 'restaurar' | 'eliminar';
    plantilla: PlantillaCalidad;
  } | null>(null);
  const [ejecutandoPl, setEjecutandoPl] = useState(false);

  const cargarTodo = async () => {
    setLoading(true);
    try {
      const [pls, insps] = await Promise.all([
        calidadApi.listarPlantillas(),
        calidadApi.listarInspecciones(),
      ]);
      setPlantillas(Array.isArray(pls) ? pls : []);
      setInspecciones(Array.isArray(insps) ? insps : []);
    } catch (e: any) {
      toast.error(e.message || 'No se pudo cargar el módulo de calidad');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    cargarTodo();
  }, []);

  const plantillasActivas = useMemo(
    () => plantillas.filter((p) => p.estado === 'activa'),
    [plantillas],
  );

  // Actualizar plantilla sugerida al cambiar orden o formato en "Nueva inspección"
  useEffect(() => {
    if (!nuevaInspOpen) return;
    const ord = ordenesTrabajo.find((o) => o.id === selOrdenId);
    const sug = resolverPlantillaSugerida(ord, plantillasActivas, selFormato);
    setSelPlantillaId(sug?.id || '');
    setYaExisteId(null);
  }, [selOrdenId, selFormato, nuevaInspOpen, plantillasActivas, ordenesTrabajo]);

  const inspeccionesFiltradas = useMemo(() => {
    return inspecciones.filter((i) => {
      if (filtroFormato !== 'todos' && i.formato !== filtroFormato) return false;
      if (filtroEstado !== 'todos' && i.estado !== filtroEstado) return false;
      if (filtroLinea !== 'todas') {
        const lineaDeOrden = lineasProducto.find((l) => l.id === i.orden?.linea_producto_id);
        if (lineaDeOrden?.clave !== filtroLinea) return false;
      }
      if (soloNoConformes && !(i.resumen?.no_conformes > 0)) return false;
      return true;
    });
  }, [inspecciones, filtroFormato, filtroEstado, filtroLinea, soloNoConformes, lineasProducto]);

  const lineasDisponibles = useMemo(() => {
    const mapa = new Map<string, string>();
    for (const l of lineasProducto) {
      if (l?.clave) mapa.set(l.clave, l.nombre || l.clave);
    }
    for (const p of plantillas) {
      if (p.linea?.clave) mapa.set(p.linea.clave, p.linea.nombre || p.linea.clave);
    }
    if (!mapa.has('cama_baja')) mapa.set('cama_baja', 'Cama baja');
    return Array.from(mapa.entries()).map(([clave, nombre]) => ({ clave, nombre }));
  }, [lineasProducto, plantillas]);

  const handleCrearInspeccion = async () => {
    if (!selOrdenId) {
      toast.error('Selecciona un equipo / orden de trabajo.');
      return;
    }
    setCreandoInsp(true);
    setYaExisteId(null);
    try {
      const creada = await calidadApi.crearInspeccion({
        orden_trabajo_id: selOrdenId,
        formato: selFormato,
        plantilla_id: selPlantillaId || null,
      });
      setNuevaInspOpen(false);
      toast.success(`Inspección ${creada.inspeccion.folio} creada`);
      await cargarTodo();
      setInspeccionAbiertaId(creada.inspeccion.id);
    } catch (e: any) {
      if (e instanceof CalidadApiError && e.codigo === 'YA_EXISTE' && e.inspeccionId) {
        setYaExisteId(e.inspeccionId);
      } else {
        toast.error(e.message || 'No se pudo crear la inspección');
      }
    } finally {
      setCreandoInsp(false);
    }
  };

  const abrirModalDuplicar = (pl: PlantillaCalidad) => {
    setDuplicarDe(pl);
    setPlNombre(`${pl.nombre} (copia)`);
    setPlLineaClave(pl.linea?.clave || 'dolly');
    setPlFormato(pl.formato);
    setNuevaPlOpen(true);
  };

  const abrirModalNuevaPlantilla = () => {
    setDuplicarDe(null);
    setPlNombre('');
    setPlLineaClave('dolly');
    setPlFormato('control_total');
    setNuevaPlOpen(true);
  };

  const handleCrearPlantilla = async () => {
    if (!plNombre.trim()) {
      toast.error('Escribe un nombre para la plantilla.');
      return;
    }
    setCreandoPl(true);
    try {
      const creada = await calidadApi.crearPlantilla({
        formato: plFormato,
        linea_clave: plLineaClave,
        nombre: plNombre.trim(),
        duplicar_de: duplicarDe?.id,
      });
      setNuevaPlOpen(false);
      toast.success(`Borrador "${creada.nombre}" creado`);
      await cargarTodo();
      setEditorPlantillaId(creada.id);
    } catch (e: any) {
      toast.error(e.message || 'No se pudo crear la plantilla');
    } finally {
      setCreandoPl(false);
    }
  };

  const handleNuevaVersion = async (pl: PlantillaCalidad) => {
    try {
      const borrador = await calidadApi.nuevaVersionPlantilla(pl.id);
      toast.success(`Borrador v${borrador.version} creado`);
      await cargarTodo();
      setEditorPlantillaId(borrador.id);
    } catch (e: any) {
      toast.error(e.message || 'No se pudo crear nueva versión');
    }
  };

  const ejecutarAccionPlantilla = async () => {
    if (!confirmAccionPl) return;
    setEjecutandoPl(true);
    try {
      const { tipo, plantilla } = confirmAccionPl;
      if (tipo === 'eliminar') {
        await calidadApi.eliminarPlantilla(plantilla.id);
        toast.success('Borrador eliminado');
      } else {
        await calidadApi.publicarPlantilla(plantilla.id);
        toast.success(
          tipo === 'restaurar'
            ? `Versión v${plantilla.version} restaurada como activa`
            : `Plantilla v${plantilla.version} publicada como activa`,
        );
      }
      setConfirmAccionPl(null);
      await cargarTodo();
    } catch (e: any) {
      toast.error(e.message || 'No se pudo completar la acción');
    } finally {
      setEjecutandoPl(false);
    }
  };

  const opcionesPlantillaModal = plantillasActivas.filter((p) => p.formato === selFormato);

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-foreground flex items-center gap-2">
            <ClipboardCheck className="h-6 w-6 text-primary" />
            Calidad
          </h1>
          <p className="text-sm text-muted-foreground">
            Inspecciones de proceso y entrega por equipo, impresión en formato carta y editor de plantillas.
          </p>
        </div>

        <div className="flex items-center gap-2">
          {tab === 'inspecciones' ? (
            <Button onClick={() => setNuevaInspOpen(true)}>
              <Plus className="h-4 w-4 mr-1.5" /> Nueva inspección
            </Button>
          ) : (
            <Button onClick={abrirModalNuevaPlantilla}>
              <FilePlus className="h-4 w-4 mr-1.5" /> Nueva plantilla
            </Button>
          )}
        </div>
      </div>

      <Tabs value={tab} onValueChange={(v) => setTab(v as any)}>
        <TabsList>
          <TabsTrigger value="inspecciones">Inspecciones ({inspecciones.length})</TabsTrigger>
          <TabsTrigger value="plantillas">Plantillas ({plantillas.length})</TabsTrigger>
        </TabsList>

        {/* PESTAÑA INSPECCIONES */}
        <TabsContent value="inspecciones" className="space-y-4 mt-4">
          <Card className="bg-card border-border">
            <CardContent className="pt-4">
              <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3 items-end">
                <div>
                  <Label className="text-xs">Formato</Label>
                  <Select value={filtroFormato} onValueChange={setFiltroFormato}>
                    <SelectTrigger className="h-9 text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="todos">Todos los formatos</SelectItem>
                      <SelectItem value="control_total">Control total</SelectItem>
                      <SelectItem value="entrega">Entrega</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-xs">Estado</Label>
                  <Select value={filtroEstado} onValueChange={setFiltroEstado}>
                    <SelectTrigger className="h-9 text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="todos">Todos los estados</SelectItem>
                      <SelectItem value="en_proceso">En proceso</SelectItem>
                      <SelectItem value="cerrada">Cerrada</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div>
                  <Label className="text-xs">Línea</Label>
                  <Select value={filtroLinea} onValueChange={setFiltroLinea}>
                    <SelectTrigger className="h-9 text-xs">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="todas">Todas las líneas</SelectItem>
                      {lineasDisponibles.map((l) => (
                        <SelectItem key={l.clave} value={l.clave}>{l.nombre}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="flex items-center gap-2 h-9">
                  <input
                    id="chk-no-conf"
                    type="checkbox"
                    checked={soloNoConformes}
                    onChange={(e) => setSoloNoConformes(e.target.checked)}
                    className="h-4 w-4 accent-primary"
                  />
                  <Label htmlFor="chk-no-conf" className="text-xs cursor-pointer">
                    Solo con no conformes
                  </Label>
                </div>
              </div>
            </CardContent>
          </Card>

          <Card className="bg-card border-border">
            <CardContent className="p-0 overflow-x-auto">
              {loading ? (
                <div className="flex items-center justify-center py-12 text-muted-foreground">
                  <Loader2 className="h-5 w-5 animate-spin mr-2" /> Cargando inspecciones...
                </div>
              ) : inspeccionesFiltradas.length === 0 ? (
                <div className="text-center py-12 text-sm text-muted-foreground">
                  No hay inspecciones que coincidan con los filtros.
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Folio</TableHead>
                      <TableHead>Formato</TableHead>
                      <TableHead>Equipo / Modelo</TableHead>
                      <TableHead>Progreso</TableHead>
                      <TableHead>No conformes</TableHead>
                      <TableHead>Estado</TableHead>
                      <TableHead>Fechas</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {inspeccionesFiltradas.map((insp) => (
                      <TableRow key={insp.id}>
                        <TableCell className="font-mono font-semibold text-xs">
                          {insp.folio}
                          {insp.intento > 1 ? ` (v${insp.intento})` : ''}
                        </TableCell>
                        <TableCell className="text-xs">
                          {insp.formato === 'control_total' ? 'Control Total' : 'Entrega'}
                        </TableCell>
                        <TableCell className="text-xs">
                          <div className="font-medium text-foreground">
                            {insp.orden?.etiqueta || insp.orden?.modelo || 'Orden'}
                          </div>
                          {insp.orden?.niv && (
                            <div className="text-muted-foreground font-mono text-[11px]">
                              NIV: {insp.orden.niv}
                            </div>
                          )}
                        </TableCell>
                        <TableCell className="text-xs">
                          {insp.resumen ? `${insp.resumen.capturados} / ${insp.resumen.total}` : '—'}
                        </TableCell>
                        <TableCell>
                          {insp.resumen?.no_conformes > 0 ? (
                            <Badge className="bg-destructive/15 text-destructive border-destructive/30">
                              {insp.resumen.no_conformes}
                            </Badge>
                          ) : (
                            <span className="text-xs text-muted-foreground">0</span>
                          )}
                        </TableCell>
                        <TableCell>
                          <Badge
                            className={
                              insp.estado === 'cerrada'
                                ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                                : 'bg-blue-500/15 text-blue-600 border-blue-500/30'
                            }
                          >
                            {insp.estado === 'cerrada' ? 'Cerrada' : 'En proceso'}
                          </Badge>
                        </TableCell>
                        <TableCell className="text-xs text-muted-foreground">
                          <div>Inicio: {insp.fecha_inicio || '—'}</div>
                          {insp.fecha_liberacion && <div>Lib.: {insp.fecha_liberacion}</div>}
                        </TableCell>
                        <TableCell className="text-right">
                          <Button size="sm" variant="outline" onClick={() => setInspeccionAbiertaId(insp.id)}>
                            Abrir
                          </Button>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>

        {/* PESTAÑA PLANTILLAS */}
        <TabsContent value="plantillas" className="space-y-4 mt-4">
          <Card className="bg-card border-border">
            <CardContent className="p-0 overflow-x-auto">
              {loading ? (
                <div className="flex items-center justify-center py-12 text-muted-foreground">
                  <Loader2 className="h-5 w-5 animate-spin mr-2" /> Cargando plantillas...
                </div>
              ) : (
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nombre</TableHead>
                      <TableHead>Línea</TableHead>
                      <TableHead>Formato</TableHead>
                      <TableHead>Versión</TableHead>
                      <TableHead>Estado</TableHead>
                      <TableHead>Unidades</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {plantillas.map((pl) => {
                      const cfg = normalizarConfigPlantilla(pl.config);
                      return (
                        <TableRow key={pl.id}>
                          <TableCell className="font-medium text-sm">
                            {pl.nombre}
                            {pl.revision_formato && (
                              <span className="block text-[11px] text-muted-foreground">
                                {pl.revision_formato} {pl.fecha_revision_formato ? `(${pl.fecha_revision_formato})` : ''}
                              </span>
                            )}
                          </TableCell>
                          <TableCell className="text-xs">{pl.linea?.nombre || '—'}</TableCell>
                          <TableCell className="text-xs">
                            {pl.formato === 'control_total' ? 'Control Total' : 'Entrega'}
                          </TableCell>
                          <TableCell className="font-mono text-xs">v{pl.version}</TableCell>
                          <TableCell>
                            <Badge
                              className={
                                pl.estado === 'activa'
                                  ? 'bg-emerald-500/15 text-emerald-600 border-emerald-500/30'
                                  : pl.estado === 'borrador'
                                    ? 'bg-amber-500/15 text-amber-600 border-amber-500/30'
                                    : 'bg-muted text-muted-foreground border-border'
                              }
                            >
                              {pl.estado}
                            </Badge>
                          </TableCell>
                          <TableCell className="text-xs text-muted-foreground">
                            {cfg.unidades.join(', ')}
                          </TableCell>
                          <TableCell className="text-right">
                            <div className="flex flex-wrap justify-end gap-1.5">
                              {pl.estado === 'borrador' && (
                                <>
                                  <Button
                                    size="sm"
                                    variant="outline"
                                    onClick={() => setEditorPlantillaId(pl.id)}
                                  >
                                    <Edit className="h-3.5 w-3.5 mr-1" /> Editar
                                  </Button>
                                  <Button
                                    size="sm"
                                    onClick={() => setConfirmAccionPl({ tipo: 'publicar', plantilla: pl })}
                                  >
                                    <Upload className="h-3.5 w-3.5 mr-1" /> Publicar
                                  </Button>
                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    className="text-destructive"
                                    onClick={() => setConfirmAccionPl({ tipo: 'eliminar', plantilla: pl })}
                                  >
                                    <Trash2 className="h-3.5 w-3.5" />
                                  </Button>
                                </>
                              )}
                              {pl.estado !== 'borrador' && (
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => handleNuevaVersion(pl)}
                                >
                                  <Plus className="h-3.5 w-3.5 mr-1" /> Nueva versión
                                </Button>
                              )}
                              {pl.estado === 'archivada' && (
                                <Button
                                  size="sm"
                                  variant="outline"
                                  onClick={() => setConfirmAccionPl({ tipo: 'restaurar', plantilla: pl })}
                                >
                                  <RotateCcw className="h-3.5 w-3.5 mr-1" /> Restaurar esta versión
                                </Button>
                              )}
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => abrirModalDuplicar(pl)}
                                title="Duplicar a otra línea o formato"
                              >
                                <Copy className="h-3.5 w-3.5 mr-1" /> Duplicar
                              </Button>
                            </div>
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              )}
            </CardContent>
          </Card>
        </TabsContent>
      </Tabs>

      {/* Diálogo: Nueva inspección */}
      <Dialog open={nuevaInspOpen} onOpenChange={setNuevaInspOpen}>
        <DialogContent className="max-w-lg bg-card border-border">
          <DialogHeader>
            <DialogTitle>Nueva inspección de calidad</DialogTitle>
            <DialogDescription>
              Elige el equipo y el formato. El sistema sugiere automáticamente la plantilla activa correspondiente (incluyendo Cama baja para tipo 05).
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3">
            <div>
              <Label className="text-xs">Equipo / Orden de trabajo *</Label>
              <Select value={selOrdenId} onValueChange={setSelOrdenId}>
                <SelectTrigger>
                  <SelectValue placeholder="Selecciona una orden de trabajo" />
                </SelectTrigger>
                <SelectContent>
                  {ordenesTrabajo.map((o) => (
                    <SelectItem key={o.id} value={o.id}>
                      {o.etiqueta || o.modelo || o.nomenclatura_id}
                      {o.niv ? ` (${o.niv})` : ''}
                    </SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label className="text-xs">Formato *</Label>
              <Select value={selFormato} onValueChange={(v) => setSelFormato(v as FormatoCalidad)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="control_total">Control de calidad total (en proceso)</SelectItem>
                  <SelectItem value="entrega">Calidad de entrega al cliente</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div>
              <Label className="text-xs">Plantilla activa a utilizar</Label>
              {opcionesPlantillaModal.length === 0 ? (
                <p className="text-xs text-amber-600 mt-1">
                  No hay plantillas activas para este formato. Créala en la pestaña Plantillas.
                </p>
              ) : (
                <Select value={selPlantillaId} onValueChange={setSelPlantillaId}>
                  <SelectTrigger>
                    <SelectValue placeholder="Selecciona una plantilla activa" />
                  </SelectTrigger>
                  <SelectContent>
                    {opcionesPlantillaModal.map((p) => (
                      <SelectItem key={p.id} value={p.id}>
                        {p.nombre} ({p.linea?.nombre || 'Línea'} · v{p.version})
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </div>

            {yaExisteId && (
              <div className="p-3 rounded-md bg-amber-500/10 border border-amber-500/30 text-xs flex items-center justify-between gap-2">
                <span>Ya existe una inspección en proceso para este equipo y formato.</span>
                <Button
                  size="sm"
                  onClick={() => {
                    setNuevaInspOpen(false);
                    setInspeccionAbiertaId(yaExisteId);
                  }}
                >
                  Abrir la que ya existe
                </Button>
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setNuevaInspOpen(false)} disabled={creandoInsp}>
              Cancelar
            </Button>
            <Button onClick={handleCrearInspeccion} disabled={creandoInsp || !selOrdenId}>
              {creandoInsp ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : null}
              Iniciar inspección
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo: Nueva / Duplicar plantilla */}
      <Dialog open={nuevaPlOpen} onOpenChange={setNuevaPlOpen}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle>
              {duplicarDe ? `Duplicar "${duplicarDe.nombre}"` : 'Nueva plantilla de calidad'}
            </DialogTitle>
            <DialogDescription>
              Se creará como borrador editable para que ajustes grupos y actividades antes de publicarla.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3">
            <div>
              <Label className="text-xs">Nombre *</Label>
              <Input
                value={plNombre}
                onChange={(e) => setPlNombre(e.target.value)}
                placeholder="Ej. Control de calidad total — Dolly"
              />
            </div>
            <div>
              <Label className="text-xs">Línea destino *</Label>
              <Select value={plLineaClave} onValueChange={setPlLineaClave}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {lineasDisponibles.map((l) => (
                    <SelectItem key={l.clave} value={l.clave}>{l.nombre}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>
            <div>
              <Label className="text-xs">Formato *</Label>
              <Select value={plFormato} onValueChange={(v) => setPlFormato(v as FormatoCalidad)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="control_total">Control total</SelectItem>
                  <SelectItem value="entrega">Entrega</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setNuevaPlOpen(false)} disabled={creandoPl}>
              Cancelar
            </Button>
            <Button onClick={handleCrearPlantilla} disabled={creandoPl}>
              {creandoPl ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : null}
              Crear borrador
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmación Publicar / Restaurar / Eliminar plantilla */}
      <Dialog open={Boolean(confirmAccionPl)} onOpenChange={(v) => { if (!v) setConfirmAccionPl(null); }}>
        <DialogContent className="max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle>
              {confirmAccionPl?.tipo === 'eliminar'
                ? 'Eliminar borrador'
                : confirmAccionPl?.tipo === 'restaurar'
                  ? `Restaurar versión v${confirmAccionPl.plantilla.version}`
                  : `Publicar versión v${confirmAccionPl?.plantilla.version}`}
            </DialogTitle>
            <DialogDescription>
              {confirmAccionPl?.tipo === 'eliminar'
                ? `¿Seguro que deseas eliminar "${confirmAccionPl.plantilla.nombre}"?`
                : 'La versión activa anterior quedará archivada. Las inspecciones ya hechas conservarán exactamente su plantilla original.'}
            </DialogDescription>
          </DialogHeader>
          <DialogFooter>
            <Button variant="outline" onClick={() => setConfirmAccionPl(null)} disabled={ejecutandoPl}>
              Cancelar
            </Button>
            <Button
              variant={confirmAccionPl?.tipo === 'eliminar' ? 'destructive' : 'default'}
              onClick={ejecutarAccionPlantilla}
              disabled={ejecutandoPl}
            >
              {ejecutandoPl ? <Loader2 className="h-4 w-4 animate-spin mr-1.5" /> : null}
              Confirmar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modales de inspección y editor */}
      <CalidadInspeccionModal
        inspeccionId={inspeccionAbiertaId}
        open={Boolean(inspeccionAbiertaId)}
        ajustes={ajustes}
        onClose={() => setInspeccionAbiertaId(null)}
        onActualizado={cargarTodo}
        onAbrirInspeccion={(nuevoId) => setInspeccionAbiertaId(nuevoId)}
      />

      <CalidadPlantillaEditorModal
        plantillaId={editorPlantillaId}
        open={Boolean(editorPlantillaId)}
        ajustes={ajustes}
        onClose={() => setEditorPlantillaId(null)}
        onGuardado={cargarTodo}
      />
    </div>
  );
}
