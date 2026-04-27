import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle, DialogTrigger } from '../ui/dialog';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle } from '../ui/alert-dialog';
import { Skeleton } from '../ui/skeleton';
import { Plus, Search, Edit, Trash2, Users } from 'lucide-react';
import { Cliente } from '../../types';
import { ClienteModal } from './ClienteModal';

interface ClientesListProps {
  clientes: Cliente[];
  loading: boolean;
  onCrearCliente: (cliente: Omit<Cliente, 'id'>) => void;
  onActualizarCliente: (id: string, cliente: Partial<Cliente>) => void;
  onEliminarCliente: (id: string) => void;
}

export function ClientesList({
  clientes,
  loading,
  onCrearCliente,
  onActualizarCliente,
  onEliminarCliente
}: ClientesListProps) {
  const [busqueda, setBusqueda] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [clienteEditando, setClienteEditando] = useState<Cliente | null>(null);
  const [clienteAEliminar, setClienteAEliminar] = useState<string | null>(null);

  const clientesFiltrados = clientes.filter(cliente => {
    if (!cliente) return false;
    const busquedaLower = busqueda.toLowerCase();
    return (
      (cliente.nombre_razon_social || '').toLowerCase().includes(busquedaLower) ||
      (cliente.correo || '').toLowerCase().includes(busquedaLower) ||
      (cliente.telefono || '').includes(busqueda)
    );
  });

  const manejarGuardarCliente = (clienteData: Omit<Cliente, 'id'>) => {
    if (clienteEditando) {
      onActualizarCliente(clienteEditando.id, clienteData);
    } else {
      onCrearCliente(clienteData);
    }
    setModalOpen(false);
    setClienteEditando(null);
  };

  const abrirModalEdicion = (cliente: Cliente) => {
    setClienteEditando(cliente);
    setModalOpen(true);
  };

  const abrirModalCreacion = () => {
    setClienteEditando(null);
    setModalOpen(true);
  };

  if (loading) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>Clientes</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="space-y-4">
            {[...Array(5)].map((_, i) => (
              <Skeleton key={i} className="h-12 w-full" />
            ))}
          </div>
        </CardContent>
      </Card>
    );
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
            <CardTitle>Clientes</CardTitle>
            <Button onClick={abrirModalCreacion} className="w-full sm:w-auto">
              <Plus className="mr-2 h-4 w-4" />
              Nuevo Cliente
            </Button>
          </div>
          
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 h-4 w-4 text-gray-400" />
            <Input
              placeholder="Buscar clientes..."
              value={busqueda}
              onChange={(e) => setBusqueda(e.target.value)}
              className="pl-10"
            />
          </div>
        </CardHeader>
        
        <CardContent>
          {clientesFiltrados.length === 0 ? (
            <div className="text-center py-12">
              <Users className="mx-auto h-12 w-12 text-gray-400" />
              <h3 className="mt-4 text-lg font-medium text-gray-900">
                {busqueda ? 'No se encontraron clientes' : 'No hay clientes registrados'}
              </h3>
              <p className="mt-2 text-sm sm:text-base text-gray-500">
                {busqueda 
                  ? 'Intenta ajustar los términos de búsqueda'
                  : 'Comienza agregando tu primer cliente'
                }
              </p>
              {!busqueda && (
                <Button onClick={abrirModalCreacion} className="mt-4">
                  <Plus className="mr-2 h-4 w-4" />
                  Nuevo Cliente
                </Button>
              )}
            </div>
          ) : (
            <>
              {/* Vista de cards para móvil */}
              <div className="lg:hidden space-y-3">
                {clientesFiltrados.map((cliente) => (
                  <div key={cliente.id} className="border border-gray-200 rounded-lg p-4">
                    <div className="flex items-start justify-between mb-3">
                      <div className="flex-1">
                        <div className="font-semibold text-gray-900">{cliente.nombre_razon_social}</div>
                        {cliente.nombre_contacto && (
                          <div className="text-sm text-gray-600 mt-1">{cliente.nombre_contacto}</div>
                        )}
                      </div>
                    </div>
                    
                    <div className="space-y-2 text-sm">
                      {cliente.telefono && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Teléfono:</span>
                          <span className="text-gray-900">{cliente.telefono}</span>
                        </div>
                      )}
                      {cliente.correo && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Correo:</span>
                          <span className="text-gray-900 truncate ml-2">{cliente.correo}</span>
                        </div>
                      )}
                      {(cliente.ciudad || cliente.estado) && (
                        <div className="flex justify-between">
                          <span className="text-gray-600">Ubicación:</span>
                          <span className="text-gray-900">{[cliente.ciudad, cliente.estado].filter(Boolean).join(', ')}</span>
                        </div>
                      )}
                      <div className="flex justify-between">
                        <span className="text-gray-600">Tipo de pago:</span>
                        <span className="text-gray-900">{cliente.tipo_pago_preferido}</span>
                      </div>
                    </div>
                    
                    <div className="flex gap-2 mt-4">
                      <Button
                        variant="outline"
                        size="sm"
                        className="flex-1"
                        onClick={() => abrirModalEdicion(cliente)}
                      >
                        <Edit className="mr-2 h-4 w-4" />
                        Editar
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => setClienteAEliminar(cliente.id)}
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </div>
                ))}
              </div>

              {/* Tabla para desktop */}
              <div className="hidden lg:block overflow-x-auto">
                <Table>
                  <TableHeader>
                    <TableRow>
                      <TableHead>Nombre/Razón Social</TableHead>
                      <TableHead>Contacto</TableHead>
                      <TableHead>Teléfono</TableHead>
                      <TableHead>Correo</TableHead>
                      <TableHead>Ciudad</TableHead>
                      <TableHead>Estado</TableHead>
                      <TableHead>Tipo de Pago</TableHead>
                      <TableHead className="text-right">Acciones</TableHead>
                    </TableRow>
                  </TableHeader>
                  <TableBody>
                    {clientesFiltrados.map((cliente) => (
                      <TableRow key={cliente.id}>
                        <TableCell className="font-medium">{cliente.nombre_razon_social}</TableCell>
                        <TableCell>{cliente.nombre_contacto || '-'}</TableCell>
                        <TableCell>{cliente.telefono || '-'}</TableCell>
                        <TableCell>{cliente.correo || '-'}</TableCell>
                        <TableCell>{cliente.ciudad || '-'}</TableCell>
                        <TableCell>{cliente.estado || '-'}</TableCell>
                        <TableCell>{cliente.tipo_pago_preferido}</TableCell>
                        <TableCell className="text-right">
                          <div className="flex gap-1 justify-end">
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => abrirModalEdicion(cliente)}
                            >
                              <Edit className="h-4 w-4" />
                            </Button>
                            <Button
                              variant="ghost"
                              size="sm"
                              onClick={() => setClienteAEliminar(cliente.id)}
                            >
                              <Trash2 className="h-4 w-4" />
                            </Button>
                          </div>
                        </TableCell>
                      </TableRow>
                    ))}
                  </TableBody>
                </Table>
              </div>
            </>
          )}
        </CardContent>
      </Card>

      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="max-w-2xl max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle>
              {clienteEditando ? 'Editar Cliente' : 'Nuevo Cliente'}
            </DialogTitle>
            <DialogDescription>
              {clienteEditando 
                ? 'Modifica la información del cliente existente.' 
                : 'Completa los datos para crear un nuevo cliente.'
              }
            </DialogDescription>
          </DialogHeader>
          <ClienteModal
            cliente={clienteEditando || undefined}
            onGuardar={manejarGuardarCliente}
            onCancelar={() => setModalOpen(false)}
          />
        </DialogContent>
      </Dialog>

      <AlertDialog open={!!clienteAEliminar} onOpenChange={() => setClienteAEliminar(null)}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar cliente?</AlertDialogTitle>
            <AlertDialogDescription>
              Esta acción no se puede deshacer. Se eliminará permanentemente el cliente de la base de datos.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (clienteAEliminar) {
                  onEliminarCliente(clienteAEliminar);
                  setClienteAEliminar(null);
                }
              }}
            >
              Eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </>
  );
}