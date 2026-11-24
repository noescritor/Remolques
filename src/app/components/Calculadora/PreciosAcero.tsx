import React, { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
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
import {
  Plus,
  RefreshCw,
  Search,
  History,
  Building2,
  AlertTriangle,
  Layers,
  Edit2,
  Trash2,
  Check,
  X,
  FileSpreadsheet,
  BookmarkCheck,
  Pencil,
} from 'lucide-react';
import { Checkbox } from '../ui/checkbox';
import { toast } from 'sonner';
import { formatearMoneda } from '../../utils/calculations';
import { determinarTipoMaterial, TipoMaterialAcero } from '../../utils/aceroCalc';
import {
  guardarPrecioAceroApi,
  crearMaterialAceroApi,
  actualizarMaterialAceroApi,
  eliminarPrecioAceroApi,
  fetchHistorialAceroApi,
  renombrarProveedorAceroApi,
} from '../../utils/aceroApi';
import { GestionAliasAceroModal } from './GestionAliasAceroModal';
import { AceroMaterialItem } from '../../../../supabase/functions/make-server-feea4382/motor/acero';

const TIPOS_MATERIAL_ACERO: Array<{ value: TipoMaterialAcero; label: string }> = [
  { value: 'placa', label: 'Placa' },
  { value: 'lamina', label: 'Lámina' },
  { value: 'solera', label: 'Solera' },
  { value: 'canal', label: 'Canal' },
  { value: 'ptr', label: 'PTR' },
  { value: 'tubo', label: 'Tubo' },
  { value: 'angulo', label: 'Ángulo' },
  { value: 'redondo', label: 'Redondo' },
];

interface PreciosAceroProps {
  materiales: AceroMaterialItem[];
  proveedores: string[];
  supabase: any;
  loading?: boolean;
  onRecargar: () => void;
}

export function PreciosAcero({
  materiales,
  proveedores,
  supabase,
  loading = false,
  onRecargar,
}: PreciosAceroProps) {
  const navigate = useNavigate();

  // Filtros
  const [filtroTipo, setFiltroTipo] = useState<string>('todos');
  const [busqueda, setBusqueda] = useState<string>('');

  // Edición en línea de celda
  // key = `${materialId}::${proveedor}`
  const [celdaEditando, setCeldaEditando] = useState<string | null>(null);
  const [valorEditando, setValorEditando] = useState<string>('');
  const [incluyeIvaEditando, setIncluyeIvaEditando] = useState<boolean>(true);
  const [guardando, setGuardando] = useState<boolean>(false);

  // Diálogo de confirmación para cambio > 30%
  const [alertaCambio, setAlertaCambio] = useState<{
    materialId: string;
    proveedor: string;
    precioAnterior: number;
    precioNuevo: number;
    incluyeIva: boolean;
    porcentaje: number;
  } | null>(null);

  // Diálogo de nuevo material
  const [modalNuevoMaterial, setModalNuevoMaterial] = useState<boolean>(false);
  const [nuevoMaterialNombre, setNuevoMaterialNombre] = useState<string>('');
  const [nuevoMaterialTipo, setNuevoMaterialTipo] = useState<TipoMaterialAcero>('placa');
  const [nuevoMaterialTipoManual, setNuevoMaterialTipoManual] = useState<boolean>(false);
  const [nuevoMaterialNotas, setNuevoMaterialNotas] = useState<string>('');

  // Diálogo de editar material existente
  const [materialEditando, setMaterialEditando] = useState<AceroMaterialItem | null>(null);
  const [editMatNombre, setEditMatNombre] = useState<string>('');
  const [editMatTipo, setEditMatTipo] = useState<TipoMaterialAcero>('placa');
  const [editMatNotas, setEditMatNotas] = useState<string>('');
  const [editMatActivo, setEditMatActivo] = useState<boolean>(true);

  // Diálogo de nuevo proveedor
  const [modalNuevoProveedor, setModalNuevoProveedor] = useState<boolean>(false);
  const [nuevoProveedorNombre, setNuevoProveedorNombre] = useState<string>('');
  const [proveedoresLocales, setProveedoresLocales] = useState<string[]>([]);

  // Diálogo de renombrar proveedor
  const [proveedorRenombrando, setProveedorRenombrando] = useState<string | null>(null);
  const [renombreNuevo, setRenombreNuevo] = useState<string>('');
  const [errorRenombre, setErrorRenombre] = useState<string | null>(null);

  // Diálogo de alias XML
  const [modalAliasOpen, setModalAliasOpen] = useState<boolean>(false);

  // Diálogo de historial
  const [modalHistorial, setModalHistorial] = useState<boolean>(false);
  const [historialItems, setHistorialItems] = useState<any[]>([]);
  const [cargandoHistorial, setCargandoHistorial] = useState<boolean>(false);

  // Lista combinada de proveedores
  const todosProveedores = useMemo(() => {
    const set = new Set([...proveedores, ...proveedoresLocales]);
    return Array.from(set).sort();
  }, [proveedores, proveedoresLocales]);

  // Materiales filtrados
  const materialesFiltrados = useMemo(() => {
    return materiales.filter((m) => {
      if (filtroTipo !== 'todos' && m.tipo !== filtroTipo) return false;
      if (busqueda.trim()) {
        const q = busqueda.toLowerCase().trim();
        return m.nombre.toLowerCase().includes(q) || m.tipo.toLowerCase().includes(q);
      }
      return true;
    });
  }, [materiales, filtroTipo, busqueda]);

  // Precios más económicos por material (comparados en la misma base sin IVA)
  const mejoresPreciosPorFila = useMemo(() => {
    const map: Record<string, number> = {};
    for (const m of materiales) {
      if (m.precios) {
        let minSinIva = Infinity;
        for (const p of Object.values(m.precios)) {
          if (p.precio > 0) {
            const baseSinIva = p.incluye_iva === false ? p.precio : p.precio / 1.16;
            if (baseSinIva < minSinIva) {
              minSinIva = baseSinIva;
            }
          }
        }
        if (minSinIva !== Infinity) {
          map[m.id] = minSinIva;
        }
      }
    }
    return map;
  }, [materiales]);

  // Iniciar edición de una celda
  const handleIniciarEdicion = (
    materialId: string,
    proveedor: string,
    precioActual?: number,
    incluyeIvaActual?: boolean
  ) => {
    setCeldaEditando(`${materialId}::${proveedor}`);
    setValorEditando(precioActual ? String(precioActual) : '');
    setIncluyeIvaEditando(incluyeIvaActual !== undefined ? incluyeIvaActual : true);
  };

  // Guardar edición
  const handleGuardarCelda = async (
    materialId: string,
    proveedor: string,
    precioAnterior?: number
  ) => {
    const num = parseFloat(valorEditando);
    if (isNaN(num) || num <= 0) {
      toast.error('El precio debe ser un número mayor a cero');
      return;
    }

    // Verificar si el cambio supera el 30%
    if (precioAnterior && precioAnterior > 0) {
      const difRel = Math.abs(num - precioAnterior) / precioAnterior;
      if (difRel > 0.3) {
        setAlertaCambio({
          materialId,
          proveedor,
          precioAnterior,
          precioNuevo: num,
          incluyeIva: incluyeIvaEditando,
          porcentaje: Math.round(difRel * 100),
        });
        return;
      }
    }

    await ejecutarGuardarPrecio(materialId, proveedor, num, incluyeIvaEditando);
  };

  const ejecutarGuardarPrecio = async (
    materialId: string,
    proveedor: string,
    precio: number,
    incluyeIva: boolean = true
  ) => {
    try {
      setGuardando(true);
      await guardarPrecioAceroApi(supabase, {
        material_id: materialId,
        proveedor,
        precio,
        incluye_iva: incluyeIva,
        fuente: 'Manual',
      });
      toast.success(`Precio de ${proveedor} guardado: ${formatearMoneda(precio)}`);
      setCeldaEditando(null);
      setAlertaCambio(null);
      onRecargar();
    } catch (err: any) {
      toast.error('Error al guardar precio', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  // Eliminar precio
  const handleEliminarPrecio = async (materialId: string, proveedor: string) => {
    try {
      setGuardando(true);
      await eliminarPrecioAceroApi(supabase, materialId, proveedor);
      toast.success(`Precio de ${proveedor} eliminado`);
      setCeldaEditando(null);
      onRecargar();
    } catch (err: any) {
      toast.error('Error al eliminar precio', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  // Crear nuevo material
  const handleCrearMaterial = async () => {
    if (!nuevoMaterialNombre.trim()) {
      toast.error('El nombre del material es requerido');
      return;
    }
    try {
      setGuardando(true);
      await crearMaterialAceroApi(supabase, {
        nombre: nuevoMaterialNombre.trim(),
        tipo: nuevoMaterialTipo,
        notas: nuevoMaterialNotas.trim() || undefined,
      });
      toast.success('Material creado exitosamente');
      setModalNuevoMaterial(false);
      setNuevoMaterialNombre('');
      setNuevoMaterialTipo('placa');
      setNuevoMaterialTipoManual(false);
      setNuevoMaterialNotas('');
      onRecargar();
    } catch (err: any) {
      toast.error('Error al crear material', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  // Abrir editor de material
  const handleAbrirEditarMaterial = (mat: AceroMaterialItem) => {
    setMaterialEditando(mat);
    setEditMatNombre(mat.nombre);
    setEditMatTipo(mat.tipo);
    setEditMatNotas(mat.notas || '');
    setEditMatActivo(mat.activo);
  };

  const handleGuardarMaterialEditado = async () => {
    if (!materialEditando) return;
    if (!editMatNombre.trim()) {
      toast.error('El nombre del material no puede estar vacío');
      return;
    }
    try {
      setGuardando(true);
      await actualizarMaterialAceroApi(supabase, materialEditando.id, {
        nombre: editMatNombre.trim(),
        tipo: editMatTipo,
        notas: editMatNotas.trim(),
        activo: editMatActivo,
      });
      toast.success('Material actualizado');
      setMaterialEditando(null);
      onRecargar();
    } catch (err: any) {
      toast.error('Error al actualizar material', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  // Renombrar proveedor en toda la matriz
  const handleAbrirRenombrarProveedor = (prov: string) => {
    setProveedorRenombrando(prov);
    setRenombreNuevo(prov);
    setErrorRenombre(null);
  };

  const handleConfirmarRenombrarProveedor = async () => {
    if (!proveedorRenombrando) return;
    const nuevo = renombreNuevo.trim();
    if (!nuevo) {
      setErrorRenombre('Escribe el nuevo nombre del proveedor.');
      return;
    }
    if (nuevo === proveedorRenombrando) {
      setProveedorRenombrando(null);
      return;
    }
    try {
      setGuardando(true);
      setErrorRenombre(null);
      const res = await renombrarProveedorAceroApi(supabase, proveedorRenombrando, nuevo);
      setProveedoresLocales((prev) => prev.map((p) => (p === proveedorRenombrando ? nuevo : p)));
      toast.success(
        `Proveedor renombrado a "${res.a}" (${res.precios_actualizados} precios actualizados)`
      );
      setProveedorRenombrando(null);
      onRecargar();
    } catch (err: any) {
      setErrorRenombre(err?.message || 'No se pudo renombrar el proveedor.');
    } finally {
      setGuardando(false);
    }
  };

  // Agregar nuevo proveedor a la vista
  const handleAgregarProveedor = () => {
    const provUpper = nuevoProveedorNombre.trim().toUpperCase();
    if (!provUpper) {
      toast.error('El nombre del proveedor es requerido');
      return;
    }
    if (todosProveedores.includes(provUpper)) {
      toast.error('El proveedor ya existe');
      return;
    }
    setProveedoresLocales((prev) => [...prev, provUpper]);
    setModalNuevoProveedor(false);
    setNuevoProveedorNombre('');
    toast.success(`Proveedor "${provUpper}" agregado a la tabla`);
  };

  // Abrir historial
  const handleVerHistorial = async () => {
    try {
      setCargandoHistorial(true);
      setModalHistorial(true);
      const data = await fetchHistorialAceroApi(supabase, undefined, 50);
      setHistorialItems(data || []);
    } catch (err: any) {
      toast.error('Error al cargar historial', { description: err.message });
    } finally {
      setCargandoHistorial(false);
    }
  };

  return (
    <div className="space-y-6">
      {/* Encabezado */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-bold font-sans flex items-center gap-2 text-foreground">
            <Building2 className="h-5 w-5 text-accent-blue" />
            Catálogo y Precios de Acero
          </h2>
          <p className="text-sm text-muted-foreground mt-0.5">
            Administra la matriz de precios por proveedor con trazabilidad e historial de cambios.
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          <Button
            variant="outline"
            size="sm"
            onClick={handleVerHistorial}
            className="text-xs gap-1.5"
          >
            <History className="h-4 w-4" />
            Historial de cambios
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setModalAliasOpen(true)}
            className="text-xs gap-1.5"
          >
            <BookmarkCheck className="h-4 w-4" />
            Gestionar alias
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => navigate('/catalogo-costos?tab=actualizar-precios')}
            className="text-xs gap-1.5 border-emerald-500/30 text-emerald-600 hover:text-emerald-700 hover:bg-emerald-50 dark:hover:bg-emerald-950/20"
          >
            <FileSpreadsheet className="h-4 w-4 text-emerald-500" />
            Actualización masiva
          </Button>
          <Button
            variant="outline"
            size="sm"
            onClick={() => setModalNuevoProveedor(true)}
            className="text-xs gap-1.5"
          >
            <Plus className="h-4 w-4" />
            Nuevo proveedor
          </Button>
          <Button
            size="sm"
            onClick={() => setModalNuevoMaterial(true)}
            className="text-xs gap-1.5 bg-accent-blue text-white hover:bg-accent-blue/90"
          >
            <Plus className="h-4 w-4" />
            Nuevo material
          </Button>
          <Button
            variant="outline"
            size="icon"
            onClick={onRecargar}
            disabled={loading}
            className="h-8 w-8"
          >
            <RefreshCw className={`h-4 w-4 ${loading ? 'animate-spin' : ''}`} />
          </Button>
        </div>
      </div>

      {/* Filtros de búsqueda y tipo */}
      <Card className="border-border bg-card">
        <CardContent className="pt-4 pb-4">
          <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
            <div className="relative flex-1 max-w-sm">
              <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar material por nombre o medida..."
                value={busqueda}
                onChange={(e) => setBusqueda(e.target.value)}
                className="pl-9 text-xs h-9"
              />
            </div>

            <div className="flex flex-wrap items-center gap-1.5">
              {[
                { key: 'todos', label: 'Todos' },
                { key: 'placa', label: 'Placas' },
                { key: 'lamina', label: 'Láminas' },
                { key: 'solera', label: 'Soleras' },
                { key: 'canal', label: 'Canales' },
                { key: 'ptr', label: 'PTR' },
                { key: 'tubo', label: 'Tubos' },
                { key: 'angulo', label: 'Ángulos' },
                { key: 'redondo', label: 'Redondos' },
              ].map((t) => (
                <button
                  key={t.key}
                  type="button"
                  onClick={() => setFiltroTipo(t.key)}
                  className={`text-xs px-2.5 py-1 rounded-full border transition-colors ${
                    filtroTipo === t.key
                      ? 'bg-accent-blue/10 border-accent-blue text-accent-blue font-semibold'
                      : 'bg-muted/40 border-border text-muted-foreground hover:bg-muted'
                  }`}
                >
                  {t.label}
                </button>
              ))}
            </div>
          </div>
        </CardContent>
      </Card>

      {/* Matriz de precios */}
      <Card className="border-border bg-card">
        <CardHeader className="pb-3 border-b border-border/50">
          <CardTitle className="text-base font-semibold">
            Matriz de Precios ({materialesFiltrados.length} materiales)
          </CardTitle>
          <CardDescription className="text-xs">
            Haz clic en cualquier celda para capturar o actualizar el precio vigente. Presiona Enter para guardar o Esc para cancelar.
          </CardDescription>
        </CardHeader>

        <CardContent className="pt-4">
          <div className="overflow-x-auto rounded-lg border border-border">
            <Table>
              <TableHeader>
                <TableRow className="bg-muted/50 hover:bg-muted/50">
                  <TableHead className="text-xs font-semibold min-w-[260px]">Material</TableHead>
                  <TableHead className="text-xs font-semibold w-24">Tipo</TableHead>
                  {todosProveedores.map((prov) => (
                    <TableHead
                      key={prov}
                      className="text-xs font-semibold text-right min-w-[150px]"
                    >
                      <div className="inline-flex items-center justify-end gap-1">
                        <span>{prov}</span>
                        <button
                          type="button"
                          onClick={() => handleAbrirRenombrarProveedor(prov)}
                          className="p-0.5 rounded hover:bg-muted text-muted-foreground hover:text-foreground transition-colors"
                          title={`Renombrar proveedor ${prov}`}
                          aria-label={`Renombrar proveedor ${prov}`}
                        >
                          <Pencil className="h-3 w-3" />
                        </button>
                      </div>
                    </TableHead>
                  ))}
                </TableRow>
              </TableHeader>
              <TableBody className="divide-y divide-border/60">
                {materialesFiltrados.length === 0 ? (
                  <TableRow>
                    <TableCell
                      colSpan={2 + todosProveedores.length}
                      className="text-center py-8 text-xs text-muted-foreground"
                    >
                      No se encontraron materiales con los filtros aplicados.
                    </TableCell>
                  </TableRow>
                ) : (
                  materialesFiltrados.map((material) => {
                    const mejorPrecio = mejoresPreciosPorFila[material.id];
                    return (
                      <TableRow
                        key={material.id}
                        className="hover:bg-muted/30 transition-colors"
                      >
                        <TableCell className="py-2.5 font-medium text-xs text-foreground">
                          <div className="flex items-start justify-between gap-2">
                            <div className="min-w-0">
                              <div className="flex items-center gap-1.5 flex-wrap">
                                <span>{material.nombre}</span>
                                {!material.activo && (
                                  <Badge variant="secondary" className="text-[10px] py-0">
                                    Inactivo
                                  </Badge>
                                )}
                              </div>
                              {material.ancho_ft && material.largo_ft && (
                                <span className="text-[11px] text-muted-foreground block font-mono">
                                  {material.ancho_ft}&apos; × {material.largo_ft}&apos;
                                </span>
                              )}
                            </div>
                            <Button
                              variant="ghost"
                              size="icon"
                              onClick={() => handleAbrirEditarMaterial(material)}
                              className="h-6 w-6 shrink-0 text-muted-foreground hover:text-foreground"
                              title={`Editar material ${material.nombre}`}
                              aria-label={`Editar material ${material.nombre}`}
                            >
                              <Edit2 className="h-3 w-3" />
                            </Button>
                          </div>
                        </TableCell>

                        <TableCell className="py-2.5">
                          <Badge variant="outline" className="text-[10px] capitalize">
                            {material.tipo}
                          </Badge>
                        </TableCell>

                        {/* Celdas de precios por proveedor */}
                        {todosProveedores.map((prov) => {
                          const celdaKey = `${material.id}::${prov}`;
                          const editando = celdaEditando === celdaKey;
                          const precioObj = material.precios?.[prov];
                          const precioVal = precioObj?.precio;
                          const baseSinIva =
                            precioVal !== undefined
                              ? precioObj?.incluye_iva === false
                                ? precioVal
                                : precioVal / 1.16
                              : undefined;
                          const esElMejor =
                            mejorPrecio !== undefined &&
                            baseSinIva !== undefined &&
                            Math.abs(baseSinIva - mejorPrecio) < 0.01;

                          if (editando) {
                            return (
                              <TableCell
                                key={prov}
                                className="py-1 px-2 text-right bg-accent-blue/10 dark:bg-accent-blue/20"
                              >
                                <div className="flex flex-col items-end gap-1">
                                  <div className="flex items-center justify-end gap-1">
                                    <Input
                                      type="number"
                                      step="0.01"
                                      autoFocus
                                      value={valorEditando}
                                      onChange={(e) => setValorEditando(e.target.value)}
                                      onKeyDown={(e) => {
                                        if (e.key === 'Enter') {
                                          handleGuardarCelda(material.id, prov, precioVal);
                                        } else if (e.key === 'Escape') {
                                          setCeldaEditando(null);
                                        }
                                      }}
                                      className="text-xs font-mono h-7 w-24 text-right bg-background p-1"
                                    />
                                    <Button
                                      size="icon"
                                      variant="ghost"
                                      onClick={() =>
                                        handleGuardarCelda(material.id, prov, precioVal)
                                      }
                                      disabled={guardando}
                                      className="h-6 w-6 text-emerald-600"
                                      aria-label="Guardar precio"
                                    >
                                      <Check className="h-3.5 w-3.5" />
                                    </Button>
                                    {precioVal && (
                                      <Button
                                        size="icon"
                                        variant="ghost"
                                        onClick={() => handleEliminarPrecio(material.id, prov)}
                                        disabled={guardando}
                                        className="h-6 w-6 text-destructive"
                                        title="Eliminar precio"
                                      >
                                        <Trash2 className="h-3 w-3" />
                                      </Button>
                                    )}
                                    <Button
                                      size="icon"
                                      variant="ghost"
                                      onClick={() => setCeldaEditando(null)}
                                      className="h-6 w-6 text-muted-foreground"
                                    >
                                      <X className="h-3.5 w-3.5" />
                                    </Button>
                                  </div>
                                  <label className="inline-flex items-center gap-1 text-[10px] text-muted-foreground cursor-pointer">
                                    <Checkbox
                                      checked={incluyeIvaEditando}
                                      onCheckedChange={(v) => setIncluyeIvaEditando(Boolean(v))}
                                      className="h-3 w-3"
                                    />
                                    <span>{incluyeIvaEditando ? 'Incluye IVA' : 'Sin IVA'}</span>
                                  </label>
                                </div>
                              </TableCell>
                            );
                          }

                          return (
                            <TableCell
                              key={prov}
                              onClick={() =>
                                handleIniciarEdicion(
                                  material.id,
                                  prov,
                                  precioVal,
                                  precioObj?.incluye_iva
                                )
                              }
                              className={`py-2 px-3 text-right cursor-pointer group transition-colors ${
                                esElMejor
                                  ? 'bg-emerald-50/40 dark:bg-emerald-950/20 font-semibold text-emerald-700 dark:text-emerald-300'
                                  : 'hover:bg-muted/50'
                              }`}
                            >
                              <div className="flex flex-col items-end">
                                <div className="flex items-center justify-end gap-1.5">
                                  {precioVal ? (
                                    <>
                                      <span className="font-mono text-xs">
                                        {formatearMoneda(precioVal)}
                                      </span>
                                      {esElMejor && (
                                        <span
                                          className="h-1.5 w-1.5 rounded-full bg-emerald-500"
                                          title="Precio más económico"
                                        />
                                      )}
                                      <Edit2 className="h-3 w-3 opacity-0 group-hover:opacity-60 transition-opacity ml-1 text-muted-foreground" />
                                    </>
                                  ) : (
                                    <span className="text-muted-foreground/50 text-[11px] group-hover:text-foreground">
                                      + agregar
                                    </span>
                                  )}
                                </div>
                                {precioVal && (
                                  <div className="flex items-center justify-end gap-1 text-[10px] text-muted-foreground font-normal">
                                    <span>{precioObj?.incluye_iva === false ? 's/IVA' : 'c/IVA'}</span>
                                    {precioObj?.fuente && precioObj.fuente !== 'Manual' && (
                                      <span
                                        className="truncate max-w-[95px]"
                                        title={precioObj.fuente}
                                      >
                                        · {precioObj.fuente}
                                      </span>
                                    )}
                                  </div>
                                )}
                              </div>
                            </TableCell>
                          );
                        })}
                      </TableRow>
                    );
                  })
                )}
              </TableBody>
            </Table>
          </div>
        </CardContent>
      </Card>

      {/* Diálogo de Confirmación: Variación > 30% */}
      {alertaCambio && (
        <Dialog open={true} onOpenChange={() => setAlertaCambio(null)}>
          <DialogContent className="sm:max-w-md">
            <DialogHeader>
              <DialogTitle className="flex items-center gap-2 text-amber-600 dark:text-amber-400">
                <AlertTriangle className="h-5 w-5" />
                Variación de precio significativa
              </DialogTitle>
              <DialogDescription className="text-xs pt-1">
                El precio capturado varía más del <strong>{alertaCambio.porcentaje}%</strong> respecto al precio anterior registrado para <strong>{alertaCambio.proveedor}</strong>.
              </DialogDescription>
            </DialogHeader>

            <div className="p-3 rounded-lg border border-border bg-muted/40 space-y-2 text-xs">
              <div className="flex justify-between">
                <span className="text-muted-foreground">Precio anterior:</span>
                <span className="font-mono font-medium line-through text-muted-foreground">
                  {formatearMoneda(alertaCambio.precioAnterior)}
                </span>
              </div>
              <div className="flex justify-between font-bold">
                <span>Nuevo precio capturado:</span>
                <span className="font-mono text-foreground text-sm">
                  {formatearMoneda(alertaCambio.precioNuevo)}
                </span>
              </div>
            </div>

            <DialogFooter className="gap-2 sm:gap-0 pt-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => setAlertaCambio(null)}
              >
                Cancelar y corregir
              </Button>
              <Button
                size="sm"
                onClick={() =>
                  ejecutarGuardarPrecio(
                    alertaCambio.materialId,
                    alertaCambio.proveedor,
                    alertaCambio.precioNuevo,
                    alertaCambio.incluyeIva
                  )
                }
                disabled={guardando}
                className="bg-accent-blue text-white"
              >
                Confirmar y guardar
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      )}

      {/* Diálogo de Nuevo Material */}
      <Dialog open={modalNuevoMaterial} onOpenChange={setModalNuevoMaterial}>
        <DialogContent className="sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Layers className="h-5 w-5 text-accent-blue" />
              Nuevo Material de Acero
            </DialogTitle>
            <DialogDescription className="text-xs">
              El tipo y las medidas se detectan automáticamente a partir del nombre comercial.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2 text-xs">
            <div className="space-y-1.5">
              <Label className="text-xs">Nombre comercial del material</Label>
              <Input
                placeholder='Ej. Placa de grado A-36 de 1/4" en 4X10&apos;'
                value={nuevoMaterialNombre}
                onChange={(e) => {
                  const val = e.target.value;
                  setNuevoMaterialNombre(val);
                  if (!nuevoMaterialTipoManual) {
                    try {
                      setNuevoMaterialTipo(determinarTipoMaterial(val));
                    } catch {
                      // conservar tipo seleccionado
                    }
                  }
                }}
                className="text-xs"
              />
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs">Tipo de material</Label>
              <select
                aria-label="Tipo de nuevo material"
                value={nuevoMaterialTipo}
                onChange={(e) => {
                  setNuevoMaterialTipo(e.target.value as TipoMaterialAcero);
                  setNuevoMaterialTipoManual(true);
                }}
                className="w-full h-9 rounded-md border border-border bg-background px-2.5 text-xs text-foreground"
              >
                {TIPOS_MATERIAL_ACERO.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs">Notas u observaciones (opcional)</Label>
              <Input
                placeholder="Especificación especial, proveedor preferente, etc."
                value={nuevoMaterialNotas}
                onChange={(e) => setNuevoMaterialNotas(e.target.value)}
                className="text-xs"
              />
            </div>
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setModalNuevoMaterial(false)}
            >
              Cancelar
            </Button>
            <Button
              size="sm"
              onClick={handleCrearMaterial}
              disabled={guardando}
              className="bg-accent-blue text-white"
            >
              Crear material
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de Nuevo Proveedor */}
      <Dialog open={modalNuevoProveedor} onOpenChange={setModalNuevoProveedor}>
        <DialogContent className="sm:max-w-sm">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Building2 className="h-5 w-5 text-accent-blue" />
              Agregar Columna de Proveedor
            </DialogTitle>
            <DialogDescription className="text-xs">
              Agrega una nueva columna a la matriz de precios para capturar cotizaciones de este proveedor.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2 text-xs">
            <div className="space-y-1.5">
              <Label className="text-xs">Nombre del proveedor</Label>
              <Input
                placeholder="Ej. ACEROS DE ORIENTE"
                value={nuevoProveedorNombre}
                onChange={(e) => setNuevoProveedorNombre(e.target.value)}
                className="text-xs uppercase"
              />
            </div>
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setModalNuevoProveedor(false)}
            >
              Cancelar
            </Button>
            <Button
              size="sm"
              onClick={handleAgregarProveedor}
              className="bg-accent-blue text-white"
            >
              Agregar a la tabla
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de Historial de Cambios */}
      <Dialog open={modalHistorial} onOpenChange={setModalHistorial}>
        <DialogContent className="sm:max-w-2xl max-h-[80vh] flex flex-col">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <History className="h-5 w-5 text-accent-blue" />
              Historial de Cambios de Precios
            </DialogTitle>
            <DialogDescription className="text-xs">
              Registro de auditoría de cada modificación de precio capturada en el sistema.
            </DialogDescription>
          </DialogHeader>

          <div className="flex-1 overflow-y-auto py-2">
            {cargandoHistorial ? (
              <div className="py-12 text-center text-xs text-muted-foreground flex items-center justify-center gap-2">
                <RefreshCw className="h-4 w-4 animate-spin" />
                Cargando historial...
              </div>
            ) : historialItems.length === 0 ? (
              <div className="py-12 text-center text-xs text-muted-foreground">
                No hay cambios de precio registrados aún en el historial.
              </div>
            ) : (
              <div className="divide-y divide-border/60 text-xs">
                {historialItems.map((h) => (
                  <div key={h.id} className="py-2.5 flex items-start justify-between gap-4">
                    <div className="space-y-0.5">
                      <p className="font-medium text-foreground">
                        {h.material?.nombre || 'Material'}
                      </p>
                      <div className="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground">
                        <Badge variant="outline" className="text-[10px] py-0">
                          {h.proveedor}
                        </Badge>
                        {h.fuente && (
                          <Badge variant="secondary" className="text-[10px] py-0">
                            {h.fuente}
                          </Badge>
                        )}
                        {typeof h.incluye_iva === 'boolean' && (
                          <span className="text-[10px] font-mono">
                            {h.incluye_iva ? 'c/IVA' : 's/IVA'}
                          </span>
                        )}
                        <span>
                          {new Date(h.creado_el).toLocaleString('es-MX', {
                            dateStyle: 'medium',
                            timeStyle: 'short',
                          })}
                        </span>
                      </div>
                    </div>

                    <div className="text-right font-mono text-xs">
                      {h.precio_anterior ? (
                        <div>
                          <span className="text-muted-foreground line-through block text-[11px]">
                            {formatearMoneda(h.precio_anterior)}
                          </span>
                          <span className="font-semibold text-foreground">
                            {formatearMoneda(h.precio_nuevo)}
                          </span>
                        </div>
                      ) : (
                        <span className="font-semibold text-emerald-600 dark:text-emerald-400">
                          + {formatearMoneda(h.precio_nuevo)} (alta)
                        </span>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button
              variant="outline"
              size="sm"
              onClick={() => setModalHistorial(false)}
            >
              Cerrar
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de Editar Material */}
      <Dialog
        open={Boolean(materialEditando)}
        onOpenChange={(o) => {
          if (!o) setMaterialEditando(null);
        }}
      >
        <DialogContent className="sm:max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Edit2 className="h-4 w-4 text-accent-blue" />
              Editar Material de Acero
            </DialogTitle>
            <DialogDescription className="text-xs">
              Cambia el nombre, tipo, notas o estado del material. Renombrar no sobrescribe el tipo seleccionado.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2 text-xs">
            <div className="space-y-1.5">
              <Label className="text-xs">Nombre comercial</Label>
              <Input
                aria-label="Nombre del material"
                value={editMatNombre}
                onChange={(e) => setEditMatNombre(e.target.value)}
                className="text-xs bg-background"
              />
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs">Tipo de material</Label>
              <select
                aria-label="Tipo del material"
                value={editMatTipo}
                onChange={(e) => setEditMatTipo(e.target.value as TipoMaterialAcero)}
                className="w-full h-9 rounded-md border border-border bg-background px-2.5 text-xs text-foreground"
              >
                {TIPOS_MATERIAL_ACERO.map((t) => (
                  <option key={t.value} value={t.value}>
                    {t.label}
                  </option>
                ))}
              </select>
            </div>
            <div className="space-y-1.5">
              <Label className="text-xs">Notas</Label>
              <Input
                aria-label="Notas del material"
                value={editMatNotas}
                onChange={(e) => setEditMatNotas(e.target.value)}
                className="text-xs bg-background"
              />
            </div>
            <label className="flex items-center gap-2 text-xs text-foreground cursor-pointer">
              <Checkbox
                checked={editMatActivo}
                onCheckedChange={(v) => setEditMatActivo(Boolean(v))}
              />
              <span>Material activo en calculadora</span>
            </label>
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setMaterialEditando(null)}
              disabled={guardando}
            >
              Cancelar
            </Button>
            <Button
              size="sm"
              onClick={handleGuardarMaterialEditado}
              disabled={guardando}
              className="bg-accent-blue text-white"
            >
              Guardar cambios
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de Renombrar Proveedor */}
      <Dialog
        open={Boolean(proveedorRenombrando)}
        onOpenChange={(o) => {
          if (!o) {
            setProveedorRenombrando(null);
            setErrorRenombre(null);
          }
        }}
      >
        <DialogContent className="sm:max-w-md bg-card border-border">
          <DialogHeader>
            <DialogTitle className="flex items-center gap-2">
              <Pencil className="h-4 w-4 text-accent-blue" />
              Renombrar proveedor en matriz
            </DialogTitle>
            <DialogDescription className="text-xs">
              Esta acción cambiará el nombre de <strong>{proveedorRenombrando}</strong> en todos sus precios vigentes, historial y aplicaciones XML. Si el nuevo nombre ya tiene precios para el mismo material, se bloqueará para evitar sobrescribir datos.
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-3 py-2 text-xs">
            <div className="space-y-1.5">
              <Label className="text-xs">Nuevo nombre del proveedor</Label>
              <Input
                aria-label="Nuevo nombre del proveedor"
                value={renombreNuevo}
                onChange={(e) => {
                  setRenombreNuevo(e.target.value);
                  setErrorRenombre(null);
                }}
                className="text-xs bg-background"
              />
            </div>
            {errorRenombre && (
              <div
                role="alert"
                className="p-2.5 rounded-md border border-destructive/40 bg-destructive/10 text-destructive text-xs"
              >
                {errorRenombre}
              </div>
            )}
          </div>

          <DialogFooter className="gap-2 sm:gap-0">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setProveedorRenombrando(null)}
              disabled={guardando}
            >
              Cancelar
            </Button>
            <Button
              size="sm"
              onClick={handleConfirmarRenombrarProveedor}
              disabled={guardando || !renombreNuevo.trim()}
              className="bg-accent-blue text-white"
            >
              Renombrar proveedor
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Diálogo de Gestión de Alias XML */}
      <GestionAliasAceroModal
        open={modalAliasOpen}
        onOpenChange={setModalAliasOpen}
        supabase={supabase}
      />
    </div>
  );
}
