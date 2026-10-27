import React, { useState, useMemo } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
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
import { UserPlus, Edit2, Search, Power, Phone, Briefcase } from 'lucide-react';
import { toast } from 'sonner';
import { OperarioRef, PlanTarea } from '../../utils/planProduccion';

interface OperariosManagerProps {
  operarios: OperarioRef[];
  tareasSemana: PlanTarea[];
  cargando: boolean;
  onCrearOperario: (payload: { nombre: string; puesto?: string; telefono?: string; notas?: string }) => Promise<void>;
  onActualizarOperario: (id: string, payload: { nombre?: string; puesto?: string; telefono?: string; activo?: boolean; notas?: string }) => Promise<void>;
}

export function OperariosManager({
  operarios,
  tareasSemana,
  cargando,
  onCrearOperario,
  onActualizarOperario,
}: OperariosManagerProps) {
  const [busqueda, setBusqueda] = useState('');
  const [modalAbierto, setModalAbierto] = useState(false);
  const [operarioEditando, setOperarioEditando] = useState<OperarioRef | null>(null);

  const [nombre, setNombre] = useState('');
  const [puesto, setPuesto] = useState('');
  const [telefono, setTelefono] = useState('');
  const [notas, setNotas] = useState('');
  const [guardando, setGuardando] = useState(false);

  // Conteo de tareas por operario en la semana
  const tareasPorOperario = useMemo(() => {
    const mapa: Record<string, number> = {};
    for (const t of tareasSemana) {
      if (t.estado === 'cancelada') continue;
      for (const op of t.operarios || []) {
        const opId = typeof op === 'string' ? op : op.id;
        if (opId) {
          mapa[opId] = (mapa[opId] || 0) + 1;
        }
      }
    }
    return mapa;
  }, [tareasSemana]);

  const operariosFiltrados = useMemo(() => {
    const q = busqueda.toLowerCase().trim();
    if (!q) return operarios;
    return operarios.filter(
      (o) =>
        o.nombre?.toLowerCase().includes(q) ||
        o.puesto?.toLowerCase().includes(q) ||
        o.telefono?.includes(q)
    );
  }, [operarios, busqueda]);

  const abrirModalCrear = () => {
    setOperarioEditando(null);
    setNombre('');
    setPuesto('');
    setTelefono('');
    setNotas('');
    setModalAbierto(true);
  };

  const abrirModalEditar = (op: OperarioRef) => {
    setOperarioEditando(op);
    setNombre(op.nombre || '');
    setPuesto(op.puesto || '');
    setTelefono(op.telefono || '');
    setNotas((op as any).notas || '');
    setModalAbierto(true);
  };

  const handleToggleActivo = async (op: OperarioRef) => {
    const nuevoEstado = !op.activo;
    try {
      await onActualizarOperario(op.id, { activo: nuevoEstado });
      toast.success(
        nuevoEstado
          ? `Operario "${op.nombre}" activado`
          : `Operario "${op.nombre}" desactivado`
      );
    } catch (err: any) {
      toast.error('Error al cambiar estado del operario', { description: err.message });
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!nombre.trim()) {
      toast.error('El nombre del operario es obligatorio');
      return;
    }

    try {
      setGuardando(true);
      if (operarioEditando) {
        await onActualizarOperario(operarioEditando.id, {
          nombre: nombre.trim(),
          puesto: puesto.trim() || undefined,
          telefono: telefono.trim() || undefined,
          notas: notas.trim() || undefined,
        });
        toast.success(`Operario "${nombre.trim()}" actualizado`);
      } else {
        await onCrearOperario({
          nombre: nombre.trim(),
          puesto: puesto.trim() || undefined,
          telefono: telefono.trim() || undefined,
          notas: notas.trim() || undefined,
        });
        toast.success(`Operario "${nombre.trim()}" creado exitosamente`);
      }
      setModalAbierto(false);
    } catch (err: any) {
      toast.error('Error al guardar operario', { description: err.message });
    } finally {
      setGuardando(false);
    }
  };

  return (
    <div className="space-y-4">
      {/* Cabecera y Acciones */}
      <div className="bg-card border border-border/50 rounded-xl p-4 shadow-sm flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h2 className="text-base font-bold text-foreground">Catálogo de Operarios de Taller</h2>
          <p className="text-xs text-muted-foreground">
            Personal de producción disponible para asignación en el plan semanal.
          </p>
        </div>

        <div className="flex items-center gap-2">
          <div className="relative w-64">
            <Search className="w-3.5 h-3.5 absolute left-2.5 top-2.5 text-muted-foreground" />
            <Input
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              placeholder="Buscar por nombre o puesto..."
              className="bg-background text-xs pl-8 h-8"
            />
          </div>

          <Button
            size="sm"
            onClick={abrirModalCrear}
            className="h-8 text-xs gap-1.5 bg-primary text-primary-foreground font-semibold"
          >
            <UserPlus className="w-3.5 h-3.5" />
            Nuevo Operario
          </Button>
        </div>
      </div>

      {/* Tabla de Operarios */}
      <Card className="border-border/50 bg-card overflow-hidden">
        <div className="overflow-x-auto">
          <Table className="text-xs">
            <TableHeader className="bg-muted/30">
              <TableRow className="border-border/50">
                <TableHead className="font-bold text-foreground">Nombre</TableHead>
                <TableHead className="font-bold text-foreground">Puesto / Especialidad</TableHead>
                <TableHead className="font-bold text-foreground">Teléfono</TableHead>
                <TableHead className="font-bold text-foreground text-center">Estado</TableHead>
                <TableHead className="font-bold text-foreground text-center">Tareas esta semana</TableHead>
                <TableHead className="font-bold text-foreground text-right">Acciones</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {operariosFiltrados.map((op) => {
                const numTareas = tareasPorOperario[op.id] || 0;
                return (
                  <TableRow key={op.id} className="border-border/40 hover:bg-muted/10 transition-colors">
                    <TableCell className="font-semibold text-foreground py-2.5">
                      {op.nombre}
                    </TableCell>
                    <TableCell className="text-muted-foreground py-2.5">
                      {op.puesto ? (
                        <span className="flex items-center gap-1.5">
                          <Briefcase className="w-3 h-3 text-muted-foreground/70" />
                          {op.puesto}
                        </span>
                      ) : (
                        <span className="italic text-muted-foreground/50">Sin puesto</span>
                      )}
                    </TableCell>
                    <TableCell className="text-muted-foreground py-2.5 font-mono">
                      {op.telefono ? (
                        <span className="flex items-center gap-1.5">
                          <Phone className="w-3 h-3 text-muted-foreground/70" />
                          {op.telefono}
                        </span>
                      ) : (
                        <span className="italic text-muted-foreground/50">-</span>
                      )}
                    </TableCell>
                    <TableCell className="text-center py-2.5">
                      <Badge
                        variant="outline"
                        className={`text-[10px] ${
                          op.activo
                            ? 'bg-accent-green/20 text-accent-green border-accent-green/30'
                            : 'bg-muted/40 text-muted-foreground border-border/50'
                        }`}
                      >
                        {op.activo ? 'Activo' : 'Inactivo'}
                      </Badge>
                    </TableCell>
                    <TableCell className="text-center py-2.5 font-mono font-bold">
                      <span className={`px-2 py-0.5 rounded ${numTareas > 0 ? 'bg-primary/10 text-primary' : 'text-muted-foreground'}`}>
                        {numTareas}
                      </span>
                    </TableCell>
                    <TableCell className="text-right py-2.5">
                      <div className="flex items-center justify-end gap-1">
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => abrirModalEditar(op)}
                          className="h-7 w-7 text-muted-foreground hover:text-foreground"
                          title="Editar datos del operario"
                        >
                          <Edit2 className="w-3.5 h-3.5" />
                        </Button>
                        <Button
                          variant="ghost"
                          size="icon"
                          onClick={() => handleToggleActivo(op)}
                          className={`h-7 w-7 ${
                            op.activo
                              ? 'text-muted-foreground hover:text-accent-yellow'
                              : 'text-muted-foreground hover:text-accent-green'
                          }`}
                          title={op.activo ? 'Desactivar operario' : 'Activar operario'}
                        >
                          <Power className="w-3.5 h-3.5" />
                        </Button>
                      </div>
                    </TableCell>
                  </TableRow>
                );
              })}
              {operariosFiltrados.length === 0 && (
                <TableRow>
                  <TableCell colSpan={6} className="text-center py-8 text-muted-foreground italic">
                    {cargando ? 'Cargando operarios...' : 'No se encontraron operarios registrados'}
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </div>
      </Card>

      {/* Modal Alta / Edición de Operario */}
      <Dialog open={modalAbierto} onOpenChange={setModalAbierto}>
        <DialogContent className="max-w-md bg-card border-border text-foreground">
          <DialogHeader>
            <DialogTitle className="text-base font-bold flex items-center gap-2">
              <UserPlus className="w-4 h-4 text-primary" />
              {operarioEditando ? 'Editar Operario' : 'Nuevo Operario'}
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              {operarioEditando
                ? 'Actualiza los datos del personal de taller.'
                : 'Registra a un nuevo trabajador para el plan semanal.'}
            </DialogDescription>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-3 py-2 text-xs">
            <div>
              <Label className="text-xs font-semibold">Nombre Completo *</Label>
              <Input
                value={nombre}
                onChange={(e) => setNombre(e.target.value)}
                placeholder="Ej. Pedro Gómez Álvarez"
                className="bg-background mt-1 text-xs"
                required
                autoFocus
              />
            </div>

            <div>
              <Label className="text-xs font-semibold">Puesto / Especialidad</Label>
              <Input
                value={puesto}
                onChange={(e) => setPuesto(e.target.value)}
                placeholder="Ej. Soldador de baras, Pintor, Armador..."
                className="bg-background mt-1 text-xs"
              />
            </div>

            <div>
              <Label className="text-xs font-semibold">Teléfono de Contacto</Label>
              <Input
                value={telefono}
                onChange={(e) => setTelefono(e.target.value)}
                placeholder="Ej. 81 1234 5678"
                className="bg-background mt-1 text-xs font-mono"
              />
            </div>

            <div>
              <Label className="text-xs font-semibold">Notas Adicionales</Label>
              <Input
                value={notas}
                onChange={(e) => setNotas(e.target.value)}
                placeholder="Observaciones de turno, certificaciones..."
                className="bg-background mt-1 text-xs"
              />
            </div>

            <DialogFooter className="gap-2 pt-2">
              <Button
                type="button"
                variant="outline"
                size="sm"
                onClick={() => setModalAbierto(false)}
                disabled={guardando}
                className="text-xs h-8"
              >
                Cancelar
              </Button>
              <Button
                type="submit"
                size="sm"
                disabled={guardando || !nombre.trim()}
                className="text-xs h-8 bg-primary text-primary-foreground font-semibold"
              >
                {guardando ? 'Guardando...' : operarioEditando ? 'Guardar Cambios' : 'Registrar Operario'}
              </Button>
            </DialogFooter>
          </form>
        </DialogContent>
      </Dialog>
    </div>
  );
}
