import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Alert, AlertDescription } from '../ui/alert';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Plus, Trash2 } from 'lucide-react';
import { Cliente, ContactoCliente, CategoriaCliente } from '../../types';

interface ClienteModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cliente?: Cliente;
  categorias?: CategoriaCliente[];
  onGuardar: (cliente: Omit<Cliente, 'id'>) => void;
}

export function ClienteModal({ open, onOpenChange, cliente, categorias = [], onGuardar }: ClienteModalProps) {
  const [formData, setFormData] = useState({
    nombre_razon_social: '',
    nombre_contacto: '',
    telefono: '',
    correo: '',
    direccion: '',
    ciudad: '',
    estado: '',
    codigo_postal: '',
    pais: 'México',
    tipo_pago_preferido: 'Transferencia' as any,
    categoria_id: 'ninguna',
    origen_lead: '',
    giro_empresa: '',
    limite_credito: 0,
    contactos: [] as ContactoCliente[]
  });

  useEffect(() => {
    if (open) {
      setFormData({
        nombre_razon_social: cliente?.nombre_razon_social || '',
        nombre_contacto: cliente?.nombre_contacto || '',
        telefono: cliente?.telefono || '',
        correo: cliente?.correo || '',
        direccion: cliente?.direccion || '',
        ciudad: cliente?.ciudad || '',
        estado: cliente?.estado || '',
        codigo_postal: cliente?.codigo_postal || '',
        pais: cliente?.pais || 'México',
        tipo_pago_preferido: cliente?.tipo_pago_preferido || 'Transferencia',
        categoria_id: cliente?.categoria_id || 'ninguna',
        origen_lead: cliente?.origen_lead || '',
        giro_empresa: cliente?.giro_empresa || '',
        limite_credito: cliente?.limite_credito || 0,
        contactos: cliente?.contactos || []
      });
      setErrores([]);
    }
  }, [cliente, open]);

  const [errores, setErrores] = useState<string[]>([]);

  const validarFormulario = (): string[] => {
    const errores = [];
    if (!formData.nombre_razon_social.trim()) errores.push('El nombre/razón social es requerido');
    if (formData.correo && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(formData.correo)) {
      errores.push('El formato del correo electrónico no es válido');
    }
    return errores;
  };

  const manejarGuardar = () => {
    const erroresValidacion = validarFormulario();
    if (erroresValidacion.length > 0) {
      setErrores(erroresValidacion);
      return;
    }
    setErrores([]);
    const payload: any = { ...formData };
    if (payload.categoria_id === 'ninguna') {
      payload.categoria_id = null;
    }
    onGuardar(payload);
  };

  const agregarContacto = () => {
    setFormData(prev => ({
      ...prev,
      contactos: [...prev.contactos, { id: Date.now().toString(), nombre: '', departamento: '', puesto: '', telefono: '', correo: '' }]
    }));
  };

  const actualizarContacto = (id: string, cambios: Partial<ContactoCliente>) => {
    setFormData(prev => ({
      ...prev,
      contactos: prev.contactos.map(c => c.id === id ? { ...c, ...cambios } : c)
    }));
  };

  const eliminarContacto = (id: string) => {
    setFormData(prev => ({
      ...prev,
      contactos: prev.contactos.filter(c => c.id !== id)
    }));
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[700px] max-h-[90vh] overflow-y-auto">
        <DialogHeader>
          <DialogTitle>{cliente ? 'Editar Cliente' : 'Nuevo Cliente'}</DialogTitle>
        </DialogHeader>

        <div className="space-y-4 py-4">
          {errores.length > 0 && (
            <Alert variant="destructive">
              <AlertDescription>
                <ul className="list-disc list-inside">
                  {errores.map((error, index) => <li key={index}>{error}</li>)}
                </ul>
              </AlertDescription>
            </Alert>
          )}

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label>Nombre o Razón Social *</Label>
              <Input value={formData.nombre_razon_social} onChange={e => setFormData({...formData, nombre_razon_social: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Contacto Principal</Label>
              <Input value={formData.nombre_contacto} onChange={e => setFormData({...formData, nombre_contacto: e.target.value})} />
            </div>

            <div className="space-y-2">
              <Label>Correo Electrónico</Label>
              <Input type="email" value={formData.correo} onChange={e => setFormData({...formData, correo: e.target.value})} />
            </div>
            <div className="space-y-2">
              <Label>Teléfono</Label>
              <Input value={formData.telefono} onChange={e => setFormData({...formData, telefono: e.target.value})} />
            </div>

            <div className="space-y-2">
              <Label>Categoría</Label>
              <Select value={formData.categoria_id} onValueChange={v => setFormData({...formData, categoria_id: v})}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="ninguna">Sin categoría</SelectItem>
                  {categorias.map(c => <SelectItem key={c.id} value={c.id}>{c.nombre}</SelectItem>)}
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label>Método de Pago Preferido</Label>
              <Select value={formData.tipo_pago_preferido} onValueChange={v => setFormData({...formData, tipo_pago_preferido: v})}>
                <SelectTrigger><SelectValue /></SelectTrigger>
                <SelectContent>
                  <SelectItem value="Transferencia">Transferencia</SelectItem>
                  <SelectItem value="Tarjeta">Tarjeta</SelectItem>
                  <SelectItem value="Efectivo">Efectivo</SelectItem>
                  <SelectItem value="PayPal">PayPal</SelectItem>
                  <SelectItem value="Crédito 30 días">Crédito 30 días</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label>Giro de la Empresa</Label>
              <Input value={formData.giro_empresa} onChange={e => setFormData({...formData, giro_empresa: e.target.value})} placeholder="Ej. Restaurante, Diseño, Textil..." />
            </div>
            <div className="space-y-2">
              <Label>Origen del Lead</Label>
              <Input value={formData.origen_lead} onChange={e => setFormData({...formData, origen_lead: e.target.value})} placeholder="Ej. Recomendación, Facebook, Web..." />
            </div>
            <div className="space-y-2">
              <Label>Límite de Crédito</Label>
              <Input type="number" value={formData.limite_credito || ''} onChange={e => setFormData({...formData, limite_credito: Number(e.target.value)})} placeholder="0.00" />
            </div>
            {cliente && (
              <div className="space-y-2">
                <Label>Saldo Usado</Label>
                <div className="h-10 px-3 py-2 border rounded-md bg-white/[0.02] text-sm flex items-center text-muted-foreground border-white/10">
                  ${(cliente.saldo_usado || 0).toLocaleString()}
                </div>
              </div>
            )}
          </div>

          <div className="border-t pt-4 mt-4 border-white/10">
            <h3 className="text-sm font-medium mb-3 text-muted-foreground">Contactos Adicionales</h3>
            <div className="space-y-4">
              {formData.contactos.map((contacto) => (
                <div key={contacto.id} className="grid grid-cols-1 sm:grid-cols-2 gap-3 p-3 bg-white/[0.02] border border-white/5 rounded-lg relative">
                  <Button variant="ghost" size="icon" className="absolute top-2 right-2 h-6 w-6 text-red-500 hover:text-red-400" onClick={() => eliminarContacto(contacto.id)}>
                    <Trash2 className="h-4 w-4" />
                  </Button>
                  <div className="space-y-2">
                    <Label className="text-xs">Nombre</Label>
                    <Input className="h-8 text-sm" value={contacto.nombre} onChange={e => actualizarContacto(contacto.id, { nombre: e.target.value })} />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">Correo</Label>
                    <Input className="h-8 text-sm" type="email" value={contacto.correo || ''} onChange={e => actualizarContacto(contacto.id, { correo: e.target.value })} />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">Teléfono</Label>
                    <Input className="h-8 text-sm" value={contacto.telefono || ''} onChange={e => actualizarContacto(contacto.id, { telefono: e.target.value })} />
                  </div>
                  <div className="space-y-2">
                    <Label className="text-xs">Puesto / Depto</Label>
                    <Input className="h-8 text-sm" value={contacto.puesto || ''} onChange={e => actualizarContacto(contacto.id, { puesto: e.target.value })} />
                  </div>
                </div>
              ))}
              <Button type="button" variant="outline" size="sm" onClick={agregarContacto} className="w-full text-xs">
                <Plus className="mr-2 h-3 w-3" /> Añadir Contacto
              </Button>
            </div>
          </div>

        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>Cancelar</Button>
          <Button onClick={manejarGuardar}>Guardar Cliente</Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
