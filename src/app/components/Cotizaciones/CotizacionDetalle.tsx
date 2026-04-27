import { useState } from 'react';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '../ui/table';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Tabs, TabsContent, TabsList, TabsTrigger } from '../ui/tabs';
import { Badge } from '../ui/badge';
import { Alert, AlertDescription } from '../ui/alert';
import { ArrowLeft, FileDown, Edit, Save, Eye, Mail, GitBranch, ExternalLink, Link2, Copy, Loader2 } from 'lucide-react';
import { Cotizacion, Pago, EstadoCotizacion, TRANSICIONES_ESTADO, Cliente } from '../../types';
import { formatearMoneda, formatearFecha } from '../../utils/calculations';
import { EnviarEmailDialog } from './EnviarEmailDialog';
import { toast } from 'sonner';


interface CotizacionDetalleProps {
  cotizacion: Cotizacion;
  todasLasCotizaciones?: Cotizacion[];
  pagos: Pago[];
  saldoPendiente: number;
  productos: any[];
  ajustes: any;
  cliente?: Cliente;
  onVolver: () => void;
  onEditar: (id: string) => void;
  onVerCotizacion?: (id: string) => void;
  onExportPDF: (cotizacion: Cotizacion) => void;
  onVerPDF?: (cotizacion: Cotizacion) => void;
  onCambiarEstado: (id: string, estado: EstadoCotizacion) => void;
  onCrearPago: (pago: Omit<Pago, 'id'>) => void;
  onGenerarTokenPortal?: (id: string) => Promise<{ token: string; expira: string; portalUrl: string }>;
}

const estadoColors: Record<EstadoCotizacion, string> = {
  'Borrador': 'bg-gray-100 text-gray-800',
  'Enviada': 'bg-blue-100 text-blue-800',
  'Aprobada': 'bg-green-100 text-green-800',
  'Cancelada': 'bg-red-100 text-red-800',
  'Pagada': 'bg-emerald-100 text-emerald-800'
};

