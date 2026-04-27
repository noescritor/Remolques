import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Alert, AlertDescription } from '../ui/alert';
import { Cliente } from '../../types';

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
    tipo_pago_preferido: cliente?.tipo_pago_preferido || 'Transferencia' as any
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
          <Label>Nombre de Contacto</Label>
          <Input
            value={formData.nombre_contacto}
            onChange={(e) => setFormData(prev => ({ ...prev, nombre_contacto: e.target.value }))}
            placeholder="Persona de contacto"
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