import { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  Download,
  Search,
  ChevronDown,
  ChevronUp,
  Package,
  Layers,
  HelpCircle,
  FileSpreadsheet,
  AlertCircle
} from 'lucide-react';
import {
  BomEquipoResumen,
  contarPiezasDistintas,
  consolidarDespiece,
  agruparLineasEquipo,
  filtrarLineas,
  formatearCantidad,
  formatearOrigen,
  generarCsvDespiece
} from '../../utils/despiece';

interface Props {
  meta?: any;
  folio?: string;
}

export function PresupuestoDespieceTab({ meta, folio }: Props) {
  const bom: BomEquipoResumen[] = useMemo(() => {
    return Array.isArray(meta?.bom) ? meta.bom : [];
  }, [meta]);

  const [tipoAgrupacion, setTipoAgrupacion] = useState<'seccion' | 'paso'>('seccion');
  const [busqueda, setBusqueda] = useState('');
  const [equiposAbiertos, setEquiposAbiertos] = useState<Record<number, boolean>>({});
  const [consolidadoAbierto, setConsolidadoAbierto] = useState(true);
  const [pendientesAbierto, setPendientesAbierto] = useState(false);

  // Si no hay BOM, mostrar aviso requerido
  if (!bom || bom.length === 0) {
    return (
      <div className="p-8 rounded-lg border border-amber-500/30 bg-amber-500/10 text-center space-y-3">
        <AlertCircle className="mx-auto h-8 w-8 text-amber-600 dark:text-amber-400" />
        <h3 className="text-base font-semibold text-foreground">Despiece no disponible</h3>
        <p className="text-sm text-muted-foreground max-w-lg mx-auto">
          Este presupuesto se generó antes del despiece. Vuelve a generarlo desde la cotización para incluirlo.
        </p>
      </div>
    );
  }

  const toggleEquipo = (idx: number) => {
    setEquiposAbiertos(prev => ({
      ...prev,
      [idx]: prev[idx] !== undefined ? !prev[idx] : false // default abierto si undefined
    }));
  };

  const isEquipoAbierto = (idx: number) => {
    return equiposAbiertos[idx] !== undefined ? equiposAbiertos[idx] : true;
  };

  const numPiezasDistintas = useMemo(() => contarPiezasDistintas(bom), [bom]);
  const consolidadoCompleto = useMemo(() => consolidarDespiece(bom), [bom]);

  const consolidadoFiltrado = useMemo(() => {
    if (!busqueda.trim()) return consolidadoCompleto;
    const q = busqueda.trim().toLowerCase();
    return consolidadoCompleto.filter(
      p => p.nombre.toLowerCase().includes(q) || p.material_id.toLowerCase().includes(q)
    );
  }, [consolidadoCompleto, busqueda]);

  const handleDescargarCsv = () => {
    const csvContent = generarCsvDespiece(bom, { cotizacionFolio: meta?.cotizacion_folio });
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.setAttribute('download', `despiece_${folio || 'presupuesto'}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
    URL.revokeObjectURL(url);
  };

  // Extraer omitidas y alternativas de todos los equipos
  const todosPendientes = useMemo(() => {
    const omitidas: Array<{ equipo: string; descripcion: string; texto: string }> = [];
    const alternativas: Array<{ equipo: string; reemplaza: string | null; posibles_reemplazos: string[]; sustituto: string; grupo: string }> = [];

    for (const eq of bom) {
      for (const o of eq.omitidas || []) {
        omitidas.push({ equipo: eq.descripcion, ...o });
      }
      for (const a of eq.alternativas || []) {
        alternativas.push({ equipo: eq.descripcion, ...a });
      }
    }
    return { omitidas, alternativas, total: omitidas.length + alternativas.length };
  }, [bom]);

  const fechaFormateada = meta?.generado_en ? new Date(meta.generado_en).toLocaleString() : '';

  return (
    <div className="space-y-6">
      {/* Encabezado del despiece */}
      <Card className="bg-card border-border">
        <CardContent className="pt-6">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="space-y-1">
              <div className="flex items-center gap-2">
                <Package className="h-5 w-5 text-primary" />
                <h3 className="text-lg font-bold text-foreground">Despiece de Fabricación</h3>
              </div>
              <p className="text-xs text-muted-foreground">
                {meta?.cotizacion_folio ? (
                  <>
                    Origen: <span className="font-semibold text-foreground">Cotización {meta.cotizacion_folio}</span>
                    {fechaFormateada ? ` · generado ${fechaFormateada}` : ''}
                  </>
                ) : (
                  fechaFormateada ? `Generado ${fechaFormateada}` : 'Generado desde costeo'
                )}
                {' · '}
                <span className="font-medium text-foreground">{bom.length} {bom.length === 1 ? 'equipo' : 'equipos'}</span>
                {' · '}
                <span className="font-medium text-foreground">{numPiezasDistintas} piezas distintas</span>
              </p>
            </div>

            <Button
              variant="outline"
              size="sm"
              onClick={handleDescargarCsv}
              className="gap-2 shrink-0 border-border hover:bg-muted"
            >
              <FileSpreadsheet className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
              <span>Descargar despiece (CSV)</span>
              <Download className="h-3.5 w-3.5 opacity-60" />
            </Button>
          </div>

          {/* Barra de herramientas / filtros */}
          <div className="mt-4 pt-4 border-t border-border flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
            <div className="relative flex-1">
              <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar pieza, código o sección..."
                value={busqueda}
                onChange={e => setBusqueda(e.target.value)}
                className="pl-9 h-9 text-xs bg-background"
              />
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <span className="text-xs text-muted-foreground whitespace-nowrap">Agrupar por:</span>
              <Select
                value={tipoAgrupacion}
                onValueChange={(val: 'seccion' | 'paso') => setTipoAgrupacion(val)}
              >
                <SelectTrigger className="h-9 w-36 text-xs bg-background">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="seccion">Sección</SelectItem>
                  <SelectItem value="paso">Paso / kit</SelectItem>
                </SelectContent>
              </Select>
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Tarjetas por cada equipo del BOM */}
      <div className="space-y-4">
        {bom.map((equipo, eqIdx) => {
          const abierto = isEquipoAbierto(eqIdx);
          const lineasFiltradas = filtrarLineas(equipo.lineas || [], busqueda);
          const grupos = agruparLineasEquipo(lineasFiltradas, tipoAgrupacion);
          const cantEq = Number(equipo.cantidad) > 0 ? Number(equipo.cantidad) : 1;

          return (
            <Card key={eqIdx} className="border-border bg-card overflow-hidden">
              <div
                className="px-4 py-3 bg-muted/60 border-b border-border flex items-center justify-between cursor-pointer select-none hover:bg-muted transition-colors"
                onClick={() => toggleEquipo(eqIdx)}
              >
                <div className="flex items-center gap-3">
                  <Layers className="h-4 w-4 text-primary shrink-0" />
                  <div>
                    <h4 className="text-sm font-bold text-foreground">
                      {equipo.descripcion}
                    </h4>
                    <span className="text-xs text-muted-foreground">
                      {cantEq} {cantEq === 1 ? 'unidad' : 'unidades'} · {lineasFiltradas.length} piezas
                      {busqueda.trim() && lineasFiltradas.length !== (equipo.lineas || []).length && (
                        ` (filtradas de ${equipo.lineas?.length || 0})`
                      )}
                    </span>
                  </div>
                </div>
                <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
                  {abierto ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
                </Button>
              </div>

              {abierto && (
                <CardContent className="p-0">
                  {Object.keys(grupos).length === 0 ? (
                    <div className="p-6 text-center text-xs text-muted-foreground italic">
                      No se encontraron piezas con el filtro actual.
                    </div>
                  ) : (
                    <div className="divide-y divide-border">
                      {Object.entries(grupos).map(([nombreGrupo, lineasGrupo]) => (
                        <div key={nombreGrupo} className="p-3">
                          <div className="mb-2 flex items-center justify-between">
                            <span className="text-xs font-semibold text-primary uppercase tracking-wider">
                              {tipoAgrupacion === 'paso' ? `Paso / kit: ${nombreGrupo}` : `Sección: ${nombreGrupo}`}
                            </span>
                            <span className="text-[11px] text-muted-foreground">
                              {lineasGrupo.length} {lineasGrupo.length === 1 ? 'pieza' : 'piezas'}
                            </span>
                          </div>

                          {/* Tabla responsiva que hace scroll horizontal en móvil sin romper el viewport */}
                          <div className="w-full overflow-x-auto rounded border border-border/70">
                            <table className="w-full text-xs min-w-[620px]">
                              <thead className="bg-muted/40 border-b border-border text-muted-foreground">
                                <tr>
                                  <th className="text-left p-2 font-medium">PIEZA</th>
                                  <th className="text-center p-2 w-20 font-medium">UNIDAD</th>
                                  <th className="text-right p-2 w-24 font-medium">POR EQUIPO</th>
                                  <th className="text-right p-2 w-28 font-medium">TOTAL ({cantEq > 1 ? `×${cantEq}` : 'TOTAL'})</th>
                                  <th className="text-left p-2 w-40 font-medium">ORIGEN</th>
                                </tr>
                              </thead>
                              <tbody className="divide-y divide-border/60">
                                {lineasGrupo.map((linea, lIdx) => {
                                  const totalPiezas = (Number(linea.cantidad) || 0) * cantEq;
                                  return (
                                    <tr key={lIdx} className="hover:bg-muted/20 transition-colors">
                                      <td className="p-2 font-medium text-foreground">
                                        <div className="leading-tight">{linea.nombre}</div>
                                        {linea.material_id && (
                                          <div className="text-[10px] text-muted-foreground font-mono mt-0.5">
                                            {linea.material_id}
                                          </div>
                                        )}
                                      </td>
                                      <td className="p-2 text-center text-muted-foreground uppercase">
                                        {linea.unidad || 'PZA'}
                                      </td>
                                      <td className="p-2 text-right font-mono text-foreground">
                                        {formatearCantidad(linea.cantidad)}
                                      </td>
                                      <td className="p-2 text-right font-mono font-semibold text-foreground">
                                        {formatearCantidad(totalPiezas)}
                                      </td>
                                      <td className="p-2 text-left text-[11px] text-muted-foreground">
                                        <span className="inline-block px-1.5 py-0.5 rounded bg-muted border border-border/80">
                                          {formatearOrigen(linea.origen)}
                                        </span>
                                      </td>
                                    </tr>
                                  );
                                })}
                              </tbody>
                            </table>
                          </div>
                        </div>
                      ))}
                    </div>
                  )}
                </CardContent>
              )}
            </Card>
          );
        })}
      </div>

      {/* Bloque Consolidado */}
      <Card className="border-border bg-card">
        <div
          className="px-4 py-3 bg-muted/60 border-b border-border flex items-center justify-between cursor-pointer select-none hover:bg-muted transition-colors"
          onClick={() => setConsolidadoAbierto(!consolidadoAbierto)}
        >
          <div className="flex items-center gap-2.5">
            <Package className="h-4 w-4 text-emerald-600 dark:text-emerald-400" />
            <span className="text-sm font-bold text-foreground">Consolidado Total de Materiales</span>
            <span className="text-xs text-muted-foreground">
              ({consolidadoFiltrado.length} piezas distintas · base para requisición)
            </span>
          </div>
          <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
            {consolidadoAbierto ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
          </Button>
        </div>

        {consolidadoAbierto && (
          <CardContent className="p-0">
            <div className="w-full overflow-x-auto">
              <table className="w-full text-xs min-w-[500px]">
                <thead className="bg-muted/40 border-b border-border text-muted-foreground">
                  <tr>
                    <th className="text-left p-2 font-medium">PIEZA CONSOLIDADA</th>
                    <th className="text-center p-2 w-24 font-medium">UNIDAD</th>
                    <th className="text-right p-2 w-32 font-medium">CANTIDAD TOTAL</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border/60">
                  {consolidadoFiltrado.map((p, idx) => (
                    <tr key={idx} className="hover:bg-muted/20 transition-colors">
                      <td className="p-2 font-medium text-foreground">
                        <div className="leading-tight">{p.nombre}</div>
                        {p.material_id && (
                          <div className="text-[10px] text-muted-foreground font-mono mt-0.5">
                            {p.material_id}
                          </div>
                        )}
                      </td>
                      <td className="p-2 text-center text-muted-foreground uppercase">
                        {p.unidad}
                      </td>
                      <td className="p-2 text-right font-mono font-bold text-foreground">
                        {formatearCantidad(p.cantidad_total)}
                      </td>
                    </tr>
                  ))}
                  {consolidadoFiltrado.length === 0 && (
                    <tr>
                      <td colSpan={3} className="p-6 text-center text-xs text-muted-foreground italic">
                        No hay piezas en el consolidado con el filtro actual.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </CardContent>
        )}
      </Card>

      {/* Sección "Pendientes de definir" (plegada por defecto) */}
      {todosPendientes.total > 0 && (
        <Card className="border-border bg-card">
          <div
            className="px-4 py-3 bg-muted/60 border-b border-border flex items-center justify-between cursor-pointer select-none hover:bg-muted transition-colors"
            onClick={() => setPendientesAbierto(!pendientesAbierto)}
          >
            <div className="flex items-center gap-2.5">
              <HelpCircle className="h-4 w-4 text-amber-500" />
              <span className="text-sm font-bold text-foreground">Pendientes de definir</span>
              <span className="text-xs px-2 py-0.5 rounded bg-amber-500/20 text-amber-700 dark:text-amber-300 font-semibold border border-amber-500/30">
                {todosPendientes.total} {todosPendientes.total === 1 ? 'partida' : 'partidas'}
              </span>
            </div>
            <Button variant="ghost" size="sm" className="h-8 w-8 p-0">
              {pendientesAbierto ? <ChevronUp className="h-4 w-4" /> : <ChevronDown className="h-4 w-4" />}
            </Button>
          </div>

          {pendientesAbierto && (
            <CardContent className="p-4 space-y-4 text-xs">
              {todosPendientes.omitidas.length > 0 && (
                <div className="space-y-2">
                  <h5 className="font-semibold text-foreground">Líneas omitidas por condición o regla:</h5>
                  <ul className="space-y-1 list-disc list-inside text-muted-foreground">
                    {todosPendientes.omitidas.map((o, idx) => (
                      <li key={idx}>
                        <span className="font-medium text-foreground">{o.equipo}</span>: {o.descripcion} ({o.texto})
                      </li>
                    ))}
                  </ul>
                </div>
              )}

              {todosPendientes.alternativas.length > 0 && (
                <div className="space-y-2">
                  <h5 className="font-semibold text-foreground">Posibles alternativas o reemplazos:</h5>
                  <ul className="space-y-1 list-disc list-inside text-muted-foreground">
                    {todosPendientes.alternativas.map((a, idx) => (
                      <li key={idx}>
                        <span className="font-medium text-foreground">{a.equipo}</span> ({a.grupo}): {a.sustituto} reemplaza a {a.reemplaza || 'base'}
                      </li>
                    ))}
                  </ul>
                </div>
              )}
            </CardContent>
          )}
        </Card>
      )}
    </div>
  );
}
