import React, { useState, useEffect, useMemo } from 'react';
import { supabase } from '../../utils/supabase/client';
import { crearOrdenProduccion } from '../../utils/tableroApi';
import { normalizarTextoBusqueda } from '../../utils/tableroProduccion';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
  DialogFooter,
} from '../ui/dialog';
import { Popover, PopoverContent, PopoverTrigger } from '../ui/popover';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '../ui/select';
import {
  Plus,
  Loader2,
  Check,
  ChevronsUpDown,
  Search,
  AlertCircle,
  RefreshCw,
} from 'lucide-react';
import { toast } from 'sonner';
import { cn } from '../ui/utils';

interface NuevoEquipoModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  lineaDefecto?: string;
  token?: string;
  onEquipoCreado: (orden: any) => Promise<void> | void;
}

interface ClienteOpcion {
  id: string;
  nombre: string;
  contacto?: string;
}

const MODELOS_POR_LINEA: Record<string, Array<{ tipo: string; modelo: string }>> = {
  plataforma: [
    { tipo: '01', modelo: 'Plataforma 40 ft 2 ejes' },
    { tipo: '01', modelo: 'Plataforma 40 ft 3 ejes' },
    { tipo: '01', modelo: 'Plataforma 43 ft 3 ejes' },
    { tipo: '01', modelo: 'Plataforma 48 ft 3 ejes' },
    { tipo: '01', modelo: 'Plataforma 53 ft 3 ejes' },
  ],
  gondola: [
    { tipo: '03', modelo: 'Góndola 30 m3 3 ejes' },
    { tipo: '03', modelo: 'Góndola 24 m3 2 ejes' },
    { tipo: '03', modelo: 'Góndola 30 m3 2 ejes' },
  ],
  dolly: [
    { tipo: '02', modelo: 'Dolly 2 ejes' },
    { tipo: '02', modelo: 'Dolly 1 eje' },
  ],
  traila: [
    { tipo: '09', modelo: 'Traila cuello de ganso' },
    { tipo: '09', modelo: 'Traila ganadera' },
  ],
};