export function CotizacionDetalle({
  cotizacion,
  todasLasCotizaciones = [],
  pagos,
  saldoPendiente,
  productos,
  ajustes,
  cliente,
  onVolver,
  onEditar,
  onVerCotizacion,
  onExportPDF,
  onVerPDF,
  onCambiarEstado,
  onCrearPago,
  onGenerarTokenPortal
}: CotizacionDetalleProps) {

  // ── Calcular familia de versiones ──────────────────────────────────────────
  const famVersiones = (() => {
    if (!todasLasCotizaciones.length) return [];
    // La raíz es la que no tiene padre, o el padre de esta
    const rootId = cotizacion.cotizacion_padre_id || cotizacion.id;
    const root = todasLasCotizaciones.find(c => c.id === rootId);
    const hijos = todasLasCotizaciones.filter(c => c.cotizacion_padre_id === rootId);
    const familia = root ? [root, ...hijos] : hijos;
    return familia.sort((a, b) => (a.version || 1) - (b.version || 1));
  })();
  const [formPago, setFormPago] = useState({
    tipo_pago: '' as any,
    referencia: '',
    monto: 0,
    fecha: new Date().toISOString().split('T')[0]
  });
  const [erroresPago, setErroresPago] = useState<string[]>([]);
  const [emailDialogOpen, setEmailDialogOpen] = useState(false);
  const [generandoPortal, setGenerandoPortal] = useState(false);

  const transicionesPermitidas = TRANSICIONES_ESTADO[cotizacion.estado];

  const validarPago = (): string[] => {
    const errores = [];
    
    if (!formPago.tipo_pago) {
      errores.push('Debe seleccionar un tipo de pago');
    }
    
    if (formPago.monto <= 0) {
      errores.push('El monto debe ser mayor a 0');
    }
    
    if (formPago.monto > saldoPendiente) {
      errores.push('El monto no puede ser mayor al saldo pendiente');
    }
    
    return errores;
  };

  const manejarCrearPago = () => {
    const erroresValidacion = validarPago();
    if (erroresValidacion.length > 0) {
      setErroresPago(erroresValidacion);
      return;
    }
    
    setErroresPago([]);
    
    onCrearPago({
      cotizacion_id: cotizacion.id,
      ...formPago
    });
    
    // Limpiar formulario
    setFormPago({
      tipo_pago: '' as any,
      referencia: '',
      monto: 0,
      fecha: new Date().toISOString().split('T')[0]
    });
  };

  const puedeMarcarComoPagada = Math.abs(saldoPendiente) < 0.01 && cotizacion.estado !== 'Pagada';

  const copiarLinkPortal = async (url: string) => {
    try {
      await navigator.clipboard.writeText(url);
      toast.success('Link del portal copiado');
    } catch {
      toast.error('No se pudo copiar el link');
    }
  };

  const manejarPortal = async () => {
    const tokenExistente = cotizacion.token_publico;
    const linkExistente = tokenExistente ? `${window.location.origin}/cotizacion/${tokenExistente}` : null;

    if (linkExistente && !cotizacion.token_expira_en) {
      await copiarLinkPortal(linkExistente);
      return;
    }

    if (linkExistente && cotizacion.token_expira_en && new Date(cotizacion.token_expira_en) > new Date()) {
      await copiarLinkPortal(linkExistente);
      return;
    }

    if (!onGenerarTokenPortal) {
      toast.error('No se pudo generar el portal');
      return;
    }

    setGenerandoPortal(true);
    try {
      const result = await onGenerarTokenPortal(cotizacion.id);
      await copiarLinkPortal(result.portalUrl);
    } finally {
      setGenerandoPortal(false);
    }
  };

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-4">
          <Button variant="outline" onClick={onVolver}>
            <ArrowLeft className="mr-2 h-4 w-4" />
            Volver
          </Button>
          <h1>Cotización {cotizacion.folio}</h1>
        </div>
        
        <div className="flex gap-2">
          <Button variant="outline" onClick={() => onEditar(cotizacion.id)}>
            <Edit className="mr-2 h-4 w-4" />
            Editar
          </Button>
          
          <Button 
            variant="outline" 
            onClick={() => setEmailDialogOpen(true)}
            className="text-purple-600 border-purple-300 hover:bg-purple-50"
          >
            <Mail className="mr-2 h-4 w-4" />
            Enviar Email
          </Button>

          <Button
            variant="outline"
            onClick={manejarPortal}
            disabled={generandoPortal}
            className="text-blue-600 border-blue-300 hover:bg-blue-50"
          >
            {generandoPortal ? (
              <Loader2 className="mr-2 h-4 w-4 animate-spin" />
            ) : cotizacion.token_publico ? (
              <Copy className="mr-2 h-4 w-4" />
            ) : (
              <Link2 className="mr-2 h-4 w-4" />
            )}
            {cotizacion.token_publico ? 'Copiar Portal' : 'Generar Portal'}
          </Button>
          
          {onVerPDF && (
            <Button variant="outline" onClick={() => onVerPDF(cotizacion)}>
              <Eye className="mr-2 h-4 w-4" />
              Vista Previa PDF
            </Button>
          )}
          
          <Button variant="outline" onClick={() => onExportPDF(cotizacion)}>
            <FileDown className="mr-2 h-4 w-4" />
            Exportar PDF
          </Button>
        </div>
      </div>

      {/* Resumen */}
      <Card>
        <CardHeader>
          <CardTitle>Resumen de Cotización</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
            <div>
              <Label className="text-sm text-gray-500">Folio</Label>
              <div className="font-medium">{cotizacion.folio}</div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">Cliente</Label>
              <div className="font-medium">{cotizacion.cliente?.nombre_razon_social}</div>
              <div className="text-sm text-gray-500">{cotizacion.cliente?.correo}</div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">Fecha</Label>
              <div className="font-medium">{formatearFecha(cotizacion.fecha)}</div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">Validez</Label>
              <div className="font-medium">{cotizacion.validez_dias} días</div>
            </div>

            {cotizacion.descripcion && (
              <div className="lg:col-span-3">
                <Label className="text-sm text-gray-500">Descripción</Label>
                <div className="font-medium">{cotizacion.descripcion}</div>
              </div>
            )}
            
            <div>
              <Label className="text-sm text-gray-500">Estado</Label>
              <div className="flex gap-2 items-center">
                <Badge className={estadoColors[cotizacion.estado]}>
                  {cotizacion.estado}
                </Badge>
                
                {transicionesPermitidas.length > 0 && (
                  <Select onValueChange={(estado: EstadoCotizacion) => onCambiarEstado(cotizacion.id, estado)}>
                    <SelectTrigger className="w-40">
                      <SelectValue placeholder="Cambiar..." />
                    </SelectTrigger>
                    <SelectContent>
                      {transicionesPermitidas.map(estado => (
                        <SelectItem key={estado} value={estado}>{estado}</SelectItem>
                      ))}
                      {puedeMarcarComoPagada && !transicionesPermitidas.includes('Pagada') && (
                        <SelectItem value="Pagada">Pagada</SelectItem>
                      )}
                    </SelectContent>
                  </Select>
                )}
              </div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">Subtotal</Label>
              <div className="font-medium">{formatearMoneda(cotizacion.subtotal)}</div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">IVA</Label>
              <div className="font-medium">{formatearMoneda(cotizacion.iva)}</div>
            </div>
            
            <div>
              <Label className="text-sm text-gray-500">Total</Label>
              <div className="font-bold text-lg text-green-600">{formatearMoneda(cotizacion.total)}</div>
            </div>
          </div>
          
          {cotizacion.nota && (
            <div className="mt-6 p-4 bg-gray-50 rounded-md">
              <Label className="text-sm text-gray-500">Nota</Label>
              <div className="mt-1">{cotizacion.nota}</div>
            </div>
          )}
        </CardContent>
      </Card>

      <Tabs defaultValue="conceptos" className="w-full">
        <TabsList>
          <TabsTrigger value="conceptos">Conceptos</TabsTrigger>
          <TabsTrigger value="pagos">Pagos</TabsTrigger>
          {famVersiones.length > 1 && (
            <TabsTrigger value="versiones" className="flex items-center gap-1.5">
              <GitBranch className="h-3.5 w-3.5" />
              Versiones
              <span className="ml-1 bg-blue-100 text-blue-700 text-xs rounded-full px-1.5 py-0.5 font-medium">
                {famVersiones.length}
              </span>
            </TabsTrigger>
          )}
        </TabsList>
        
        <TabsContent value="conceptos">
          <Card>
            <CardHeader>
              <CardTitle>Conceptos de la Cotización</CardTitle>
            </CardHeader>
            <CardContent>
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Pos</TableHead>
                    <TableHead>Cantidad</TableHead>
                    <TableHead>Unidad</TableHead>
                    <TableHead>Descripción</TableHead>
                    <TableHead>No. Proyecto</TableHead>
                    <TableHead className="text-right">Precio Unitario</TableHead>
                    <TableHead className="text-right">Total + IVA</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {cotizacion.items.map((item) => (
                    <TableRow key={item.id}>
                      <TableCell>{item.posicion}</TableCell>
                      <TableCell>{item.cantidad}</TableCell>
                      <TableCell>{item.unidad}</TableCell>
                      <TableCell>{item.descripcion}</TableCell>
                      <TableCell>{item.numero_proyecto || '-'}</TableCell>
                      <TableCell className="text-right">{formatearMoneda(item.precio_unitario)}</TableCell>
                      <TableCell className="text-right">{formatearMoneda(item.total_item + item.iva_item)}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            </CardContent>
          </Card>
        </TabsContent>
        
        <TabsContent value="pagos">
          <div className="space-y-6">
            <Card>
              <CardHeader>
                <CardTitle>Historial de Pagos</CardTitle>
              </CardHeader>
              <CardContent>
                {pagos.length === 0 ? (
                  <div className="text-center py-8 text-gray-500">
                    No se han registrado pagos para esta cotización.
                  </div>
                ) : (
                  <Table>
                    <TableHeader>
                      <TableRow>
                        <TableHead>Tipo de Pago</TableHead>
                        <TableHead>Referencia</TableHead>
                        <TableHead>Fecha</TableHead>
                        <TableHead className="text-right">Monto</TableHead>
                      </TableRow>
                    </TableHeader>
                    <TableBody>
                      {pagos.map((pago) => (
                        <TableRow key={pago.id}>
                          <TableCell>{pago.tipo_pago}</TableCell>
                          <TableCell>{pago.referencia || '-'}</TableCell>
                          <TableCell>{formatearFecha(pago.fecha)}</TableCell>
                          <TableCell className="text-right">{formatearMoneda(pago.monto)}</TableCell>
                        </TableRow>
                      ))}
                    </TableBody>
                  </Table>
                )}
                
                <div className="mt-6 p-4 bg-blue-50 rounded-md">
                  <div className="flex justify-between items-center">
                    <span className="font-medium">Total de la Cotización:</span>
                    <span className="font-bold">{formatearMoneda(cotizacion.total)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="font-medium">Total Pagado:</span>
                    <span className="font-bold">{formatearMoneda(cotizacion.total - saldoPendiente)}</span>
                  </div>
                  <div className="flex justify-between items-center">
                    <span className="font-medium text-lg">Saldo Pendiente:</span>
                    <span className={`font-bold text-lg ${saldoPendiente > 0 ? 'text-red-600' : 'text-green-600'}`}>
                      {formatearMoneda(saldoPendiente)}
                    </span>
                  </div>
                </div>
              </CardContent>
            </Card>

            {saldoPendiente > 0 && (
              <Card>
                <CardHeader>
                  <CardTitle>Registrar Nuevo Pago</CardTitle>
                </CardHeader>
                <CardContent>
                  {erroresPago.length > 0 && (
                    <Alert className="mb-4">
                      <AlertDescription>
                        <ul className="list-disc list-inside">
                          {erroresPago.map((error, index) => (
                            <li key={index}>{error}</li>
                          ))}
                        </ul>
                      </AlertDescription>
                    </Alert>
                  )}
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
                    <div>
                      <Label>Tipo de Pago *</Label>
                      <Select 
                        value={formPago.tipo_pago} 
                        onValueChange={(value) => setFormPago(prev => ({ ...prev, tipo_pago: value as any }))}
                      >
                        <SelectTrigger>
                          <SelectValue placeholder="Seleccionar..." />
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
                    
                    <div>
                      <Label>Referencia</Label>
                      <Input
                        value={formPago.referencia}
                        onChange={(e) => setFormPago(prev => ({ ...prev, referencia: e.target.value }))}
                        placeholder="Número de referencia"
                      />
                    </div>
                    
                    <div>
                      <Label>Monto *</Label>
                      <Input
                        type="number"
                        value={formPago.monto}
                        onChange={(e) => setFormPago(prev => ({ ...prev, monto: parseFloat(e.target.value) || 0 }))}
                        placeholder="0.00"
                        min="0"
                        max={saldoPendiente}
                        step="0.01"
                      />
                    </div>
                    
                    <div>
                      <Label>Fecha *</Label>
                      <Input
                        type="date"
                        value={formPago.fecha}
                        onChange={(e) => setFormPago(prev => ({ ...prev, fecha: e.target.value }))}
                      />
                    </div>
                  </div>
                  
                  <div className="mt-6">
                    <Button onClick={manejarCrearPago}>
                      <Save className="mr-2 h-4 w-4" />
                      Registrar Pago
                    </Button>
                  </div>
                </CardContent>
              </Card>
            )}
          </div>
        </TabsContent>

        {famVersiones.length > 1 && (
          <TabsContent value="versiones">
            <Card>
              <CardHeader>
                <CardTitle className="flex items-center gap-2">
                  <GitBranch className="h-5 w-5 text-blue-600" />
                  Historial de Versiones
                </CardTitle>
              </CardHeader>
              <CardContent>
                <div className="relative">
                  {/* Línea vertical del timeline */}
                  <div className="absolute left-5 top-3 bottom-3 w-0.5 bg-gray-200" />

                  <div className="space-y-4">
                    {famVersiones.map((version, idx) => {
                      const esCurrent = version.id === cotizacion.id;
                      const esUltima = idx === famVersiones.length - 1;

                      return (
                        <div key={version.id} className="relative flex items-start gap-4 pl-12">
                          {/* Punto del timeline */}
                          <div className={`
                            absolute left-3 top-3 w-4 h-4 rounded-full border-2 flex items-center justify-center
                            ${esCurrent
                              ? 'bg-blue-600 border-blue-600'
                              : 'bg-white border-gray-300'}
                          `}>
                            {esCurrent && <div className="w-1.5 h-1.5 rounded-full bg-white" />}
                          </div>

                          <div className={`
                            flex-1 rounded-lg border p-4 transition-colors
                            ${esCurrent
                              ? 'border-blue-300 bg-blue-50'
                              : 'border-gray-200 bg-white hover:border-gray-300'}
                          `}>
                            <div className="flex items-start justify-between gap-3">
                              <div>
                                <div className="flex items-center gap-2 flex-wrap">
                                  <span className="font-semibold text-gray-900">{version.folio}</span>
                                  <span className="text-xs bg-gray-100 text-gray-600 px-2 py-0.5 rounded-full">
                                    v{version.version || 1}
                                  </span>
                                  {esCurrent && (
                                    <span className="text-xs bg-blue-100 text-blue-700 px-2 py-0.5 rounded-full font-medium">
                                      Actual
                                    </span>
                                  )}
                                  {esUltima && !esCurrent && (
                                    <span className="text-xs bg-green-100 text-green-700 px-2 py-0.5 rounded-full">
                                      Más reciente
                                    </span>
                                  )}
                                </div>
                                <div className="mt-1 flex items-center gap-3 text-sm text-gray-500">
                                  <span>{formatearFecha(version.fecha)}</span>
                                  <span>·</span>
                                  <Badge className={estadoColors[version.estado]} style={{ fontSize: '11px' }}>
                                    {version.estado}
                                  </Badge>
                                </div>
                                {version.descripcion && (
                                  <p className="mt-1 text-sm text-gray-600">{version.descripcion}</p>
                                )}
                              </div>

                              <div className="text-right shrink-0">
                                <div className="font-bold text-gray-900">{formatearMoneda(version.total)}</div>
                                {idx > 0 && famVersiones[idx - 1].total !== version.total && (
                                  <div className={`text-xs mt-0.5 ${version.total > famVersiones[idx - 1].total ? 'text-red-600' : 'text-green-600'}`}>
                                    {version.total > famVersiones[idx - 1].total ? '▲' : '▼'}{' '}
                                    {formatearMoneda(Math.abs(version.total - famVersiones[idx - 1].total))} vs v{(famVersiones[idx - 1].version || 1)}
                                  </div>
                                )}
                              </div>
                            </div>

                            {!esCurrent && onVerCotizacion && (
                              <div className="mt-3 pt-3 border-t border-gray-100">
                                <button
                                  onClick={() => onVerCotizacion(version.id)}
                                  className="text-sm text-blue-600 hover:text-blue-800 flex items-center gap-1"
                                >
                                  <ExternalLink className="h-3.5 w-3.5" />
                                  Ver esta versión
                                </button>
                              </div>
                            )}
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </CardContent>
            </Card>
          </TabsContent>
        )}
      </Tabs>

      <EnviarEmailDialog
        open={emailDialogOpen}
        onOpenChange={setEmailDialogOpen}
        cotizacionId={cotizacion.id}
        cotizacionFolio={cotizacion.folio}
        clienteEmail={cliente?.correo}
        clienteNombre={cliente?.nombre_contacto || cliente?.nombre_razon_social}
      />
    </div>
  );
}
