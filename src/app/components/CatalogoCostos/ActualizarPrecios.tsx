import React, { useState, useEffect, useMemo, useRef } from 'react';
import * as XLSX from 'xlsx';
import {
  FileSpreadsheet,
  Upload,
  Download,
  ArrowRight,
  ArrowLeft,
  Check,
  AlertTriangle,
  AlertCircle,
  RefreshCw,
  Undo2,
  Percent,
  Search,
  Filter,
  Loader2,
  Eye,
  CheckCircle2,
  XCircle,
  ShieldAlert,
  History,
  Layers,
  HelpCircle,
} from 'lucide-react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Badge } from '../ui/badge';
import { Checkbox } from '../ui/checkbox';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '../ui/dialog';
import {
  Table,
  TableHeader,
  TableRow,
  TableHead,
  TableBody,
  TableCell,
} from '../ui/table';
import { toast } from 'sonner';
import { supabase } from '../../utils/supabase/client';
import { BASE_URL } from '../../utils/api';
import { formatearMoneda } from '../../utils/catalogoCostos';
import {
  calcularNuevoPrecio,
  filasDesdeHoja,
  analizarLote,
  FuentePrecios,
  ModoAjuste,
  TipoRedondeo,
  FilaLoteAnalizada,
  ResumenLote,
} from '../../utils/preciosLote';

interface ActualizarPreciosProps {
  canEdit?: boolean;
  onPreciosActualizados?: () => void;
}

interface ItemCatalogoExportado {
  fuente: FuentePrecios;
  id: string;
  descripcion: string;
  contexto: string;
  unidad: string;
  precio_actual: number | null;
  incluye_iva?: boolean;
}

interface LoteHistorial {
  id: string;
  usuario_id: string;
  usuario_email?: string;
  origen: string;
  descripcion: string;
  creado_el: string;
  total_cambios: number;
  revertido_el: string | null;
  revertido_por: string | null;
  lote_origen_id: string | null;
}

