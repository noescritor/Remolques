import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Badge } from '../ui/badge';
import { Plus, Trash2, Edit, BookTemplate, Copy } from 'lucide-react';
import { Plantilla, ItemCotizacion } from '../../types';
import { formatearMoneda } from '../../utils/calculations';

interface PlantillasListProps {
  plantillas: Plantilla[];
  loading: boolean;
  onCrearPlantilla: (p: Omit<Plantilla, 'id' | 'created_at'>) => Promise<Plantilla>;
  onActualizarPlantilla: (id: string, p: Partial<Plantilla>) => Promise<void>;
  onEliminarPlantilla: (id: string) => Promise<void>;
}

const emptyForm = (): Omit<Plantilla, 'id' | 'created_at'> => ({
  nombre: '',
  descripcion: '',
  items: [],
  nota: '',
  con_factura: true
});

export function PlantillasList({
  plantillas,
  loading,
  onCrearPlantilla,
  onActualizarPlantilla,
  onEliminarPlantilla
}: PlantillasListProps) {
  const [modalOpen, setModalOpen] = useState(false);
  const [editando, setEditando] = useState<Plantilla | null>(null);
  const [form, setForm] = useState(emptyForm());
  const [eliminandoId, setEliminandoId] = useState<string | null>(null);
  const [guardando, setGuardando] = useState(false);

  const abrirCrear = () => {
    setEditando(null);
    setForm(emptyForm());
    setModalOpen(true);
  };

  const abrirEditar = (p: Plantilla) => {
    setEditando(p);
    setForm({ nombre: p.nombre, descripcion: p.descripcion || '', items: p.items, nota: p.nota || '', con_factura: p.con_factura ?? true });
    setModalOpen(true);
  };

  const handleGuardar = async () => {
    if (!form.nombre.trim()) return;
    setGuardando(true);
    try {
      if (editando) {
        await onActualizarPlantilla(editando.id, form);
      } else {
        await onCrearPlantilla(form);
      }
      setModalOpen(false);
    } finally {
      setGuardando(false);
    }
  };

  const totalItems = (items: ItemCotizacion[]) =>
    items.reduce((s, i) => s + (i.total_item || 0), 0);

  if (loading) {
    return (
      <div className="space-y-4">
        {[1, 2, 3].map(i => (
          <div key={i} className="h-32 bg-gray-100 animate-pulse rounded-lg" />
        ))}
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Plantillas</h1>
          <p className="text-sm text-gray-500 mt-1">Reutiliza listas de conceptos en nuevas cotizaciones</p>
        </div>
        <Button onClick={abrirCrear} className="bg-blue-600 hover:bg-blue-700">
          <Plus className="mr-2 h-4 w-4" />
          Nueva Plantilla
        </Button>
      </div>

      {/* Lista */}
      {plantillas.length === 0 ? (
        <div className="flex flex-col items-center justify-center py-20 text-gray-400 gap-4">
          <BookTemplate className="w-16 h-16 opacity-30" />
          <p className="text-lg font-medium">Sin plantillas todavía</p>
          <p className="text-sm text-center max-w-xs">
            Crea una plantilla con conceptos frecuentes y úsala al crear cualquier cotización para ahorrar tiempo.
          </p>
          <Button onClick={abrirCrear} variant="outline">
            <Plus className="mr-2 h-4 w-4" />
            Crear primera plantilla
          </Button>
        </div>
      ) : (
        <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
          {plantillas.map(p => (
            <Card key={p.id} className="hover:shadow-md transition-shadow">
              <CardHeader className="pb-2">
                <div className="flex items-start justify-between gap-2">
                  <CardTitle className="text-base leading-snug">{p.nombre}</CardTitle>
                  <div className="flex gap-1 shrink-0">
                    <Button variant="ghost" size="icon" className="h-7 w-7" onClick={() => abrirEditar(p)}>
                      <Edit className="h-3.5 w-3.5" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-red-500 hover:text-red-700"
                      onClick={() => setEliminandoId(p.id)}
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>
                {p.descripcion && (
                  <p className="text-xs text-gray-500 line-clamp-2">{p.descripcion}</p>
                )}
              </CardHeader>
              <CardContent className="pt-0 space-y-3">
                <div className="flex items-center gap-2 flex-wrap">
                  <Badge variant="secondary">{p.items.length} concepto{p.items.length !== 1 ? 's' : ''}</Badge>
                  {p.con_factura && <Badge variant="outline" className="text-xs">Con IVA</Badge>}
                  {totalItems(p.items) > 0 && (
                    <span className="text-xs text-gray-500 ml-auto">{formatearMoneda(totalItems(p.items))}</span>
                  )}
                </div>
                {p.items.slice(0, 3).map((item, idx) => (
                  <div key={idx} className="text-xs text-gray-600 flex justify-between">
                    <span className="truncate flex-1 mr-2">{item.descripcion || '(sin descripción)'}</span>
                    <span className="shrink-0 text-gray-400">×{item.cantidad}</span>
                  </div>
                ))}
                {p.items.length > 3 && (
                  <p className="text-xs text-gray-400">+{p.items.length - 3} más…</p>
                )}
              </CardContent>
            </Card>
          ))}
        </div>
      )}

      {/* Modal crear / editar */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-lg">
          <DialogHeader>
            <DialogTitle>{editando ? 'Editar Plantilla' : 'Nueva Plantilla'}</DialogTitle>
            <DialogDescription>
              {editando
                ? 'Modifica los datos de la plantilla.'
                : 'Dale un nombre descriptivo. Podrás agregar los conceptos desde el editor de cotizaciones.'}
            </DialogDescription>
          </DialogHeader>

          <div className="space-y-4 py-2">
            <div>
              <Label>Nombre *</Label>
              <Input
                placeholder="Ej: Diseño de identidad corporativa"
                value={form.nombre}
                onChange={e => setForm(f => ({ ...f, nombre: e.target.value }))}
              />
            </div>
            <div>
              <Label>Descripción</Label>
              <Input
                placeholder="Breve descripción del tipo de proyecto"
                value={form.descripcion}
                onChange={e => setForm(f => ({ ...f, descripcion: e.target.value }))}
              />
            </div>
            <div>
              <Label>Nota por defecto</Label>
              <Textarea
                placeholder="Nota que aparecerá al usar esta plantilla"
                value={form.nota}
                onChange={e => setForm(f => ({ ...f, nota: e.target.value }))}
                rows={3}
              />
            </div>
            {editando && form.items.length > 0 && (
              <div className="rounded-md border p-3 bg-gray-50 space-y-1">
                <p className="text-xs font-medium text-gray-600 mb-2">{form.items.length} conceptos guardados</p>
                {form.items.map((item, i) => (
                  <div key={i} className="text-xs text-gray-700 flex justify-between">
                    <span className="truncate">{item.descripcion}</span>
                    <span className="text-gray-400 ml-2">×{item.cantidad}</span>
                  </div>
                ))}
              </div>
            )}
          </div>

          <DialogFooter>
            <Button variant="outline" onClick={() => setModalOpen(false)}>Cancelar</Button>
            <Button onClick={handleGuardar} disabled={!form.nombre.trim() || guardando}>
              {guardando ? 'Guardando…' : editando ? 'Guardar cambios' : 'Crear plantilla'}
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Confirmar eliminación */}
      <AlertDialog open={!!eliminandoId} onOpenChange={open => !open && setEliminandoId(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar plantilla?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción no se puede deshacer. Las cotizaciones creadas con esta plantilla no se verán afectadas.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              className="bg-red-600 hover:bg-red-700"
              onClick={async () => {
                if (eliminandoId) await onEliminarPlantilla(eliminandoId);
                setEliminandoId(null);
              }}
            >
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
