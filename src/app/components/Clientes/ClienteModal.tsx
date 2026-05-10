import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Alert, AlertDescription } from '../ui/alert';
import { Plus, Trash2, UserPlus } from 'lucide-react';
import { Cliente, ContactoCliente } from '../../types';

interface ClienteModalProps {
  cliente?: Cliente;
  onGuardar: (cliente: Omit<Cliente, 'id'>) => void;
  onCancelar: () => void;
}

export function ClienteModal({ cliente, onGuardar, onCancelar }: ClienteModalProps) {
  const [formData, setFormData] = useState({
    nombre_razon_social: cliente?.nombre_razon_social || '',
    nombre_contacto: cliente?.nombre_contacto || '',
    telefono: cliente?.telefono || '',
    correo: cliente?.correo || '',
    direccion: cliente?.direccion || '',
    ciudad: cliente?.ciudad || '',
    estado: cliente?.estado || '',
    codigo_postal: cliente?.codigo_postal || '',
    pais: cliente?.pais || 'México',
    tipo_pago_preferido: cliente?.tipo_pago_preferido || 'Transferencia' as any,
    contactos: cliente?.contactos || [] as ContactoCliente[]
  });

  const [errores, setErrores] = useState<string[]>([]);

  const validarFormulario = (): string[] => {
    const errores = [];
    
    if (!formData.nombre_razon_social.trim()) {
      errores.push('El nombre/razón social es requerido');
    }
    
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
    onGuardar(formData);
  };

  const agregarContacto = () => {
    const nuevoContacto: ContactoCliente = {
      id: Date.now().toString(),
      nombre: '',
      departamento: '',
      puesto: '',
      telefono: '',
      correo: ''
    };
    setFormData(prev => ({
      ...prev,
      contactos: [...prev.contactos, nuevoContacto]
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
    <div className="space-y-4">
      {errores.length > 0 && (
        <Alert>
          <AlertDescription>
            <ul className="list-disc list-inside">
              {errores.map((error, index) => (
                <li key={index}>{error}</li>
              ))}
            </ul>
          </AlertDescription>
        </Alert>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="md:col-span-2">
          <Label>Nombre/Razón Social *</Label>
          <Input
            value={formData.nombre_razon_social}
            onChange={(e) => setFormData(prev => ({ ...prev, nombre_razon_social: e.target.value }))}
            placeholder="Nombre completo o razón social"
          />
        </div>

        <div>
          <Label>Contacto Principal</Label>
          <Input
            value={formData.nombre_contacto}
            onChange={(e) => setFormData(prev => ({ ...prev, nombre_contacto: e.target.value }))}
            placeholder="Persona de contacto principal"
          />
        </div>

        <div>
          <Label>Teléfono</Label>
          <Input
            value={formData.telefono}
            onChange={(e) => setFormData(prev => ({ ...prev, telefono: e.target.value }))}
            placeholder="555-123-4567"
          />
        </div>

        <div className="md:col-span-2">
          <Label>Correo Electrónico</Label>
          <Input
            type="email"
            value={formData.correo}
            onChange={(e) => setFormData(prev => ({ ...prev, correo: e.target.value }))}
            placeholder="correo@ejemplo.com"
          />
        </div>

        <div className="md:col-span-2">
          <Label>Dirección</Label>
          <Input
            value={formData.direccion}
            onChange={(e) => setFormData(prev => ({ ...prev, direccion: e.target.value }))}
            placeholder="Calle, número, colonia"
          />
        </div>

        <div>
          <Label>Ciudad</Label>
          <Input
            value={formData.ciudad}
            onChange={(e) => setFormData(prev => ({ ...prev, ciudad: e.target.value }))}
            placeholder="Ciudad"
          />
        </div>

        <div>
          <Label>Estado</Label>
          <Input
            value={formData.estado}
            onChange={(e) => setFormData(prev => ({ ...prev, estado: e.target.value }))}
            placeholder="Estado"
          />
        </div>

        <div>
          <Label>Código Postal</Label>
          <Input
            value={formData.codigo_postal}
            onChange={(e) => setFormData(prev => ({ ...prev, codigo_postal: e.target.value }))}
            placeholder="00000"
          />
        </div>

        <div>
          <Label>País</Label>
          <Input
            value={formData.pais}
            onChange={(e) => setFormData(prev => ({ ...prev, pais: e.target.value }))}
          />
        </div>

        <div className="md:col-span-2">
          <Label>Tipo de Pago Preferido</Label>
          <Select 
            value={formData.tipo_pago_preferido} 
            onValueChange={(value) => setFormData(prev => ({ ...prev, tipo_pago_preferido: value as any }))}
          >
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="Transferencia">Transferencia</SelectItem>
              <SelectItem value="Tarjeta">Tarjeta</SelectItem>
              <SelectItem value="Efectivo">Efectivo</SelectItem>
              <SelectItem value="PayPal">PayPal</SelectItem>
              <SelectItem value="Crédito 30 días">Crédito 30 días</SelectItem>
            </SelectContent>
          </Select>
        </div>
      </div>

      {/* ─── Contactos Adicionales ─── */}
      <div className="border-t pt-4">
        <div className="flex items-center justify-between mb-3">
          <div>
            <Label className="text-base font-semibold">Contactos del Cliente</Label>
            <p className="text-xs text-gray-500 mt-0.5">Personas de diferentes departamentos que pueden solicitar cotizaciones</p>
          </div>
          <Button type="button" variant="outline" size="sm" onClick={agregarContacto}>
            <UserPlus className="h-4 w-4 mr-1" />
            Agregar
          </Button>
        </div>

        {formData.contactos.length === 0 ? (
          <div className="text-center py-4 text-sm text-gray-400 border border-dashed rounded-lg">
            Sin contactos adicionales. Haz clic en "Agregar" para añadir personas de contacto.
          </div>
        ) : (
          <div className="space-y-3">
            {formData.contactos.map((contacto, idx) => (
              <div key={contacto.id} className="border rounded-lg p-3 bg-gray-50 space-y-2">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-gray-500">Contacto {idx + 1}</span>
                  <Button type="button" variant="ghost" size="sm" className="h-7 w-7 p-0 text-red-500" onClick={() => eliminarContacto(contacto.id)}>
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  <div>
                    <Label className="text-xs">Nombre *</Label>
                    <Input
                      value={contacto.nombre}
                      onChange={(e) => actualizarContacto(contacto.id, { nombre: e.target.value })}
                      placeholder="Nombre completo"
                      className="text-sm"
                    />
                  </div>
                  <div>
                    <Label className="text-xs">Departamento</Label>
                    <Input
                      value={contacto.departamento || ''}
                      onChange={(e) => actualizarContacto(contacto.id, { departamento: e.target.value })}
                      placeholder="Ej: RH, Ventas, Ingeniería"
                      className="text-sm"
                    />
                  </div>
                  <div>
                    <Label className="text-xs">Puesto</Label>
                    <Input
                      value={contacto.puesto || ''}
                      onChange={(e) => actualizarContacto(contacto.id, { puesto: e.target.value })}
                      placeholder="Ej: Gerente, Director"
                      className="text-sm"
                    />
                  </div>
                  <div>
                    <Label className="text-xs">Teléfono</Label>
                    <Input
                      value={contacto.telefono || ''}
                      onChange={(e) => actualizarContacto(contacto.id, { telefono: e.target.value })}
                      placeholder="555-000-0000"
                      className="text-sm"
                    />
                  </div>
                  <div className="sm:col-span-2">
                    <Label className="text-xs">Correo</Label>
                    <Input
                      type="email"
                      value={contacto.correo || ''}
                      onChange={(e) => actualizarContacto(contacto.id, { correo: e.target.value })}
                      placeholder="correo@empresa.com"
                      className="text-sm"
                    />
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="flex gap-2 justify-end pt-4">
        <Button variant="outline" onClick={onCancelar}>
          Cancelar
        </Button>
        <Button onClick={manejarGuardar}>
          {cliente ? 'Actualizar' : 'Crear'} Cliente
        </Button>
      </div>
    </div>
  );
}