export function ActualizarPrecios({ canEdit = true, onPreciosActualizados }: ActualizarPreciosProps) {
  // --- PASOS DEL FLUJO: 1 = Elegir, 2 = Revisar, 3 = Aplicar ---
  const [paso, setPaso] = useState<1 | 2 | 3>(1);

  // --- PASO 1: SELECCIÓN Y FILTROS ---
  const [fuente, setFuente] = useState<FuentePrecios>('productos');
  const [itemsCatalogo, setItemsCatalogo] = useState<ItemCatalogoExportado[]>([]);
  const [cargandoItems, setCargandoItems] = useState(false);
  const [busqueda, setBusqueda] = useState('');
  const [tipoModeloFiltro, setTipoModeloFiltro] = useState<string>('todos');
  const [soloSinPrecio, setSoloSinPrecio] = useState(false);

  // Casillas de selección en la tabla del Paso 1
  const [seleccionados, setSeleccionados] = useState<Set<string>>(new Set());

  // Parámetros de Ajuste por fórmula
  const [modoAjuste, setModoAjuste] = useState<ModoAjuste>('porcentaje');
  const [valorAjuste, setValorAjuste] = useState<string>('10');
  const [redondeoAjuste, setRedondeoAjuste] = useState<TipoRedondeo>('centavos');

  // Input de archivo Excel / CSV
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [origenLote, setOrigenLote] = useState<'excel' | 'porcentaje' | 'manual'>('porcentaje');

  // --- PASO 2: REVISIÓN DE CAMBIOS (DIFF) ---
  const [filasDiff, setFilasDiff] = useState<FilaLoteAnalizada[]>([]);
  const [resumenDiff, setResumenDiff] = useState<ResumenLote | null>(null);
  const [filtroVistaDiff, setFiltroVistaDiff] = useState<'todos' | 'cambios' | 'alertas' | 'errores'>('todos');
  const [entiendoAlertas, setEntiendoAlertas] = useState(false);
  const [previsualizando, setPrevisualizando] = useState(false);

  // --- PASO 3: APLICAR Y CONFIRMAR ---
  const [descripcionLote, setDescripcionLote] = useState('');
  const [aplicandoLote, setAplicandoLote] = useState(false);
  const [modalConfirmarOpen, setModalConfirmarOpen] = useState(false);
  const [resultadoExito, setResultadoExito] = useState<{ lote_id: string; aplicados: number; omitidos: number } | null>(null);
  const [conflictos409, setConflictos409] = useState<any[] | null>(null);

  // --- PANEL: LOTES ANTERIORES ---
  const [lotes, setLotes] = useState<LoteHistorial[]>([]);
  const [cargandoLotes, setCargandoLotes] = useState(false);
  const [loteDetalleModal, setLoteDetalleModal] = useState<any | null>(null);
  const [cargandoDetalleLote, setCargandoDetalleLote] = useState(false);
  const [loteRevertirModal, setLoteRevertirModal] = useState<LoteHistorial | null>(null);
  const [revirtiendoLote, setRevirtiendoLote] = useState(false);

  // =========================================================================
  // CARGA DE ITEMS POR FUENTE
  // =========================================================================
  const cargarItemsCatalogo = async (fuenteActual: FuentePrecios = fuente) => {
    try {
      setCargandoItems(true);
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const params = new URLSearchParams({
        fuente: fuenteActual,
      });
      if (busqueda.trim()) params.append('q', busqueda.trim());
      if (soloSinPrecio) params.append('solo_sin_precio', 'true');
      if (tipoModeloFiltro && tipoModeloFiltro !== 'todos') {
        params.append('tipo_modelo', tipoModeloFiltro);
      }

      const res = await fetch(`${BASE_URL}/precios/exportar?${params.toString()}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        const err = await res.json().catch(() => ({}));
        throw new Error(err.error || 'Error al obtener catálogo para exportación');
      }

      const json = await res.json();
      const items: ItemCatalogoExportado[] = json.items || [];
      setItemsCatalogo(items);
      setSeleccionados(new Set()); // Reset selección al cambiar de fuente o filtros
    } catch (err: any) {
      console.error('Error cargando catálogo:', err);
      toast.error('Error cargando catálogo', { description: err.message });
    } finally {
      setCargandoItems(false);
    }
  };

  useEffect(() => {
    cargarItemsCatalogo(fuente);
  }, [fuente, soloSinPrecio, tipoModeloFiltro]);

  // Manejar búsqueda con Enter o botón
  const handleBuscar = (e: React.FormEvent) => {
    e.preventDefault();
    cargarItemsCatalogo(fuente);
  };

  // Cargar Lotes Anteriores
  const cargarLotesAnteriores = async () => {
    try {
      setCargandoLotes(true);
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;
      const res = await fetch(`${BASE_URL}/precios/lotes?limite=50`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      if (res.ok) {
        const json = await res.json();
        setLotes(json || []);
      }
    } catch (err) {
      console.error('Error cargando lotes:', err);
    } finally {
      setCargandoLotes(false);
    }
  };

  useEffect(() => {
    cargarLotesAnteriores();
  }, []);

  // =========================================================================
  // SELECCIÓN DE FILAS EN PASO 1
  // =========================================================================
  const toggleSeleccionarTodo = () => {
    if (seleccionados.size === itemsCatalogo.length && itemsCatalogo.length > 0) {
      setSeleccionados(new Set());
    } else {
      setSeleccionados(new Set(itemsCatalogo.map((i) => i.id)));
    }
  };

  const toggleSeleccionarItem = (id: string) => {
    setSeleccionados((prev) => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  };

  // =========================================================================
  // AJUSTE POR FÓRMULA (CAMINO A)
  // =========================================================================
  const handleAjustarFormula = async () => {
    if (seleccionados.size === 0) {
      toast.error('Selecciona al menos un registro para aplicar el ajuste');
      return;
    }

    const valorNum = Number(valorAjuste);
    if (isNaN(valorNum)) {
      toast.error('Ingresa un valor numérico válido para el ajuste');
      return;
    }

    const filasParaAnalizar = itemsCatalogo
      .filter((item) => seleccionados.has(item.id))
      .map((item) => {
        let precioNuevo: number | null = null;
        try {
          const res = calcularNuevoPrecio({
            precioActual: item.precio_actual,
            modo: modoAjuste,
            valor: valorNum,
            redondeo: redondeoAjuste,
          });
          precioNuevo = res.precioNuevo;
        } catch {
          precioNuevo = NaN; // Marcará error en analizarLote
        }

        return {
          id: item.id,
          fuente: item.fuente,
          descripcion: item.descripcion,
          contexto: item.contexto,
          unidad: item.unidad,
          precioActual: item.precio_actual,
          precioNuevo,
        };
      });

    ejecutarPrevisualizacion(filasParaAnalizar, 'porcentaje');
  };

  // =========================================================================
  // EXCEL / CSV (CAMINO B)
  // =========================================================================
  const handleDescargarPlantilla = () => {
    try {
      const filasData = (itemsCatalogo.length > 0 ? itemsCatalogo : []).map((item) => ({
        id: item.id,
        descripcion: item.descripcion,
        contexto: item.contexto,
        unidad: item.unidad,
        precio_actual: item.precio_actual !== null ? Number(item.precio_actual) : '',
        precio_nuevo: '', // vacía para que el usuario escriba
      }));

      const wb = XLSX.utils.book_new();

      // Hoja de Datos
      const wsData = XLSX.utils.json_to_sheet(filasData);
      XLSX.utils.book_append_sheet(wb, wsData, `Precios_${fuente}`);

      // Hoja de Instrucciones
      const instruccionesData = [
        ['INSTRUCCIONES PARA ACTUALIZACIÓN MASIVA DE PRECIOS'],
        [''],
        ['1. NO modifiques ni borres la columna "id" ni agregues IDs inexistentes.'],
        ['2. Escribe el nuevo precio en la columna "precio_nuevo".'],
        ['3. Deja vacía la columna "precio_nuevo" en las filas que NO deseas modificar.'],
        ['4. Formatos aceptados: 1,234.56, $1,234.56, 1 234,56 o números simples.'],
        ['5. No ingreses precios negativos ni textos ambiguos como "1,234" sin decimales.'],
        ['6. Guarda el archivo y súbelo en la pestaña Actualizar Precios.'],
      ];
      const wsInstrucciones = XLSX.utils.aoa_to_sheet(instruccionesData);
      XLSX.utils.book_append_sheet(wb, wsInstrucciones, 'Instrucciones');

      const fechaStr = new Date().toISOString().slice(0, 10);
      XLSX.writeFile(wb, `plantilla_precios_${fuente}_${fechaStr}.xlsx`);
      toast.success('Plantilla descargada correctamente');
    } catch (err: any) {
      console.error('Error generando plantilla Excel:', err);
      toast.error('Error al descargar plantilla', { description: err.message });
    }
  };

  const handleSubirArchivo = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    if (file.size > 2 * 1024 * 1024) {
      toast.error('El archivo excede el tamaño máximo permitido de 2 MB');
      if (fileInputRef.current) fileInputRef.current.value = '';
      return;
    }

    const reader = new FileReader();
    reader.onload = (evt) => {
      try {
        const data = new Uint8Array(evt.target?.result as ArrayBuffer);
        const workbook = XLSX.read(data, { type: 'array' });
        const sheetName = workbook.SheetNames[0];
        const sheet = workbook.Sheets[sheetName];
        const rawJson: any[] = XLSX.utils.sheet_to_json(sheet, { defval: '' });

        if (rawJson.length === 0) {
          toast.error('El archivo no contiene filas con datos');
          return;
        }

        // Convertir filas usando la función pura filasDesdeHoja
        const filasParseadas = filasDesdeHoja(rawJson, fuente);

        // Filtrar solo las que tienen algún dato en precioNuevo (o que intentaron poner precio y dio NaN)
        const conIntencionCambio = filasParseadas.filter(
          (f) => f.precioNuevo !== null && f.precioNuevo !== undefined
        );

        if (conIntencionCambio.length === 0) {
          toast.info('No se detectaron valores en la columna "precio_nuevo". Asegúrate de escribir los precios nuevos antes de subir el archivo.');
          return;
        }

        ejecutarPrevisualizacion(conIntencionCambio, 'excel');
      } catch (err: any) {
        console.error('Error leyendo archivo:', err);
        toast.error('No se pudo leer el archivo Excel o CSV', { description: err.message });
      } finally {
        if (fileInputRef.current) fileInputRef.current.value = '';
      }
    };
    reader.readAsArrayBuffer(file);
  };

  // =========================================================================
  // EJECUTAR PREVISUALIZACIÓN (PASO 2)
  // =========================================================================
  const ejecutarPrevisualizacion = async (
    filasLocales: any[],
    origen: 'excel' | 'porcentaje' | 'manual'
  ) => {
    try {
      setPrevisualizando(true);
      setOrigenLote(origen);
      setEntiendoAlertas(false);

      // 1. Análisis local de errores y alertas con la función pura
      const { resumen, filas: analizadasLocales } = analizarLote({
        filas: filasLocales,
      });

      // 2. Consulta al backend POST /precios/previsualizar para asegurar precios frescos de la base
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const payloadCambios = filasLocales
        .filter((f) => !isNaN(f.precioNuevo) && f.precioNuevo !== null && f.precioNuevo >= 0)
        .map((f) => ({
          fuente: f.fuente,
          id: f.id,
          precio_nuevo: f.precioNuevo,
        }));

      if (payloadCambios.length > 0) {
        const res = await fetch(`${BASE_URL}/precios/previsualizar`, {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            Authorization: `Bearer ${token}`,
          },
          body: JSON.stringify({
            origen,
            cambios: payloadCambios,
          }),
        });

        if (res.ok) {
          const json = await res.json();
          // El backend puede reportar diff y alertas sobre precios frescos
          // Si el backend respondió, enriquecemos las filas locales con el precio_actual fresco
          const mapFrescos = new Map(json.filas?.map((f: any) => [f.id, f]) || []);
          const enriquecidas = analizadasLocales.map((loc) => {
            const fresco = mapFrescos.get(loc.id) as any;
            if (fresco) {
              return {
                ...loc,
                precioActual: fresco.precio_actual,
                delta: fresco.delta,
                deltaPorcentaje: fresco.delta_porcentaje,
                alertas: Array.from(new Set([...loc.alertas, ...(fresco.alertas || [])])),
              };
            }
            return loc;
          });

          setFilasDiff(enriquecidas);
          setResumenDiff(resumen);
          setPaso(2);
          return;
        }
      }

      setFilasDiff(analizadasLocales);
      setResumenDiff(resumen);
      setPaso(2);
    } catch (err: any) {
      console.error('Error previsualizando cambios:', err);
      toast.error('Error al preparar previsualización', { description: err.message });
    } finally {
      setPrevisualizando(false);
    }
  };

  // Filtrado de la tabla de diferencias en el Paso 2
  const filasDiffFiltradas = useMemo(() => {
    if (filtroVistaDiff === 'cambios') {
      return filasDiff.filter((f) => f.estado === 'cambia' || f.estado === 'alerta');
    }
    if (filtroVistaDiff === 'alertas') {
      return filasDiff.filter((f) => f.estado === 'alerta');
    }
    if (filtroVistaDiff === 'errores') {
      return filasDiff.filter((f) => f.estado === 'error');
    }
    return filasDiff;
  }, [filasDiff, filtroVistaDiff]);

  // =========================================================================
  // APLICAR LOTE (PASO 3)
  // =========================================================================
  const handleConfirmarYAplicar = async () => {
    if (!canEdit) {
      toast.error('No tienes permiso para modificar costos');
      return;
    }

    if (!descripcionLote.trim()) {
      toast.error('Debes ingresar una descripción obligatoria para el lote');
      return;
    }

    // Filtrar solo las filas válidas que cambian o tienen alerta aceptada
    const filasValidas = filasDiff.filter(
      (f) => (f.estado === 'cambia' || f.estado === 'alerta') && f.precioNuevo !== null && !isNaN(f.precioNuevo)
    );

    if (filasValidas.length === 0) {
      toast.error('No hay cambios válidos para aplicar');
      return;
    }

    if (filasValidas.length > 2000) {
      toast.error('El lote excede el límite máximo permitido de 2,000 cambios');
      return;
    }

    try {
      setAplicandoLote(true);
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const cambiosPayload = filasValidas.map((f) => ({
        fuente: f.fuente,
        id: f.id,
        precio_nuevo: f.precioNuevo,
        precio_anterior_visto: f.precioActual,
      }));

      const res = await fetch(`${BASE_URL}/precios/aplicar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          origen: origenLote,
          descripcion: descripcionLote.trim(),
          cambios: cambiosPayload,
        }),
      });

      const json = await res.json().catch(() => ({}));

      if (res.status === 409) {
        // Conflicto de concurrencia
        setConflictos409(json.conflictos || []);
        toast.error('Conflicto de precios detectado', {
          description: 'Uno o más registros fueron modificados por otro usuario mientras preparabas los cambios.',
        });
        return;
      }

      if (!res.ok) {
        throw new Error(json.error || `Error ${res.status} al aplicar lote`);
      }

      // Éxito
      setModalConfirmarOpen(false);
      setResultadoExito({
        lote_id: json.lote_id,
        aplicados: json.aplicados,
        omitidos: json.omitidos_sin_cambio || 0,
      });
      toast.success('¡Lote de precios aplicado con éxito!', {
        description: `Se actualizaron ${json.aplicados} registros.`,
      });

      // Refrescar pantallas y catálogo
      cargarLotesAnteriores();
      cargarItemsCatalogo(fuente);
      if (onPreciosActualizados) {
        onPreciosActualizados();
      }
    } catch (err: any) {
      console.error('Error aplicando lote:', err);
      toast.error('Error aplicando lote de precios', { description: err.message });
    } finally {
      setAplicandoLote(false);
    }
  };

  // =========================================================================
  // REVERSIÓN DE LOTE
  // =========================================================================
  const handleRevertirLote = async () => {
    if (!loteRevertirModal) return;
    try {
      setRevirtiendoLote(true);
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const res = await fetch(`${BASE_URL}/precios/lotes/${loteRevertirModal.id}/revertir`, {
        method: 'POST',
        headers: { Authorization: `Bearer ${token}` },
      });

      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(json.error || 'Error al revertir lote');
      }

      toast.success('Lote revertido correctamente', {
        description: `Se restauraron ${json.revertidos} registros. (${json.omitidos_modificados_posteriormente || 0} omitidos por edición posterior).`,
      });

      setLoteRevertirModal(null);
      cargarLotesAnteriores();
      cargarItemsCatalogo(fuente);
      if (onPreciosActualizados) {
        onPreciosActualizados();
      }
    } catch (err: any) {
      console.error('Error al revertir lote:', err);
      toast.error('No se pudo revertir el lote', { description: err.message });
    } finally {
      setRevirtiendoLote(false);
    }
  };

  const verDetalleLote = async (loteId: string) => {
    try {
      setCargandoDetalleLote(true);
      setLoteDetalleModal({ id: loteId, cargando: true });
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token;

      const res = await fetch(`${BASE_URL}/precios/lotes/${loteId}`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (res.ok) {
        const json = await res.json();
        setLoteDetalleModal(json);
      } else {
        toast.error('No se pudo cargar el detalle del lote');
        setLoteDetalleModal(null);
      }
    } catch (err: any) {
      console.error('Error cargando detalle lote:', err);
      setLoteDetalleModal(null);
    } finally {
      setCargandoDetalleLote(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* ─── INDICADOR VISUAL DE PASOS ────────────────────────────────────────── */}
      <div className="p-4 rounded-xl border border-border bg-card shadow-xs">
        <div className="flex items-center justify-between max-w-2xl mx-auto">
          {/* Paso 1 */}
          <div className="flex items-center gap-3">
            <div
              className={`h-8 w-8 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                paso === 1
                  ? 'bg-primary text-primary-foreground shadow-xs'
                  : paso > 1
                  ? 'bg-emerald-500 text-white'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {paso > 1 ? <Check className="h-4 w-4" /> : '1'}
            </div>
            <div>
              <p className="text-sm font-medium text-foreground">1. Elegir</p>
              <p className="text-xs text-muted-foreground hidden sm:block">Fuente y selección</p>
            </div>
          </div>

          <div className="h-0.5 w-12 sm:w-24 bg-border" />

          {/* Paso 2 */}
          <div className="flex items-center gap-3">
            <div
              className={`h-8 w-8 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                paso === 2
                  ? 'bg-primary text-primary-foreground shadow-xs'
                  : paso > 2
                  ? 'bg-emerald-500 text-white'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              {paso > 2 ? <Check className="h-4 w-4" /> : '2'}
            </div>
            <div>
              <p className="text-sm font-medium text-foreground">2. Revisar</p>
              <p className="text-xs text-muted-foreground hidden sm:block">Diferencias y alertas</p>
            </div>
          </div>

          <div className="h-0.5 w-12 sm:w-24 bg-border" />

          {/* Paso 3 */}
          <div className="flex items-center gap-3">
            <div
              className={`h-8 w-8 rounded-full flex items-center justify-center text-sm font-semibold transition-colors ${
                paso === 3
                  ? 'bg-primary text-primary-foreground shadow-xs'
                  : 'bg-muted text-muted-foreground'
              }`}
            >
              3
            </div>
            <div>
              <p className="text-sm font-medium text-foreground">3. Aplicar</p>
              <p className="text-xs text-muted-foreground hidden sm:block">Confirmar y guardar</p>
            </div>
          </div>
        </div>
      </div>

      {/* ─── PASO 1: ELEGIR Y AJUSTAR ─────────────────────────────────────────── */}
      {paso === 1 && (
        <div className="space-y-6">
          {/* Selector de Fuente */}
          <Card className="border-border bg-card">
            <CardHeader className="pb-3">
              <CardTitle className="text-lg font-semibold flex items-center gap-2">
                <Layers className="h-5 w-5 text-primary" />
                Fuente de Precios
              </CardTitle>
              <CardDescription className="text-sm text-muted-foreground">
                Selecciona la fuente que deseas actualizar. Puedes aplicar fórmulas por lote o descargar/subir una plantilla de Excel.
              </CardDescription>
            </CardHeader>
            <CardContent>
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-2.5">
                {[
                  { id: 'productos', label: 'Materia prima', desc: 'Productos de inventario' },
                  { id: 'opcion_costos', label: 'Opciones de remolque', desc: 'Suspensiones, ejes, frenos' },
                  { id: 'costos_modelo', label: 'Costos por modelo', desc: 'Líneas y kits fijos' },
                  { id: 'acero_precios', label: 'Precios de acero', desc: 'Tarifario de proveedores' },
                ].map((item) => (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => setFuente(item.id as FuentePrecios)}
                    className={`flex flex-col text-left p-3 rounded-lg border transition-all ${
                      fuente === item.id
                        ? 'border-primary bg-primary/5 ring-1 ring-primary'
                        : 'border-border bg-background hover:bg-muted/50'
                    }`}
                  >
                    <span className="font-semibold text-sm text-foreground">{item.label}</span>
                    <span className="text-xs text-muted-foreground mt-0.5">{item.desc}</span>
                  </button>
                ))}
              </div>
            </CardContent>
          </Card>

          {/* Opciones de Ajuste: Fórmula vs Excel */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            {/* Camino A: Ajuste masivo por porcentaje / monto */}
            <Card className="border-border bg-card">
              <CardHeader className="pb-3">
                <CardTitle className="text-base font-semibold flex items-center gap-2">
                  <Percent className="h-4 w-4 text-primary" />
                  Ajuste Masivo por Fórmula
                </CardTitle>
                <CardDescription className="text-xs text-muted-foreground">
                  Aplica un cambio uniforme a las filas seleccionadas en la tabla inferior.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
                  <div className="space-y-1.5">
                    <Label className="text-xs font-medium">Tipo de ajuste</Label>
                    <Select value={modoAjuste} onValueChange={(val: any) => setModoAjuste(val)}>
                      <SelectTrigger className="h-9 text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="porcentaje">Porcentaje (%)</SelectItem>
                        <SelectItem value="monto">Monto fijo ($)</SelectItem>
                        <SelectItem value="fijo">Precio exacto ($)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>

                  <div className="space-y-1.5">
                    <Label className="text-xs font-medium">
                      {modoAjuste === 'porcentaje'
                        ? 'Valor (%) ej. 10 o -5'
                        : modoAjuste === 'monto'
                        ? 'Monto ($) ej. 250 o -100'
                        : 'Nuevo precio fijo ($)'}
                    </Label>
                    <Input
                      type="number"
                      step="any"
                      value={valorAjuste}
                      onChange={(e) => setValorAjuste(e.target.value)}
                      placeholder="10"
                      className="h-9 text-xs"
                    />
                  </div>

                  <div className="space-y-1.5">
                    <Label className="text-xs font-medium">Redondeo</Label>
                    <Select value={redondeoAjuste} onValueChange={(val: any) => setRedondeoAjuste(val)}>
                      <SelectTrigger className="h-9 text-xs">
                        <SelectValue />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="centavos">Centavos ($0.01)</SelectItem>
                        <SelectItem value="peso">Al peso ($1.00)</SelectItem>
                        <SelectItem value="multiplo5">Múltiplo de 5 ($5.00)</SelectItem>
                      </SelectContent>
                    </Select>
                  </div>
                </div>

                <Button
                  onClick={handleAjustarFormula}
                  disabled={seleccionados.size === 0 || previsualizando}
                  className="w-full text-xs h-9"
                >
                  {previsualizando ? (
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                  ) : (
                    <ArrowRight className="h-4 w-4 mr-2" />
                  )}
                  Previsualizar ajuste ({seleccionados.size} seleccionados)
                </Button>
              </CardContent>
            </Card>

            {/* Camino B: Plantilla Excel / CSV */}
            <Card className="border-border bg-card">
              <CardHeader className="pb-3">
                <CardTitle className="text-base font-semibold flex items-center gap-2">
                  <FileSpreadsheet className="h-4 w-4 text-emerald-500" />
                  Actualización mediante Excel / CSV
                </CardTitle>
                <CardDescription className="text-xs text-muted-foreground">
                  Descarga la plantilla con los IDs y costos vigentes, edita en Excel y vuelve a subir el archivo.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-3">
                <div className="flex flex-col sm:flex-row gap-3">
                  <Button
                    variant="outline"
                    onClick={handleDescargarPlantilla}
                    disabled={cargandoItems}
                    className="flex-1 text-xs h-9"
                  >
                    <Download className="h-4 w-4 mr-2 text-primary" />
                    Descargar plantilla (.xlsx)
                  </Button>

                  <Button
                    variant="outline"
                    onClick={() => fileInputRef.current?.click()}
                    disabled={previsualizando}
                    className="flex-1 text-xs h-9 bg-primary/5 hover:bg-primary/10 border-primary/30"
                  >
                    <Upload className="h-4 w-4 mr-2 text-primary" />
                    Subir archivo (.xlsx, .csv)
                  </Button>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept=".xlsx,.xls,.csv"
                    className="hidden"
                    onChange={handleSubirArchivo}
                  />
                </div>
                <p className="text-xs text-muted-foreground">
                  Máximo 2 MB. La columna <code className="text-foreground font-mono">precio_nuevo</code> indica los valores a modificar. Las celdas vacías no se alteran.
                </p>
              </CardContent>
            </Card>
          </div>

          {/* Filtros y Tabla de Registros */}
          <Card className="border-border bg-card">
            <CardHeader className="pb-3">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <CardTitle className="text-base font-semibold">Registros de {fuente}</CardTitle>
                  <CardDescription className="text-xs text-muted-foreground">
                    {itemsCatalogo.length} registros encontrados • {seleccionados.size} seleccionados
                  </CardDescription>
                </div>

                <div className="flex flex-wrap items-center gap-2">
                  <form onSubmit={handleBuscar} className="relative flex-1 sm:w-64">
                    <Search className="absolute left-2.5 top-2.5 h-3.5 w-3.5 text-muted-foreground" />
                    <Input
                      placeholder="Buscar por descripción o código..."
                      value={busqueda}
                      onChange={(e) => setBusqueda(e.target.value)}
                      className="pl-8 h-8 text-xs"
                    />
                  </form>

                  {(fuente === 'opcion_costos' || fuente === 'costos_modelo') && (
                    <Select value={tipoModeloFiltro} onValueChange={setTipoModeloFiltro}>
                      <SelectTrigger className="h-8 text-xs w-36">
                        <SelectValue placeholder="Modelo" />
                      </SelectTrigger>
                      <SelectContent>
                        <SelectItem value="todos">Todos los modelos</SelectItem>
                        <SelectItem value="plataforma">Plataforma</SelectItem>
                        <SelectItem value="dolly">Dolly</SelectItem>
                        <SelectItem value="gondola">Góndola</SelectItem>
                      </SelectContent>
                    </Select>
                  )}

                  <div className="flex items-center gap-1.5 pl-2">
                    <Checkbox
                      id="chk-sin-precio"
                      checked={soloSinPrecio}
                      onCheckedChange={(c) => setSoloSinPrecio(Boolean(c))}
                    />
                    <Label htmlFor="chk-sin-precio" className="text-xs cursor-pointer">
                      Solo sin precio
                    </Label>
                  </div>
                </div>
              </div>
            </CardHeader>
            <CardContent>
              {cargandoItems ? (
                <div className="flex flex-col items-center justify-center py-12 text-muted-foreground">
                  <Loader2 className="h-8 w-8 animate-spin mb-2 text-primary" />
                  <p className="text-sm">Cargando registros...</p>
                </div>
              ) : itemsCatalogo.length === 0 ? (
                <div className="text-center py-12 text-muted-foreground text-sm">
                  No se encontraron registros con los filtros seleccionados.
                </div>
              ) : (
                <div className="rounded-lg border border-border overflow-hidden">
                  <div className="max-h-96 overflow-y-auto">
                    <Table>
                      <TableHeader className="bg-muted/50 sticky top-0 z-10">
                        <TableRow>
                          <TableHead className="w-12 text-center">
                            <Checkbox
                              checked={
                                seleccionados.size === itemsCatalogo.length && itemsCatalogo.length > 0
                                  ? true
                                  : seleccionados.size > 0
                                  ? 'indeterminate'
                                  : false
                              }
                              onCheckedChange={toggleSeleccionarTodo}
                            />
                          </TableHead>
                          <TableHead className="text-xs">Descripción / Concepto</TableHead>
                          <TableHead className="text-xs">Contexto / Grupo</TableHead>
                          <TableHead className="text-xs w-20">Unidad</TableHead>
                          <TableHead className="text-xs text-right w-28">Precio Actual</TableHead>
                        </TableRow>
                      </TableHeader>
                      <TableBody>
                        {itemsCatalogo.map((item) => {
                          const isSelected = seleccionados.has(item.id);
                          return (
                            <TableRow
                              key={item.id}
                              className={`cursor-pointer transition-colors ${
                                isSelected ? 'bg-primary/5' : 'hover:bg-muted/30'
                              }`}
                              onClick={() => toggleSeleccionarItem(item.id)}
                            >
                              <TableCell className="text-center" onClick={(e) => e.stopPropagation()}>
                                <Checkbox
                                  checked={isSelected}
                                  onCheckedChange={() => toggleSeleccionarItem(item.id)}
                                />
                              </TableCell>
                              <TableCell className="font-medium text-xs text-foreground">
                                {item.descripcion}
                              </TableCell>
                              <TableCell className="text-xs text-muted-foreground">
                                {item.contexto || '-'}
                              </TableCell>
                              <TableCell className="text-xs text-muted-foreground font-mono">
                                {item.unidad || 'pz'}
                              </TableCell>
                              <TableCell className="text-xs text-right font-mono text-foreground font-medium">
                                {item.precio_actual !== null
                                  ? formatearMoneda(item.precio_actual)
                                  : <span className="text-muted-foreground italic text-xs">Sin costo</span>}
                              </TableCell>
                            </TableRow>
                          );
                        })}
                      </TableBody>
                    </Table>
                  </div>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}

      {/* ─── PASO 2: REVISIÓN DE CAMBIOS (DIFF) ─────────────────────────────────── */}
      {paso === 2 && (
        <div className="space-y-6">
          {/* Tarjetas de Resumen */}
          {resumenDiff && (
            <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
              <Card className="border-border bg-card p-4">
                <p className="text-xs text-muted-foreground font-medium">Modificaciones</p>
                <p className="text-xl font-bold text-emerald-500 mt-1">{resumenDiff.cambian}</p>
                <p className="text-[11px] text-muted-foreground mt-0.5">Filas con nuevo precio</p>
              </Card>

              <Card className="border-border bg-card p-4">
                <p className="text-xs text-muted-foreground font-medium">Sin cambio</p>
                <p className="text-xl font-bold text-muted-foreground mt-1">{resumenDiff.sinCambio}</p>
                <p className="text-[11px] text-muted-foreground mt-0.5">Mismo precio o vacío</p>
              </Card>

              <Card className="border-border bg-card p-4">
                <p className="text-xs text-muted-foreground font-medium">Alertas</p>
                <p className="text-xl font-bold text-amber-500 mt-1">{resumenDiff.alertas}</p>
                <p className="text-[11px] text-muted-foreground mt-0.5">&gt; 30%, $0 o &gt; 5×</p>
              </Card>

              <Card className="border-border bg-card p-4">
                <p className="text-xs text-muted-foreground font-medium">Errores</p>
                <p className="text-xl font-bold text-red-500 mt-1">{resumenDiff.errores}</p>
                <p className="text-[11px] text-muted-foreground mt-0.5">Se omitirán al aplicar</p>
              </Card>

              <Card className="border-border bg-card p-4 col-span-2 sm:col-span-1">
                <p className="text-xs text-muted-foreground font-medium">Impacto estimado</p>
                <p className="text-lg font-bold text-foreground mt-1">
                  {formatearMoneda(resumenDiff.impactoTotalPesos)}
                </p>
                <p className="text-[11px] text-muted-foreground mt-0.5">Σ |nuevo − actual|</p>
              </Card>
            </div>
          )}

          {/* Banner de Errores (si los hay) */}
          {resumenDiff && resumenDiff.errores > 0 && (
            <div className="flex items-start gap-3 p-4 rounded-lg bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 text-red-800 dark:text-red-300 text-sm">
              <XCircle className="h-5 w-5 shrink-0 text-red-600 dark:text-red-400 mt-0.5" />
              <div>
                <p className="font-semibold">
                  Se detectaron {resumenDiff.errores} fila(s) con error.
                </p>
                <p className="text-xs mt-0.5 text-red-700 dark:text-red-400">
                  Estas filas serán omitidas automáticamente. Los {resumenDiff.cambian} cambios válidos sí podrán aplicarse sin problemas.
                </p>
              </div>
            </div>
          )}

          {/* Banner de Alertas con Checkbox Requerido */}
          {resumenDiff && resumenDiff.alertas > 0 && (
            <div className="p-4 rounded-lg bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900 text-amber-800 dark:text-amber-300 space-y-3">
              <div className="flex items-start gap-3">
                <AlertTriangle className="h-5 w-5 shrink-0 text-amber-600 dark:text-amber-400 mt-0.5" />
                <div>
                  <p className="font-semibold text-sm">
                    Advertencia: Se detectaron {resumenDiff.alertas} cambio(s) con variación considerable o precio $0.00.
                  </p>
                  <p className="text-xs mt-0.5 text-amber-700 dark:text-amber-400">
                    Por seguridad, debes revisar detenidamente las diferencias resaltadas en amarillo antes de proceder.
                  </p>
                </div>
              </div>

              <div className="flex items-center gap-2 pt-1 border-t border-amber-200/50 dark:border-amber-900/50">
                <Checkbox
                  id="chk-entiendo"
                  checked={entiendoAlertas}
                  onCheckedChange={(c) => setEntiendoAlertas(Boolean(c))}
                />
                <Label htmlFor="chk-entiendo" className="text-xs font-semibold cursor-pointer text-amber-900 dark:text-amber-200">
                  Entiendo las alertas y confirmo que los nuevos precios son correctos.
                </Label>
              </div>
            </div>
          )}

          {/* Tabla de Cambios Detallada */}
          <Card className="border-border bg-card">
            <CardHeader className="pb-3">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <CardTitle className="text-base font-semibold">Comparativa Antes / Después</CardTitle>
                  <CardDescription className="text-xs text-muted-foreground">
                    Verifica cada precio individualmente antes de confirmar la actualización.
                  </CardDescription>
                </div>

                <div className="flex items-center gap-1.5">
                  <Button
                    size="sm"
                    variant={filtroVistaDiff === 'todos' ? 'default' : 'outline'}
                    className="text-xs h-7"
                    onClick={() => setFiltroVistaDiff('todos')}
                  >
                    Todos ({filasDiff.length})
                  </Button>
                  <Button
                    size="sm"
                    variant={filtroVistaDiff === 'cambios' ? 'default' : 'outline'}
                    className="text-xs h-7"
                    onClick={() => setFiltroVistaDiff('cambios')}
                  >
                    Cambios ({resumenDiff?.cambian || 0})
                  </Button>
                  {resumenDiff && resumenDiff.alertas > 0 && (
                    <Button
                      size="sm"
                      variant={filtroVistaDiff === 'alertas' ? 'default' : 'outline'}
                      className="text-xs h-7"
                      onClick={() => setFiltroVistaDiff('alertas')}
                    >
                      Alertas ({resumenDiff.alertas})
                    </Button>
                  )}
                  {resumenDiff && resumenDiff.errores > 0 && (
                    <Button
                      size="sm"
                      variant={filtroVistaDiff === 'errores' ? 'default' : 'outline'}
                      className="text-xs h-7 text-red-500"
                      onClick={() => setFiltroVistaDiff('errores')}
                    >
                      Errores ({resumenDiff.errores})
                    </Button>
                  )}
                </div>
              </div>
            </CardHeader>
            <CardContent>
              <div className="rounded-lg border border-border overflow-hidden">
                <div className="max-h-96 overflow-y-auto">
                  <Table>
                    <TableHeader className="bg-muted/50 sticky top-0 z-10">
                      <TableRow>
                        <TableHead className="text-xs">Descripción</TableHead>
                        <TableHead className="text-xs">Contexto</TableHead>
                        <TableHead className="text-xs text-right w-24">Precio Actual</TableHead>
                        <TableHead className="text-xs text-right w-24">Precio Nuevo</TableHead>
                        <TableHead className="text-xs text-right w-24">Diferencia</TableHead>
                        <TableHead className="text-xs w-36">Estado / Alerta</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {filasDiffFiltradas.map((fila, idx) => {
                        const esAlerta = fila.estado === 'alerta';
                        const esError = fila.estado === 'error';
                        const esCambia = fila.estado === 'cambia';

                        return (
                          <TableRow
                            key={`${fila.id}-${idx}`}
                            className={
                              esError
                                ? 'bg-red-50/50 dark:bg-red-950/20'
                                : esAlerta
                                ? 'bg-amber-50/50 dark:bg-amber-950/20'
                                : esCambia
                                ? 'bg-emerald-50/30 dark:bg-emerald-950/10'
                                : ''
                            }
                          >
                            <TableCell className="text-xs font-medium text-foreground">
                              {fila.descripcion}
                              {fila.filaArchivo && (
                                <span className="block text-[10px] text-muted-foreground font-mono">
                                  Línea de archivo: #{fila.filaArchivo}
                                </span>
                              )}
                            </TableCell>
                            <TableCell className="text-xs text-muted-foreground">
                              {fila.contexto || '-'}
                            </TableCell>
                            <TableCell className="text-xs text-right font-mono text-muted-foreground">
                              {formatearMoneda(fila.precioActual)}
                            </TableCell>
                            <TableCell className="text-xs text-right font-mono font-semibold text-foreground">
                              {fila.precioNuevo !== null && !isNaN(fila.precioNuevo)
                                ? formatearMoneda(fila.precioNuevo)
                                : '-'}
                            </TableCell>
                            <TableCell className="text-xs text-right font-mono">
                              {fila.delta !== null ? (
                                <span
                                  className={
                                    fila.delta > 0
                                      ? 'text-emerald-600 dark:text-emerald-400 font-medium'
                                      : fila.delta < 0
                                      ? 'text-amber-600 dark:text-amber-400 font-medium'
                                      : 'text-muted-foreground'
                                  }
                                >
                                  {fila.delta > 0 ? '+' : ''}
                                  {formatearMoneda(fila.delta)}
                                  {fila.deltaPorcentaje !== null && (
                                    <span className="block text-[10px]">
                                      ({fila.deltaPorcentaje > 0 ? '+' : ''}
                                      {fila.deltaPorcentaje.toFixed(1)}%)
                                    </span>
                                  )}
                                </span>
                              ) : (
                                '-'
                              )}
                            </TableCell>
                            <TableCell className="text-xs">
                              {esError ? (
                                <div className="space-y-0.5">
                                  <Badge variant="destructive" className="text-[10px]">
                                    Error
                                  </Badge>
                                  {fila.error && (
                                    <p className="text-[10px] text-red-600 dark:text-red-400">
                                      {fila.error}
                                    </p>
                                  )}
                                </div>
                              ) : esAlerta ? (
                                <div className="space-y-0.5">
                                  <Badge variant="outline" className="text-[10px] border-amber-500 text-amber-600">
                                    Alerta
                                  </Badge>
                                  {fila.alertas.map((alt, aIdx) => (
                                    <p key={aIdx} className="text-[10px] text-amber-700 dark:text-amber-400">
                                      {alt}
                                    </p>
                                  ))}
                                </div>
                              ) : esCambia ? (
                                <Badge variant="outline" className="text-[10px] border-emerald-500 text-emerald-600">
                                  Actualiza
                                </Badge>
                              ) : (
                                <span className="text-muted-foreground text-xs">Sin cambio</span>
                              )}
                            </TableCell>
                          </TableRow>
                        );
                      })}
                    </TableBody>
                  </Table>
                </div>
              </div>
            </CardContent>
          </Card>

          {/* Botones de Navegación del Paso 2 */}
          <div className="flex items-center justify-between">
            <Button variant="outline" onClick={() => setPaso(1)} className="text-xs h-9">
              <ArrowLeft className="h-4 w-4 mr-2" />
              Volver a Elegir
            </Button>

            <Button
              onClick={() => setPaso(3)}
              disabled={
                !resumenDiff ||
                resumenDiff.cambian === 0 ||
                (resumenDiff.alertas > 0 && !entiendoAlertas)
              }
              className="text-xs h-9"
            >
              Continuar a Aplicar ({resumenDiff?.cambian || 0} cambios)
              <ArrowRight className="h-4 w-4 ml-2" />
            </Button>
          </div>
        </div>
      )}

      {/* ─── PASO 3: APLICAR Y CONFIRMAR ───────────────────────────────────────── */}
      {paso === 3 && (
        <div className="space-y-6 max-w-2xl mx-auto">
          {resultadoExito ? (
            /* Vista de Éxito */
            <Card className="border-emerald-200 dark:border-emerald-900 bg-emerald-50/30 dark:bg-emerald-950/20 text-center py-8 px-6">
              <CheckCircle2 className="h-12 w-12 text-emerald-500 mx-auto mb-3" />
              <CardTitle className="text-xl font-bold text-foreground">
                ¡Lote aplicado exitosamente!
              </CardTitle>
              <CardDescription className="text-sm text-muted-foreground mt-2">
                Se actualizaron <strong className="text-foreground">{resultadoExito.aplicados}</strong> precios en el catálogo.
                {resultadoExito.omitidos > 0 && ` (${resultadoExito.omitidos} registros sin cambios fueron omitidos).`}
              </CardDescription>

              <div className="flex flex-col sm:flex-row items-center justify-center gap-3 mt-6">
                <Button
                  variant="outline"
                  onClick={() => {
                    setResultadoExito(null);
                    setPaso(1);
                    setSeleccionados(new Set());
                    setDescripcionLote('');
                  }}
                  className="text-xs h-9"
                >
                  Realizar otra actualización
                </Button>
                <Button
                  onClick={() => {
                    setResultadoExito(null);
                    setPaso(1);
                    const el = document.getElementById('panel-lotes-anteriores');
                    if (el) el.scrollIntoView({ behavior: 'smooth' });
                  }}
                  className="text-xs h-9"
                >
                  Ver en Lotes Anteriores
                </Button>
              </div>
            </Card>
          ) : (
            /* Formulario de Aplicación */
            <Card className="border-border bg-card">
              <CardHeader className="pb-4">
                <CardTitle className="text-lg font-semibold flex items-center gap-2">
                  <ShieldAlert className="h-5 w-5 text-primary" />
                  Confirmación de Actualización
                </CardTitle>
                <CardDescription className="text-sm text-muted-foreground">
                  Proporciona un motivo o descripción obligatoria para registrar la trazabilidad en la bitácora de lotes.
                </CardDescription>
              </CardHeader>
              <CardContent className="space-y-4">
                {/* Resumen numérico */}
                <div className="p-3 rounded-lg bg-muted/40 border border-border text-xs space-y-1.5">
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Origen del lote:</span>
                    <span className="font-semibold text-foreground capitalize">{origenLote}</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Registros a actualizar:</span>
                    <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                      {resumenDiff?.cambian || 0}
                    </span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-muted-foreground">Impacto económico aproximado:</span>
                    <span className="font-semibold text-foreground">
                      {formatearMoneda(resumenDiff?.impactoTotalPesos)}
                    </span>
                  </div>
                </div>

                {/* Conflictos 409 detectados */}
                {conflictos409 && (
                  <div className="p-4 rounded-lg bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900 text-red-800 dark:text-red-300 text-xs space-y-2">
                    <p className="font-semibold text-sm">Conflicto de concurrencia detectado (409):</p>
                    <p>
                      Los siguientes registros cambiaron de precio mientras preparabas este lote:
                    </p>
                    <ul className="list-disc list-inside space-y-0.5">
                      {conflictos409.slice(0, 5).map((c, idx) => (
                        <li key={idx}>
                          Registro <code className="font-mono">{c.registro_id}</code>: esperado{' '}
                          {formatearMoneda(c.precio_esperado)}, actual en BD {formatearMoneda(c.precio_actual)}
                        </li>
                      ))}
                    </ul>
                    <Button
                      size="sm"
                      variant="outline"
                      className="mt-2 text-xs h-8 border-red-300 dark:border-red-800"
                      onClick={() => {
                        setConflictos409(null);
                        setPaso(1);
                        cargarItemsCatalogo(fuente);
                      }}
                    >
                      <RefreshCw className="h-3.5 w-3.5 mr-1" />
                      Recargar catálogo y volver a empezar
                    </Button>
                  </div>
                )}

                {/* Campo de Descripción Obligatoria */}
                <div className="space-y-1.5">
                  <Label htmlFor="input-desc" className="text-xs font-semibold">
                    Descripción del lote <span className="text-red-500">*</span>
                  </Label>
                  <Input
                    id="input-desc"
                    placeholder="Ej. Ajuste proveedores octubre 2026, inflación bimestral, etc."
                    value={descripcionLote}
                    onChange={(e) => setDescripcionLote(e.target.value)}
                    maxLength={200}
                    className="h-10 text-sm"
                  />
                  <p className="text-[11px] text-muted-foreground text-right">
                    {descripcionLote.length}/200 caracteres
                  </p>
                </div>

                <div className="flex items-center justify-between pt-4 border-t border-border">
                  <Button variant="outline" onClick={() => setPaso(2)} className="text-xs h-9">
                    <ArrowLeft className="h-4 w-4 mr-2" />
                    Volver a Revisar
                  </Button>

                  <Button
                    onClick={() => setModalConfirmarOpen(true)}
                    disabled={!descripcionLote.trim() || aplicandoLote}
                    className="text-xs h-9 bg-primary"
                  >
                    Confirmar y Aplicar Lote
                  </Button>
                </div>
              </CardContent>
            </Card>
          )}

          {/* Modal de Confirmación Definitiva */}
          <Dialog open={modalConfirmarOpen} onOpenChange={setModalConfirmarOpen}>
            <DialogContent className="max-w-md">
              <DialogHeader>
                <DialogTitle className="text-base font-semibold">
                  ¿Aplicar lote de actualización de precios?
                </DialogTitle>
                <DialogDescription className="text-xs text-muted-foreground">
                  Esta acción actualizará {resumenDiff?.cambian || 0} precios vigentes en el sistema. Los cambios afectarán nuevas cotizaciones y recálculos.
                </DialogDescription>
              </DialogHeader>

              <div className="py-2 text-xs space-y-2 text-foreground">
                <p>
                  <strong>Descripción:</strong> {descripcionLote}
                </p>
                <p className="text-muted-foreground">
                  Podrás consultar la trazabilidad o revertir el lote completo desde el panel inferior si es necesario.
                </p>
              </div>

              <DialogFooter className="gap-2 sm:gap-0">
                <Button
                  variant="outline"
                  onClick={() => setModalConfirmarOpen(false)}
                  disabled={aplicandoLote}
                  className="text-xs h-9"
                >
                  Cancelar
                </Button>
                <Button
                  onClick={handleConfirmarYAplicar}
                  disabled={aplicandoLote}
                  className="text-xs h-9 bg-primary"
                >
                  {aplicandoLote ? (
                    <Loader2 className="h-4 w-4 animate-spin mr-2" />
                  ) : (
                    <Check className="h-4 w-4 mr-2" />
                  )}
                  Sí, aplicar cambios
                </Button>
              </DialogFooter>
            </DialogContent>
          </Dialog>
        </div>
      )}

      {/* ─── PANEL: LOTES ANTERIORES Y REVERSIÓN ───────────────────────────────── */}
      <div id="panel-lotes-anteriores" className="pt-6 border-t border-border/70 space-y-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-base font-semibold text-foreground flex items-center gap-2">
              <History className="h-4 w-4 text-primary" />
              Historial de Lotes Anteriores
            </h2>
            <p className="text-xs text-muted-foreground">
              Registro histórico de lotes aplicados con opción a reversión atómica y segura.
            </p>
          </div>

          <Button
            size="sm"
            variant="outline"
            onClick={cargarLotesAnteriores}
            disabled={cargandoLotes}
            className="text-xs h-8"
          >
            <RefreshCw className={`h-3.5 w-3.5 mr-1.5 ${cargandoLotes ? 'animate-spin' : ''}`} />
            Actualizar historial
          </Button>
        </div>

        <Card className="border-border bg-card">
          <CardContent className="p-0">
            {cargandoLotes ? (
              <div className="flex items-center justify-center py-10 text-muted-foreground text-sm">
                <Loader2 className="h-6 w-6 animate-spin mr-2 text-primary" />
                Cargando historial de lotes...
              </div>
            ) : lotes.length === 0 ? (
              <div className="text-center py-10 text-muted-foreground text-xs">
                No hay lotes de actualización registrados todavía.
              </div>
            ) : (
              <div className="overflow-x-auto">
                <Table>
                  <TableHeader className="bg-muted/40">
                    <TableRow>
                      <TableHead className="text-xs">Fecha y Hora</TableHead>
                      <TableHead className="text-xs">Origen</TableHead>
                      <TableHead className="text-xs">Descripción</TableHead>
                      <TableHead className="text-xs text-center w-24">Cambios</TableHead>
                      <TableHead className="text-xs text-center w-28">Estado</TableHead>
                      <TableHead className="text-xs text-right w-36">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {lotes.map((lote) => {
                      const revertido = Boolean(lote.revertido_el);
                      const fechaFormat = new Date(lote.creado_el).toLocaleString('es-MX', {
                        dateStyle: 'short',
                        timeStyle: 'short',
                      });

                      return (
                        <TableRow key={lote.id}>
                          <TableCell className="text-xs font-mono text-muted-foreground">
                            {fechaFormat}
                          </TableCell>
                          <TableCell className="text-xs capitalize font-medium text-foreground">
                            {lote.origen}
                          </TableCell>
                          <TableCell className="text-xs text-foreground max-w-xs truncate">
                            {lote.descripcion}
                          </TableCell>
                          <TableCell className="text-xs text-center font-mono font-semibold">
                            {lote.total_cambios}
                          </TableCell>
                          <TableCell className="text-xs text-center">
                            {revertido ? (
                              <Badge variant="outline" className="text-[10px] text-muted-foreground border-muted-foreground/30">
                                Revertido
                              </Badge>
                            ) : (
                              <Badge variant="outline" className="text-[10px] text-emerald-600 border-emerald-500/30">
                                Aplicado
                              </Badge>
                            )}
                          </TableCell>
                          <TableCell className="text-xs text-right space-x-1">
                            <Button
                              size="sm"
                              variant="ghost"
                              className="text-xs h-7 px-2"
                              onClick={() => verDetalleLote(lote.id)}
                            >
                              <Eye className="h-3.5 w-3.5 mr-1" />
                              Ver
                            </Button>
                            {!revertido && canEdit && (
                              <Button
                                size="sm"
                                variant="outline"
                                className="text-xs h-7 px-2 text-amber-600 hover:text-amber-700 hover:bg-amber-50 dark:hover:bg-amber-950/20 border-amber-300 dark:border-amber-800"
                                onClick={() => setLoteRevertirModal(lote)}
                              >
                                <Undo2 className="h-3.5 w-3.5 mr-1" />
                                Deshacer
                              </Button>
                            )}
                          </TableCell>
                        </TableRow>
                      );
                    })}
                  </TableBody>
                </Table>
              </div>
            )}
          </CardContent>
        </Card>
      </div>

      {/* ─── MODAL DETALLE DE ITEMS DEL LOTE ─────────────────────────────────── */}
      <Dialog open={Boolean(loteDetalleModal)} onOpenChange={(open) => !open && setLoteDetalleModal(null)}>
        <DialogContent className="max-w-3xl max-h-[85vh] flex flex-col">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold">
              Detalle del Lote
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              {loteDetalleModal?.descripcion} • {loteDetalleModal?.items?.length || 0} items
            </DialogDescription>
          </DialogHeader>

          {cargandoDetalleLote ? (
            <div className="flex items-center justify-center py-12 text-muted-foreground text-sm">
              <Loader2 className="h-6 w-6 animate-spin mr-2 text-primary" />
              Cargando items del lote...
            </div>
          ) : (
            <div className="overflow-y-auto max-h-96 rounded-lg border border-border">
              <Table>
                <TableHeader className="bg-muted/40 sticky top-0 z-10">
                  <TableRow>
                    <TableHead className="text-xs">Fuente</TableHead>
                    <TableHead className="text-xs">Descripción</TableHead>
                    <TableHead className="text-xs text-right w-24">P. Anterior</TableHead>
                    <TableHead className="text-xs text-right w-24">P. Nuevo</TableHead>
                    <TableHead className="text-xs text-right w-24">Δ Variación</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {loteDetalleModal?.items?.map((item: any, idx: number) => {
                    const diff = Number(item.precio_nuevo) - Number(item.precio_anterior);
                    return (
                      <TableRow key={item.id || idx}>
                        <TableCell className="text-xs font-mono text-muted-foreground capitalize">
                          {item.fuente}
                        </TableCell>
                        <TableCell className="text-xs font-medium text-foreground">
                          {item.descripcion}
                        </TableCell>
                        <TableCell className="text-xs text-right font-mono text-muted-foreground">
                          {formatearMoneda(item.precio_anterior)}
                        </TableCell>
                        <TableCell className="text-xs text-right font-mono font-semibold text-foreground">
                          {formatearMoneda(item.precio_nuevo)}
                        </TableCell>
                        <TableCell className="text-xs text-right font-mono">
                          <span
                            className={
                              diff > 0
                                ? 'text-emerald-600 dark:text-emerald-400'
                                : diff < 0
                                ? 'text-amber-600 dark:text-amber-400'
                                : 'text-muted-foreground'
                            }
                          >
                            {diff > 0 ? '+' : ''}
                            {formatearMoneda(diff)}
                          </span>
                        </TableCell>
                      </TableRow>
                    );
                  })}
                </TableBody>
              </Table>
            </div>
          )}

          <DialogFooter>
            <Button
              variant="outline"
              onClick={() => setLoteDetalleModal(null)}
              className="text-xs h-9"
            >
              Cerrar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* ─── MODAL DESHACER LOTE (REVERSIÓN) ─────────────────────────────────── */}
      <Dialog open={Boolean(loteRevertirModal)} onOpenChange={(open) => !open && setLoteRevertirModal(null)}>
        <DialogContent className="max-w-md">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold text-amber-600 dark:text-amber-400 flex items-center gap-2">
              <Undo2 className="h-5 w-5" />
              ¿Deshacer este lote de precios?
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              Esta acción restaurará el precio anterior únicamente en aquellos registros que no hayan sufrido modificaciones posteriores.
            </DialogDescription>
          </DialogHeader>

          {loteRevertirModal && (
            <div className="py-2 text-xs space-y-2 text-foreground">
              <div className="p-3 rounded-lg bg-muted/40 border border-border space-y-1">
                <p><strong>Lote:</strong> {loteRevertirModal.descripcion}</p>
                <p><strong>Total cambios originales:</strong> {loteRevertirModal.total_cambios}</p>
                <p><strong>Fecha de aplicación:</strong> {new Date(loteRevertirModal.creado_el).toLocaleString('es-MX')}</p>
              </div>
              <p className="text-muted-foreground">
                Los registros editados manualmente después de este lote se conservarán intactos para proteger los cambios más recientes.
              </p>
            </div>
          )}

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              variant="outline"
              onClick={() => setLoteRevertirModal(null)}
              disabled={revirtiendoLote}
              className="text-xs h-9"
            >
              Cancelar
            </Button>
            <Button
              onClick={handleRevertirLote}
              disabled={revirtiendoLote}
              className="text-xs h-9 bg-amber-600 hover:bg-amber-700 text-white"
            >
              {revirtiendoLote ? (
                <Loader2 className="h-4 w-4 animate-spin mr-2" />
              ) : (
                <Undo2 className="h-4 w-4 mr-2" />
              )}
              Confirmar Reversión
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
