import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Alert, AlertDescription } from '../ui/alert';
import { Save, Settings } from 'lucide-react';
import { Ajustes } from '../../types';

interface AjustesFormProps {
  ajustes: Ajustes;
  onActualizarAjustes: (ajustes: Partial<Ajustes>) => void;
}

export function AjustesForm({ ajustes, onActualizarAjustes }: AjustesFormProps) {
  const [formData, setFormData] = useState(ajustes);
  const [guardado, setGuardado] = useState(false);
  const [errores, setErrores] = useState<string[]>([]);

  useEffect(() => {
    setFormData(ajustes);
  }, [ajustes]);

  const validarFormulario = (): string[] => {
    const errores = [];
    
    if (formData.iva_por_defecto < 0 || formData.iva_por_defecto > 0.5) {
      errores.push('La tasa de IVA debe estar entre 0 y 0.5');
    }
    
    if (formData.validez_por_defecto <= 0) {
      errores.push('La validez por defecto debe ser mayor a 0 días');
    }
    
    if (formData.offset_folio < 1) {
      errores.push('El offset de folio debe ser al menos 1');
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
    onActualizarAjustes(formData);
    setGuardado(true);
    
    // Ocultar mensaje después de 3 segundos
    setTimeout(() => setGuardado(false), 3000);
  };

  if (!formData) {
    return (
      <div className="flex justify-center items-center py-20 min-h-[50vh]">
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-accent-blue" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center gap-4">
        <Settings className="h-6 w-6" />
        <h1>Configuración del Sistema</h1>
      </div>

      {guardado && (
        <Alert>
          <AlertDescription>
            Los ajustes se han guardado correctamente.
          </AlertDescription>
        </Alert>
      )}

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

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Cotizaciones</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>IVA por Defecto</Label>
              <Input
                type="number"
                value={formData.iva_por_defecto}
                onChange={(e) => setFormData(prev => ({ ...prev, iva_por_defecto: parseFloat(e.target.value) || 0 }))}
                min="0"
                max="0.5"
                step="0.01"
                placeholder="0.16"
              />
              <p className="text-sm text-gray-500 mt-1">
                Tasa de IVA que se aplicará por defecto a nuevos productos y conceptos
              </p>
            </div>

            <div>
              <Label>Validez por Defecto (días)</Label>
              <Input
                type="number"
                value={formData.validez_por_defecto}
                onChange={(e) => setFormData(prev => ({ ...prev, validez_por_defecto: parseInt(e.target.value) || 0 }))}
                min="1"
                placeholder="30"
              />
              <p className="text-sm text-gray-500 mt-1">
                Días de validez que tendrán las cotizaciones por defecto
              </p>
            </div>
          </div>

          <div>
            <Label>Nota por Defecto</Label>
            <Textarea
              value={formData.nota_por_defecto}
              onChange={(e) => setFormData(prev => ({ ...prev, nota_por_defecto: e.target.value }))}
              placeholder="Texto que aparecerá por defecto en las nuevas cotizaciones..."
              rows={4}
            />
            <p className="text-sm text-gray-500 mt-1">
              Puedes usar {'{validez_dias}'} para incluir automáticamente los días de validez
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Folios</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Prefijo de Folio</Label>
              <Input
                value={formData.prefijo_folio}
                onChange={(e) => setFormData(prev => ({ ...prev, prefijo_folio: e.target.value }))}
                placeholder="COT-"
              />
              <p className="text-sm text-gray-500 mt-1">
                Texto que aparecerá antes del año y número consecutivo
              </p>
            </div>

            <div>
              <Label>Offset de Folio</Label>
              <Input
                type="number"
                value={formData.offset_folio}
                onChange={(e) => setFormData(prev => ({ ...prev, offset_folio: parseInt(e.target.value) || 1 }))}
                min="1"
                placeholder="1"
              />
              <p className="text-sm text-gray-500 mt-1">
                Número inicial para la numeración consecutiva
              </p>
            </div>
          </div>

          <div className="p-4 bg-blue-50 rounded-md">
            <h4 className="font-medium text-blue-900">Vista Previa del Folio</h4>
            <p className="text-blue-700 mt-1">
              Ejemplo: {formData.prefijo_folio}{new Date().getFullYear()}-{formData.offset_folio.toString().padStart(5, '0')}
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Información de la Empresa</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Nombre de la Empresa</Label>
              <Input
                value={formData.nombre_empresa || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, nombre_empresa: e.target.value }))}
                placeholder="IDEALLY"
              />
              <p className="text-sm text-gray-500 mt-1">
                Nombre que aparecerá en los documentos PDF
              </p>
            </div>

            <div>
              <Label>Tagline</Label>
              <Input
                value={formData.tagline || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, tagline: e.target.value }))}
                placeholder="Arte . Diseño . Ingeniería"
              />
              <p className="text-sm text-gray-500 mt-1">
                Lema o descripción breve de la empresa
              </p>
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Dirección</Label>
              <Input
                value={formData.direccion || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, direccion: e.target.value }))}
                placeholder="Retorno Pascual Mendoza 27, Puebla, Pue. 72260"
              />
            </div>

            <div>
              <Label>Teléfono</Label>
              <Input
                value={formData.telefono || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, telefono: e.target.value }))}
                placeholder="+52 22 1120 2976"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Email de Contacto</Label>
              <Input
                type="email"
                value={formData.email || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, email: e.target.value }))}
                placeholder="ventas@ideally.com.mx"
              />
              <p className="text-sm text-gray-500 mt-1">
                Email que aparecerá en tus cotizaciones y documentos
              </p>
            </div>

            <div>
              <Label>Sitio Web</Label>
              <Input
                value={formData.sitio_web || ''}
                onChange={(e) => setFormData(prev => ({ ...prev, sitio_web: e.target.value }))}
                placeholder="www.ideally.com.mx"
              />
            </div>
          </div>

          <div>
            <Label>Cuenta Bancaria</Label>
            <Input
              value={formData.cuenta_bancaria || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, cuenta_bancaria: e.target.value }))}
              placeholder="Cuenta: 123456789 - Banco XYZ"
            />
            <p className="text-sm text-gray-500 mt-1">
              Información de cuenta bancaria para transferencias
            </p>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Configuración de Emails</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Email de Envío</Label>
            <Input
              type="email"
              value={formData.email_envio || ''}
              onChange={(e) => setFormData(prev => ({ ...prev, email_envio: e.target.value }))}
              placeholder="ventas@ideally.com.mx"
            />
            <p className="text-sm text-gray-500 mt-1">
              Email desde el que se enviarán las cotizaciones por correo electrónico
            </p>
          </div>

          <div className="p-4 bg-amber-50 rounded-md border border-amber-200">
            <h4 className="font-medium text-amber-900">⚠️ Importante: Verificación de Dominio</h4>
            <div className="mt-2 text-sm text-amber-800 space-y-2">
              <p>
                Para enviar emails desde tu propio dominio (ej: ventas@ideally.com.mx), 
                primero debes <strong>verificar tu dominio en Resend</strong>.
              </p>
              <p>
                Si no verificas tu dominio, los emails se enviarán desde <code className="bg-amber-100 px-1 py-0.5 rounded">onboarding@resend.dev</code>
              </p>
              <p className="mt-3">
                <strong>Pasos para verificar tu dominio:</strong>
              </p>
              <ol className="list-decimal list-inside space-y-1 ml-2">
                <li>Ve a <a href="https://resend.com/domains" target="_blank" rel="noopener noreferrer" className="underline text-amber-900 hover:text-amber-950">resend.com/domains</a></li>
                <li>Agrega tu dominio (ej: ideally.com.mx)</li>
                <li>Configura los registros DNS (SPF, DKIM, DMARC)</li>
                <li>Espera a que se verifique (puede tardar hasta 48 horas)</li>
                <li>Ingresa tu email verificado en el campo de arriba</li>
              </ol>
              <p className="mt-3">
                📖 Lee el archivo <code className="bg-amber-100 px-1 py-0.5 rounded">CONFIGURACION_EMAIL.md</code> para instrucciones detalladas
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Textos del Resumen de Servicios</CardTitle>
        </CardHeader>
        <CardContent className="space-y-4">
          <div>
            <Label>Título de la Sección</Label>
            <Input
              value={formData.resumen_servicios?.titulo || 'RESUMEN DE SERVICIOS'}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                resumen_servicios: { 
                  ...prev.resumen_servicios, 
                  titulo: e.target.value 
                } 
              }))}
              placeholder="RESUMEN DE SERVICIOS"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div>
              <Label>Texto Pago Único</Label>
              <Input
                value={formData.resumen_servicios?.pago_unico || 'Servicio de pago único'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    pago_unico: e.target.value 
                  } 
                }))}
                placeholder="Servicio de pago único"
              />
            </div>

            <div>
              <Label>Texto Suscripción</Label>
              <Input
                value={formData.resumen_servicios?.suscripcion || 'Servicio de suscripción'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    suscripcion: e.target.value 
                  } 
                }))}
                placeholder="Servicio de suscripción"
              />
            </div>

            <div>
              <Label>Texto Híbrido</Label>
              <Input
                value={formData.resumen_servicios?.hibrido || 'Servicio híbrido'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    hibrido: e.target.value 
                  } 
                }))}
                placeholder="Servicio híbrido"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Texto Setup Completo</Label>
              <Input
                value={formData.resumen_servicios?.setup_completo || 'Incluye setup completo'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    setup_completo: e.target.value 
                  } 
                }))}
                placeholder="Incluye setup completo"
              />
            </div>

            <div>
              <Label>Texto Setup Inicial</Label>
              <Input
                value={formData.resumen_servicios?.setup_inicial || 'Incluye setup inicial'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    setup_inicial: e.target.value 
                  } 
                }))}
                placeholder="Incluye setup inicial"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Etiqueta Periodo</Label>
              <Input
                value={formData.resumen_servicios?.periodo_label || 'Periodo:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    periodo_label: e.target.value 
                  } 
                }))}
                placeholder="Periodo:"
              />
            </div>

            <div>
              <Label>Etiqueta Meses Contratados</Label>
              <Input
                value={formData.resumen_servicios?.meses_contratados_label || 'Meses contratados:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    meses_contratados_label: e.target.value 
                  } 
                }))}
                placeholder="Meses contratados:"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div>
              <Label>Etiqueta Permanencia Mínima</Label>
              <Input
                value={formData.resumen_servicios?.permanencia_minima_label || 'Permanencia mínima:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    permanencia_minima_label: e.target.value 
                  } 
                }))}
                placeholder="Permanencia mínima:"
              />
            </div>

            <div>
              <Label>Etiqueta Base Asientos</Label>
              <Input
                value={formData.resumen_servicios?.base_asientos_label || 'Base:'}
                onChange={(e) => setFormData(prev => ({ 
                  ...prev, 
                  resumen_servicios: { 
                    ...prev.resumen_servicios, 
                    base_asientos_label: e.target.value 
                  } 
                }))}
                placeholder="Base:"
              />
            </div>
          </div>

          <div>
            <Label>Etiqueta Asientos Adicionales</Label>
            <Input
              value={formData.resumen_servicios?.asientos_adicionales_label || 'Asientos adicionales:'}
              onChange={(e) => setFormData(prev => ({ 
                ...prev, 
                resumen_servicios: { 
                  ...prev.resumen_servicios, 
                  asientos_adicionales_label: e.target.value 
                } 
              }))}
              placeholder="Asientos adicionales:"
            />
          </div>

          <div className="p-4 bg-blue-50 rounded-md">
            <h4 className="font-medium text-blue-900">Vista Previa</h4>
            <p className="text-blue-700 mt-1">
              {formData.resumen_servicios?.titulo || 'RESUMEN DE SERVICIOS'}
            </p>
            <div className="mt-2 text-sm text-blue-600">
              <p>• {formData.resumen_servicios?.pago_unico || 'Servicio de pago único'}</p>
              <p>• {formData.resumen_servicios?.setup_completo || 'Incluye setup completo'}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="flex justify-end">
        <Button onClick={manejarGuardar}>
          <Save className="mr-2 h-4 w-4" />
          Guardar Ajustes
        </Button>
      </div>
    </div>
  );
}