export function NuevoEquipoModal({
  open,
  onOpenChange,
  lineaDefecto = 'plataforma',
  token,
  onEquipoCreado,
}: NuevoEquipoModalProps) {
  const [linea, setLinea] = useState<string>(lineaDefecto);
  const [modeloSeleccionado, setModeloSeleccionado] = useState<string>('');
  const [modeloPersonalizado, setModeloPersonalizado] = useState<string>('');
  const [clienteId, setClienteId] = useState<string>('ninguno');
  const [etiqueta, setEtiqueta] = useState<string>('');
  const [fechaCompromiso, setFechaCompromiso] = useState<string>('');
  const [observaciones, setObservaciones] = useState<string>('');
  const [guardando, setGuardando] = useState<boolean>(false);

  // Lista de clientes con buscador y manejo explícito de errores
  const [clientes, setClientes] = useState<ClienteOpcion[]>([]);
  const [cargandoClientes, setCargandoClientes] = useState<boolean>(false);
  const [errorClientes, setErrorClientes] = useState<string | null>(null);
  const [busquedaCliente, setBusquedaCliente] = useState<string>('');
  const [popoverClienteAbierto, setPopoverClienteAbierto] = useState<boolean>(false);

  const cargarClientes = async () => {
    try {
      setCargandoClientes(true);
      setErrorClientes(null);
      // Consulta únicamente columnas reales del esquema: id, nombre_razon_social, nombre_contacto
      const { data, error } = await supabase
        .from('clientes')
        .select('id, nombre_razon_social, nombre_contacto')
        .order('nombre_razon_social');

      if (error) {
        console.error('[NuevoEquipoModal] Error al consultar clientes:', error);
        setErrorClientes(error.message || 'Error al consultar clientes');
        return;
      }

      if (data) {
        const list: ClienteOpcion[] = data.map((c: any) => ({
          id: c.id,
          nombre: c.nombre_razon_social || c.nombre_contacto || 'Cliente sin nombre',
          contacto: c.nombre_contacto || undefined,
        }));
        setClientes(list);
      }
    } catch (err: any) {
      console.error('[NuevoEquipoModal] Excepción al consultar clientes:', err);
      setErrorClientes(err?.message || 'Error de conexión al cargar clientes');
    } finally {
      setCargandoClientes(false);
    }
  };

  // Sincronizar línea inicial al abrir
  useEffect(() => {
    if (open) {
      const l = lineaDefecto || 'plataforma';
      setLinea(l);
      const opciones = MODELOS_POR_LINEA[l] || [];
      setModeloSeleccionado(opciones[0]?.modelo || 'otro');
      setModeloPersonalizado('');
      setClienteId('ninguno');
      setEtiqueta('');
      setFechaCompromiso('');
      setObservaciones('');
      setBusquedaCliente('');
      setPopoverClienteAbierto(false);

      cargarClientes();
    }
  }, [open, lineaDefecto]);

  // Al cambiar línea, actualizar modelo
  const handleCambioLinea = (nuevaLinea: string) => {
    setLinea(nuevaLinea);
    const opciones = MODELOS_POR_LINEA[nuevaLinea] || [];
    setModeloSeleccionado(opciones[0]?.modelo || 'otro');
  };

  // Al seleccionar cliente, si no hay etiqueta prellenar sugerencia
  const handleCambioCliente = (cId: string) => {
    setClienteId(cId);
    if (cId !== 'ninguno') {
      const cli = clientes.find((c) => c.id === cId);
      if (cli && (!etiqueta || etiqueta.startsWith('Inventario'))) {
        setEtiqueta(cli.nombre);
      }
    }
  };

  const clienteSeleccionadoObj = useMemo(
    () => clientes.find((c) => c.id === clienteId),
    [clientes, clienteId]
  );

  const clientesFiltrados = useMemo(() => {
    const q = normalizarTextoBusqueda(busquedaCliente);
    if (!q) return clientes;
    return clientes.filter(
      (c) =>
        normalizarTextoBusqueda(c.nombre).includes(q) ||
        (c.contacto && normalizarTextoBusqueda(c.contacto).includes(q))
    );
  }, [clientes, busquedaCliente]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    const etiquetaFinal = etiqueta.trim();
    if (!etiquetaFinal && clienteId === 'ninguno') {
      toast.error('Debes ingresar una etiqueta identificadora o seleccionar un cliente');
      return;
    }

    const modelos = MODELOS_POR_LINEA[linea] || [];
    const itemModelo = modelos.find((m) => m.modelo === modeloSeleccionado);
    const tipoEquipo = itemModelo?.tipo || '01';
    const modeloFinal =
      modeloSeleccionado === 'otro'
        ? modeloPersonalizado.trim() || 'Equipo estándar'
        : modeloSeleccionado;

    try {
      setGuardando(true);
      const resp = await crearOrdenProduccion(
        {
          linea,
          tipo_equipo: tipoEquipo,
          modelo: modeloFinal,
          etiqueta: etiquetaFinal || undefined,
          cliente_id: clienteId !== 'ninguno' ? clienteId : null,
          fecha_compromiso: fechaCompromiso || null,
          caracteristicas: observaciones.trim()
            ? { observaciones: observaciones.trim() }
            : undefined,
        },
        token
      );

      toast.success('Equipo en planta registrado exitosamente');
      onOpenChange(false);
      await onEquipoCreado(resp.orden);
    } catch (err: any) {
      console.error('[NuevoEquipoModal] Error al crear equipo:', err);
      toast.error('Error al registrar equipo', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  const modelosDisponibles = MODELOS_POR_LINEA[linea] || [];

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent
        className="sm:max-w-md bg-card text-card-foreground border-border"
      >
        <DialogHeader>
          <DialogTitle className="text-base font-bold text-foreground">
            Nuevo equipo en planta
          </DialogTitle>
          <DialogDescription className="text-xs text-muted-foreground">
            Registra una unidad directamente en producción sin cotización previa.
          </DialogDescription>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-3.5 py-2">
          {/* Línea de Producto */}
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Línea de producción</Label>
            <Select value={linea} onValueChange={handleCambioLinea}>
              <SelectTrigger className="h-8 text-xs">
                <SelectValue placeholder="Selecciona una línea" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="plataforma">Plataforma</SelectItem>
                <SelectItem value="gondola">Góndola</SelectItem>
                <SelectItem value="dolly">Dolly</SelectItem>
                <SelectItem value="traila">Traila</SelectItem>
              </SelectContent>
            </Select>
          </div>

          {/* Modelo */}
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Modelo</Label>
            <Select
              value={modeloSeleccionado}
              onValueChange={(val) => setModeloSeleccionado(val)}
            >
              <SelectTrigger className="h-8 text-xs">
                <SelectValue placeholder="Selecciona un modelo" />
              </SelectTrigger>
              <SelectContent>
                {modelosDisponibles.map((m) => (
                  <SelectItem key={m.modelo} value={m.modelo}>
                    {m.modelo}
                  </SelectItem>
                ))}
                <SelectItem value="otro">Otro modelo (personalizado)</SelectItem>
              </SelectContent>
            </Select>

            {modeloSeleccionado === 'otro' && (
              <Input
                placeholder="Nombre o descripción del modelo..."
                value={modeloPersonalizado}
                onChange={(e) => setModeloPersonalizado(e.target.value)}
                className="h-8 text-xs mt-1"
                autoFocus
              />
            )}
          </div>

          {/* Cliente (Opcional) con Buscador / Combobox */}
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <Label className="text-xs text-muted-foreground">Cliente (opcional)</Label>
              {cargandoClientes && (
                <span className="text-[11px] text-muted-foreground flex items-center gap-1">
                  <Loader2 className="w-3 h-3 animate-spin" /> Cargando...
                </span>
              )}
            </div>

            {errorClientes && (
              <div className="p-2 rounded-md bg-destructive/10 border border-destructive/30 text-destructive text-xs flex items-center justify-between gap-2">
                <div className="flex items-center gap-1.5 truncate">
                  <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                  <span className="truncate">{errorClientes}</span>
                </div>
                <Button
                  type="button"
                  variant="outline"
                  size="sm"
                  className="h-6 text-[11px] px-2 shrink-0 border-destructive/40 hover:bg-destructive/20 text-destructive"
                  onClick={cargarClientes}
                >
                  <RefreshCw className="w-2.5 h-2.5 mr-1" /> Reintentar
                </Button>
              </div>
            )}

            <Popover open={popoverClienteAbierto} onOpenChange={setPopoverClienteAbierto}>
              <PopoverTrigger asChild>
                <Button
                  type="button"
                  variant="outline"
                  role="combobox"
                  aria-expanded={popoverClienteAbierto}
                  disabled={cargandoClientes}
                  className="w-full justify-between h-8 text-xs font-normal border-border bg-background"
                >
                  <span className="truncate">
                    {clienteSeleccionadoObj
                      ? clienteSeleccionadoObj.nombre
                      : clienteId === 'ninguno'
                      ? 'Sin cliente (Inventario)'
                      : 'Seleccionar cliente...'}
                  </span>
                  <ChevronsUpDown className="w-3.5 h-3.5 ml-2 shrink-0 opacity-50" />
                </Button>
              </PopoverTrigger>
              <PopoverContent
                className="w-[320px] sm:w-[400px] p-2 bg-popover text-popover-foreground shadow-lg border border-border"
                align="start"
              >
                <div className="space-y-2">
                  <div className="relative">
                    <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 w-3.5 h-3.5 text-muted-foreground" />
                    <Input
                      placeholder="Buscar por razón social o contacto..."
                      value={busquedaCliente}
                      onChange={(e) => setBusquedaCliente(e.target.value)}
                      className="pl-8 h-7 text-xs bg-muted/40"
                      autoFocus
                    />
                  </div>

                  <div className="max-h-56 overflow-y-auto space-y-0.5 divide-y divide-border/30">
                    {/* Opción Sin cliente */}
                    <button
                      type="button"
                      className={cn(
                        'w-full text-left px-2 py-1.5 rounded-sm text-xs flex items-center justify-between hover:bg-accent hover:text-accent-foreground cursor-pointer',
                        clienteId === 'ninguno' && 'bg-accent/60 font-semibold text-accent-foreground'
                      )}
                      onClick={() => {
                        handleCambioCliente('ninguno');
                        setPopoverClienteAbierto(false);
                        setBusquedaCliente('');
                      }}
                    >
                      <span>Sin cliente (Inventario)</span>
                      {clienteId === 'ninguno' && <Check className="w-3.5 h-3.5 text-primary" />}
                    </button>

                    {clientesFiltrados.length === 0 ? (
                      <div className="py-4 text-center text-xs text-muted-foreground">
                        {clientes.length === 0
                          ? 'No hay clientes registrados'
                          : 'No se encontraron clientes'}
                      </div>
                    ) : (
                      clientesFiltrados.map((c) => (
                        <button
                          key={c.id}
                          type="button"
                          className={cn(
                            'w-full text-left px-2 py-1.5 rounded-sm text-xs flex items-center justify-between hover:bg-accent hover:text-accent-foreground cursor-pointer',
                            clienteId === c.id &&
                              'bg-accent/60 font-semibold text-accent-foreground'
                          )}
                          onClick={() => {
                            handleCambioCliente(c.id);
                            setPopoverClienteAbierto(false);
                            setBusquedaCliente('');
                          }}
                        >
                          <div className="truncate pr-2">
                            <p className="truncate text-foreground font-medium">{c.nombre}</p>
                            {c.contacto && (
                              <p className="truncate text-[10px] text-muted-foreground">
                                Contacto: {c.contacto}
                              </p>
                            )}
                          </div>
                          {clienteId === c.id && (
                            <Check className="w-3.5 h-3.5 text-primary shrink-0" />
                          )}
                        </button>
                      ))
                    )}
                  </div>
                </div>
              </PopoverContent>
            </Popover>
          </div>

          {/* Etiqueta visible */}
          <div className="space-y-1">
            <div className="flex items-center justify-between">
              <Label className="text-xs text-muted-foreground">
                Etiqueta / Identificador visible
              </Label>
              {clienteId === 'ninguno' && (
                <span className="text-[10px] text-destructive font-medium">Obligatorio</span>
              )}
            </div>
            <Input
              placeholder="Ej. Transportes Azteca #1 o Plana Stock Noviembre"
              value={etiqueta}
              onChange={(e) => setEtiqueta(e.target.value)}
              className="h-8 text-xs"
              required={clienteId === 'ninguno'}
            />
          </div>

          {/* Fecha compromiso */}
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Fecha de compromiso (opcional)</Label>
            <Input
              type="date"
              value={fechaCompromiso}
              onChange={(e) => setFechaCompromiso(e.target.value)}
              className="h-8 text-xs"
            />
          </div>

          {/* Observaciones */}
          <div className="space-y-1">
            <Label className="text-xs text-muted-foreground">Observaciones (opcional)</Label>
            <Input
              placeholder="Notas técnicas o de armado..."
              value={observaciones}
              onChange={(e) => setObservaciones(e.target.value)}
              className="h-8 text-xs"
            />
          </div>

          <DialogFooter className="pt-2">
            <Button
              type="button"
              variant="outline"
              size="sm"
              onClick={() => onOpenChange(false)}
              className="h-8 text-xs"
              disabled={guardando}
            >
              Cancelar
            </Button>
            <Button
              type="submit"
              variant="default"
              size="sm"
              className="h-8 text-xs font-semibold bg-primary text-primary-foreground hover:bg-primary/90"
              disabled={guardando}
            >
              {guardando ? (
                <>
                  <Loader2 className="w-3.5 h-3.5 mr-1.5 animate-spin" />
                  Creando...
                </>
              ) : (
                <>
                  <Plus className="w-3.5 h-3.5 mr-1.5" />
                  Registrar en planta
                </>
              )}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  );
}
