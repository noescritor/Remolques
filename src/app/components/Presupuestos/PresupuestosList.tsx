import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Plus, Search, FileText, Trash2, Printer } from 'lucide-react';
import { Input } from '../ui/input';
import { Presupuesto, Cliente } from '../../types';
import { PresupuestoEditor } from './PresupuestoEditor';
import { PresupuestoPDF } from './PresupuestoPDF';
import { pdf } from '@react-pdf/renderer';

interface Props {
  presupuestos: Presupuesto[];
  clientes: Cliente[];
  loading: boolean;
  onSave: (presu: Partial<Presupuesto>) => Promise<any>;
  onUpdate: (id: string, presu: Partial<Presupuesto>) => Promise<any>;
  onDelete: (id: string) => Promise<void>;
}

export function PresupuestosList({ presupuestos, clientes, loading, onSave, onUpdate, onDelete }: Props) {
  const [searchTerm, setSearchTerm] = useState('');
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [selectedPresupuesto, setSelectedPresupuesto] = useState<Presupuesto | null>(null);

  const handleEdit = (presu: Presupuesto) => {
    setSelectedPresupuesto(presu);
    setIsEditorOpen(true);
  };

  const handleCreate = () => {
    setSelectedPresupuesto(null);
    setIsEditorOpen(true);
  };

  const handlePrint = async (presu: Presupuesto) => {
    const cliente = clientes.find(c => c.id === presu.cliente_id);
    const blob = await pdf(<PresupuestoPDF presupuesto={presu} cliente={cliente} />).toBlob();
    const url = URL.createObjectURL(blob);
    window.open(url, '_blank');
  };

  const filtered = presupuestos.filter(p => 
    p.folio.toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.concepto && p.concepto.toLowerCase().includes(searchTerm.toLowerCase()))
  );

  if (isEditorOpen) {
    return (
      <PresupuestoEditor 
        presupuesto={selectedPresupuesto}
        clientes={clientes}
        onSave={onSave}
        onUpdate={onUpdate}
        onClose={() => setIsEditorOpen(false)}
      />
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Presupuestos / Órdenes de Fabricación</h2>
          <p className="text-muted-foreground">Gestiona las hojas de costos antes de cotizar.</p>
        </div>
        <Button onClick={handleCreate}>
          <Plus className="mr-2 h-4 w-4" /> Nuevo Presupuesto
        </Button>
      </div>

      <Card>
        <CardHeader>
          <div className="flex justify-between items-center">
            <CardTitle>Listado de Presupuestos</CardTitle>
            <div className="relative w-64">
              <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
              <Input
                placeholder="Buscar por folio o concepto..."
                className="pl-8"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
              />
            </div>
          </div>
        </CardHeader>
        <CardContent>
          <div className="rounded-md border">
            <div className="grid grid-cols-6 p-4 text-sm font-medium border-b bg-muted/50">
              <div className="col-span-1">Folio</div>
              <div className="col-span-1">Fecha</div>
              <div className="col-span-2">Concepto / Nomenclatura</div>
              <div className="col-span-1 text-right">Precio Venta</div>
              <div className="col-span-1 text-center">Acciones</div>
            </div>
            
            {loading ? (
              <div className="p-8 text-center text-muted-foreground">Cargando presupuestos...</div>
            ) : filtered.length === 0 ? (
              <div className="p-8 text-center text-muted-foreground">No se encontraron presupuestos.</div>
            ) : (
              <div className="divide-y">
                {filtered.map(p => (
                  <div key={p.id} className="grid grid-cols-6 p-4 text-sm items-center hover:bg-muted/50">
                    <div className="col-span-1 font-medium text-blue-600">{p.folio}</div>
                    <div className="col-span-1">{new Date(p.fecha).toLocaleDateString()}</div>
                    <div className="col-span-2">
                      <div className="font-semibold">{p.nomenclatura_id || 'Sin Nomenclatura'}</div>
                      <div className="text-xs text-muted-foreground line-clamp-1">{p.concepto}</div>
                    </div>
                    <div className="col-span-1 text-right font-bold">
                      ${(p.precio_venta || 0).toLocaleString()}
                    </div>
                    <div className="col-span-1 flex justify-center gap-2">
                      <Button variant="outline" size="sm" onClick={() => handleEdit(p)}>
                        <FileText className="h-4 w-4" />
                      </Button>
                      <Button variant="outline" size="sm" onClick={() => handlePrint(p)}>
                        <Printer className="h-4 w-4" />
                      </Button>
                      <Button variant="outline" size="sm" className="text-red-500 hover:text-red-600" onClick={() => {
                        if(confirm('¿Eliminar presupuesto?')) onDelete(p.id);
                      }}>
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>
            )}
          </div>
        </CardContent>
      </Card>
    </div>
  );
}
