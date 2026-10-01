import { useState } from 'react';
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from '../ui/card';
import { Button } from '../ui/button';
import { Plus, Search, FileText, Trash2, Printer, ArrowRight, Settings } from 'lucide-react';
import { Input } from '../ui/input';
import { Presupuesto, Cliente, Producto } from '../../types';
import { PresupuestoEditor } from './PresupuestoEditor';
import { PresupuestoPDF } from './PresupuestoPDF';
import { pdf } from '@react-pdf/renderer';
import { useNavigate } from 'react-router-dom';
import { formatearMoneda } from '../../utils/calculations';

interface Props {
  productos?: Producto[];
  presupuestos: Presupuesto[];
  clientes: Cliente[];
  loading: boolean;
  onSave: (presu: Partial<Presupuesto>) => Promise<any>;
  onUpdate: (id: string, presu: Partial<Presupuesto>) => Promise<any>;
  onDelete: (id: string) => Promise<void>;
}

export function PresupuestosList({ productos = [], presupuestos, clientes, loading, onSave, onUpdate, onDelete }: Props) {
  const [searchTerm, setSearchTerm] = useState('');
  const [isEditorOpen, setIsEditorOpen] = useState(false);
  const [selectedPresupuesto, setSelectedPresupuesto] = useState<Presupuesto | null>(null);
  const navigate = useNavigate();

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
  
  const modelosBOM = productos.filter(p => p.tipo_item === 'producto_terminado' && p.nombre.toLowerCase().includes(searchTerm.toLowerCase()));

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
    <div className="space-y-8">
      <div className="flex flex-col sm:flex-row justify-between items-start sm:items-center gap-4">
        <div>
          <h2 className="text-2xl font-bold tracking-tight">Catálogo de Modelos y Presupuestos</h2>
          <p className="text-muted-foreground">Configura los modelos (BOM) y conviértelos directamente a Cotizaciones.</p>
        </div>
        <div className="relative w-full sm:w-64">
          <Search className="absolute left-2 top-2.5 h-4 w-4 text-muted-foreground" />
          <Input
            placeholder="Buscar modelo o presupuesto..."
            value={searchTerm}
            onChange={(e) => setSearchTerm(e.target.value)}
            className="pl-8"
          />
        </div>
      </div>

      <div className="space-y-4">
        <h3 className="text-xl font-bold flex items-center gap-2 border-b pb-2">
          <Settings className="w-5 h-5 text-gray-500" />
          Modelos Base (Catálogo CPQ)
        </h3>
        <p className="text-sm text-gray-500">Selecciona un modelo para iniciar su configurador (presupuesto) y emitir una cotización.</p>
        
        {modelosBOM.length === 0 ? (
          <div className="p-8 text-center text-gray-500 border rounded-lg bg-gray-50">
            No se encontraron modelos configurables.
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {modelosBOM.map(modelo => (
              <Card key={modelo.id} className="hover:border-accent-blue/50 transition-colors cursor-default shadow-sm">
                <CardHeader className="pb-3">
                  <div className="flex justify-between items-start">
                    <CardTitle className="text-base font-bold text-gray-800">{modelo.nombre}</CardTitle>
                    <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded font-semibold tracking-wider uppercase">
                      Modelo
                    </span>
                  </div>
                  {modelo.descripcion && (
                    <CardDescription className="text-xs line-clamp-2 mt-1">{modelo.descripcion}</CardDescription>
                  )}
                </CardHeader>
                <CardContent className="pt-0 flex justify-between items-end">
                  <div className="text-sm">
                    <p className="text-gray-500 text-xs uppercase tracking-wider font-semibold">Precio Base</p>
                    <p className="font-bold text-lg text-gray-800">{formatearMoneda(modelo.precio_unitario || 0)}</p>
                  </div>
                  <Button 
                    size="sm" 
                    className="bg-accent-blue text-white hover:bg-blue-700"
                    onClick={() => navigate(`/cotizaciones/nueva?producto_id=${modelo.id}`)}
                  >
                    Cotizar <ArrowRight className="w-4 h-4 ml-1" />
                  </Button>
                </CardContent>
              </Card>
            ))}
          </div>
        )}
      </div>

      <div className="space-y-4 pt-8">
        <div className="flex justify-between items-center border-b pb-2">
          <h3 className="text-xl font-bold flex items-center gap-2">
            <FileText className="w-5 h-5 text-gray-500" />
            Presupuestos Históricos (Legacy)
          </h3>
          <Button onClick={handleCreate} variant="outline" size="sm">
            <Plus className="mr-2 h-4 w-4" /> Presupuesto Manual
          </Button>
        </div>

        {loading ? (
          <div className="text-center py-10 text-muted-foreground">Cargando presupuestos...</div>
        ) : filtered.length === 0 ? (
          <Card>
            <CardContent className="flex flex-col items-center justify-center py-10">
              <FileText className="h-12 w-12 text-muted-foreground/30 mb-4" />
              <p className="text-lg font-medium text-foreground">No hay presupuestos</p>
            </CardContent>
          </Card>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {filtered.map(presu => {
              const cliente = clientes.find(c => c.id === presu.cliente_id);
              return (
                <Card key={presu.id} className="hover:border-primary/50 transition-colors">
                  <CardHeader className="pb-3">
                    <div className="flex justify-between items-start">
                      <div>
                        <CardTitle className="text-lg text-primary">{presu.folio}</CardTitle>
                        <CardDescription className="font-medium text-foreground">
                          {cliente?.nombre_razon_social || 'Sin cliente asignado'}
                        </CardDescription>
                      </div>
                      <div className="flex gap-1">
                        <Button variant="ghost" size="sm" className="h-8 w-8 p-0" onClick={() => handlePrint(presu)}>
                          <Printer className="h-4 w-4 text-muted-foreground" />
                        </Button>
                        <Button variant="ghost" size="sm" className="h-8 w-8 p-0" onClick={() => handleEdit(presu)}>
                          <FileText className="h-4 w-4 text-muted-foreground" />
                        </Button>
                        <Button variant="ghost" size="sm" className="h-8 w-8 p-0 text-red-500 hover:text-red-600" onClick={() => { if(window.confirm('¿Eliminar?')) onDelete(presu.id); }}>
                          <Trash2 className="h-4 w-4" />
                        </Button>
                      </div>
                    </div>
                  </CardHeader>
                  <CardContent>
                    <div className="text-sm text-muted-foreground">
                      {presu.concepto && <p className="mb-2 line-clamp-2">{presu.concepto}</p>}
                      <p>Venta est.: {formatearMoneda(presu.precio_venta || 0)}</p>
                      <p>Fecha: {new Date(presu.fecha || '').toLocaleDateString()}</p>
                    </div>
                  </CardContent>
                </Card>
              );
            })}
          </div>
        )}
      </div>
    </div>
  );
}
