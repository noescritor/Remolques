import { useState, useEffect, useRef } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import SignaturePad from 'signature_pad';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Badge } from '../ui/badge';
import { CheckCircle, XCircle, MessageSquare, Loader2, AlertCircle, PenTool, RotateCcw, Download } from 'lucide-react';
import { LogoIdeally } from '../Cotizaciones/LogoIdeally';
import { formatearMoneda } from '../../utils/calculations';

const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;

type Accion = 'idle' | 'aprobar' | 'rechazar' | 'cambios' | 'done';

export function PortalCliente() {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();
  const [cotizacion, setCotizacion] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [accion, setAccion] = useState<Accion>('idle');
  const [enviando, setEnviando] = useState(false);
  const [comentario, setComentario] = useState('');
  const [firmaNombre, setFirmaNombre] = useState('');
  const [resultado, setResultado] = useState<'aprobado' | 'rechazado' | 'cambios' | null>(null);

  const canvasRef = useRef<HTMLCanvasElement>(null);
  const sigPadRef = useRef<SignaturePad | null>(null);

  useEffect(() => {
    if (!token) return;
    fetch(`${BASE_URL}/portal/${token}`)
      .then(r => {
        if (!r.ok) {
          return r.json().then(data => {
            throw new Error(data.error || data.message || `Error del servidor (${r.status})`);
          }).catch(() => {
            throw new Error(`Error del servidor (${r.status})`);
          });
        }
        return r.json();
      })
      .then(data => {
        setCotizacion(data);
      })
      .catch(err => setError(err.message || 'No se pudo cargar la cotización.'))
      .finally(() => setLoading(false));
  }, [token]);

  useEffect(() => {
    if (accion === 'aprobar' && canvasRef.current) {
      sigPadRef.current = new SignaturePad(canvasRef.current, {
        backgroundColor: 'rgb(255,255,255)',
        penColor: 'rgb(30,30,30)',
      });
      const resizeCanvas = () => {
        if (!canvasRef.current || !sigPadRef.current) return;
        const ratio = window.devicePixelRatio || 1;
        const w = canvasRef.current.offsetWidth || 600;
        const h = canvasRef.current.offsetHeight || 150;
        canvasRef.current.width = w * ratio;
        canvasRef.current.height = h * ratio;
        canvasRef.current.getContext('2d')?.scale(ratio, ratio);
        sigPadRef.current.clear();
      };
      // rAF ensures canvas is painted before reading dimensions
      requestAnimationFrame(resizeCanvas);
    }
  }, [accion]);

  const getUserIP = async () => {
    try {
      const r = await fetch('https://api.ipify.org?format=json');
      const d = await r.json();
      return d.ip;
    } catch { return null; }
  };

  const handleAprobar = async () => {
    const firma = sigPadRef.current;
    const firmaVacia = !firma || firma.isEmpty();
    if (!firmaNombre.trim()) { alert('Por favor escribe tu nombre para firmar.'); return; }
    if (firmaVacia) { alert('Por favor dibuja tu firma en el recuadro.'); return; }
    setEnviando(true);
    try {
      const ip = await getUserIP();
      await fetch(`${BASE_URL}/portal/${token}/aprobar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          firma_imagen: firma!.toDataURL('image/png'),
          firma_nombre: firmaNombre,
          firma_ip: ip,
        }),
      });
      setResultado('aprobado');
      setAccion('done');
    } catch { alert('Error al enviar. Intenta de nuevo.'); }
    finally { setEnviando(false); }
  };

  const handleRechazar = async () => {
    if (!comentario.trim()) { alert('Por favor indica el motivo de rechazo.'); return; }
    setEnviando(true);
    try {
      await fetch(`${BASE_URL}/portal/${token}/rechazar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ comentario }),
      });
      setResultado('rechazado');
      setAccion('done');
    } catch { alert('Error al enviar. Intenta de nuevo.'); }
    finally { setEnviando(false); }
  };

  const handleCambios = async () => {
    if (!comentario.trim()) { alert('Por favor describe los cambios que necesitas.'); return; }
    setEnviando(true);
    try {
      await fetch(`${BASE_URL}/portal/${token}/solicitar-cambios`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ comentario }),
      });
      setResultado('cambios');
      setAccion('done');
    } catch { alert('Error al enviar. Intenta de nuevo.'); }
    finally { setEnviando(false); }
  };

  if (loading) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <Loader2 className="w-8 h-8 animate-spin text-purple-600" />
    </div>
  );

  if (error) return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center space-y-3">
        <AlertCircle className="w-12 h-12 text-red-400 mx-auto" />
        <h2 className="text-xl font-semibold text-gray-800">{error}</h2>
        <p className="text-gray-500">Si crees que es un error, contacta a IDEALLY.</p>
      </div>
    </div>
  );

  if (accion === 'done') return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50">
      <div className="text-center space-y-4 max-w-sm">
        {resultado === 'aprobado' && <>
          <CheckCircle className="w-16 h-16 text-green-500 mx-auto" />
          <h2 className="text-2xl font-bold text-gray-900">¡Cotización Aprobada!</h2>
          <p className="text-gray-600">Tu firma fue registrada exitosamente. El equipo de IDEALLY se pondrá en contacto contigo para continuar.</p>
        </>}
        {resultado === 'rechazado' && <>
          <XCircle className="w-16 h-16 text-red-400 mx-auto" />
          <h2 className="text-2xl font-bold text-gray-900">Cotización Rechazada</h2>
          <p className="text-gray-600">Recibimos tu respuesta. IDEALLY revisará tus comentarios y te contactará.</p>
        </>}
        {resultado === 'cambios' && <>
          <MessageSquare className="w-16 h-16 text-blue-400 mx-auto" />
          <h2 className="text-2xl font-bold text-gray-900">Cambios Solicitados</h2>
          <p className="text-gray-600">Tus comentarios fueron enviados. El equipo de IDEALLY preparará una nueva versión.</p>
        </>}
      </div>
    </div>
  );

  const cot = cotizacion;
  const cliente = cot.cliente || {};
  const items: any[] = cot.items || [];
  const yaDecidido = ['Aprobada', 'Cancelada', 'Pagada'].includes(cot.estado);

  return (
    <div className="min-h-screen bg-gray-50 py-8 px-4">
      <div id="portal-content" className="max-w-3xl mx-auto space-y-6">

        {/* Header */}
        <div className="bg-gradient-to-r from-purple-700 to-purple-900 rounded-xl p-6 text-white flex items-center gap-4">
          <LogoIdeally size={48} />
          <div>
            <h1 className="text-2xl font-bold">IDEALLY</h1>
            <p className="text-purple-200 text-sm">Arte · Diseño · Ingeniería</p>
          </div>
          <div className="ml-auto text-right flex items-center gap-3">
            <div>
              <div className="text-xs text-purple-300">Folio</div>
              <div className="font-mono font-bold text-lg">{cot.folio}</div>
            </div>
            <button
              onClick={() => navigate(`/cotizacion/${token}/pdf`)}
              className="print:hidden bg-white/20 hover:bg-white/30 transition-colors rounded-lg p-2.5"
              title="Descargar cotización en PDF"
            >
              <Download className="h-5 w-5" />
            </button>
          </div>
        </div>

        {/* Estado actual */}
        {yaDecidido && (
          <div className={`rounded-lg p-4 text-center font-medium ${
            cot.estado === 'Aprobada' || cot.estado === 'Pagada'
              ? 'bg-green-50 text-green-800 border border-green-200'
              : 'bg-gray-50 text-gray-600 border border-gray-200'
          }`}>
            Esta cotización ya fue <strong>{cot.estado}</strong>.
          </div>
        )}

        {/* Datos del cliente */}
        <Card>
          <CardHeader><CardTitle className="text-base">Para</CardTitle></CardHeader>
          <CardContent className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-sm">
            <div><span className="text-gray-500">Cliente:</span> <span className="font-medium">{cliente.nombre_razon_social}</span></div>
            {cliente.nombre_contacto && <div><span className="text-gray-500">Contacto:</span> <span className="font-medium">{cliente.nombre_contacto}</span></div>}
            {cliente.correo && <div><span className="text-gray-500">Email:</span> <span className="font-medium">{cliente.correo}</span></div>}
            {cliente.telefono && <div><span className="text-gray-500">Tel:</span> <span className="font-medium">{cliente.telefono}</span></div>}
            <div><span className="text-gray-500">Fecha:</span> <span className="font-medium">{cot.fecha}</span></div>
            <div><span className="text-gray-500">Válida:</span> <span className="font-medium">{cot.validez_dias} días</span></div>
            {cot.descripcion && <div className="sm:col-span-2"><span className="text-gray-500">Proyecto:</span> <span className="font-medium">{cot.descripcion}</span></div>}
          </CardContent>
        </Card>

        {/* Conceptos */}
        <Card>
          <CardHeader><CardTitle className="text-base">Conceptos</CardTitle></CardHeader>
          <CardContent>
            <div className="overflow-x-auto">
              <table className="w-full text-sm">
                <thead>
                  <tr className="border-b text-gray-500 text-xs uppercase tracking-wide">
                    <th className="pb-2 text-left">Descripción</th>
                    <th className="pb-2 text-right w-16">Cant.</th>
                    <th className="pb-2 text-right w-28">Precio unit.</th>
                    <th className="pb-2 text-right w-28">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {items.map((item, i) => (
                    <tr key={i} className="py-2">
                      <td className="py-2 pr-4 text-gray-800">{item.descripcion}</td>
                      <td className="py-2 text-right text-gray-600">{item.cantidad} {item.unidad}</td>
                      <td className="py-2 text-right text-gray-600">{formatearMoneda(item.precio_unitario)}</td>
                      <td className="py-2 text-right font-medium">{formatearMoneda(item.total_item + item.iva_item)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="mt-4 pt-4 border-t space-y-1 text-sm">
              <div className="flex justify-between text-gray-600"><span>Subtotal</span><span>{formatearMoneda(cot.subtotal)}</span></div>
              {cot.con_factura && <div className="flex justify-between text-gray-600"><span>IVA (16%)</span><span>{formatearMoneda(cot.iva)}</span></div>}
              <div className="flex justify-between font-bold text-lg text-gray-900 pt-1 border-t"><span>Total</span><span className="text-green-700">{formatearMoneda(cot.total)}</span></div>
              {cot.con_factura && <div className="text-xs text-gray-400 text-right">Incluye factura</div>}
            </div>
          </CardContent>
        </Card>

        {/* Nota */}
        {cot.nota && (
          <div className="bg-amber-50 border border-amber-200 rounded-lg p-4 text-sm text-amber-900">
            <div className="font-medium mb-1">Nota</div>
            {cot.nota}
          </div>
        )}

        {/* Acciones (solo si no está decidido) */}
        {!yaDecidido && accion === 'idle' && (
          <Card>
            <CardHeader><CardTitle className="text-base">Tu respuesta</CardTitle></CardHeader>
            <CardContent className="flex flex-col sm:flex-row gap-3">
              <Button className="flex-1 bg-green-600 hover:bg-green-700 text-white" onClick={() => setAccion('aprobar')}>
                <CheckCircle className="mr-2 h-4 w-4" /> Aprobar cotización
              </Button>
              <Button variant="outline" className="flex-1 border-blue-300 text-blue-700 hover:bg-blue-50" onClick={() => setAccion('cambios')}>
                <MessageSquare className="mr-2 h-4 w-4" /> Solicitar cambios
              </Button>
              <Button variant="outline" className="flex-1 border-red-300 text-red-600 hover:bg-red-50" onClick={() => setAccion('rechazar')}>
                <XCircle className="mr-2 h-4 w-4" /> Rechazar
              </Button>
            </CardContent>
          </Card>
        )}

        {/* Panel: Aprobar + Firma */}
        {accion === 'aprobar' && (
          <Card className="border-green-200">
            <CardHeader>
              <CardTitle className="text-base text-green-800 flex items-center gap-2">
                <PenTool className="h-4 w-4" /> Firma tu aprobación
              </CardTitle>
            </CardHeader>
            <CardContent className="space-y-4">
              <div>
                <Label>Nombre completo *</Label>
                <Input placeholder="Nombre del firmante" value={firmaNombre} onChange={e => setFirmaNombre(e.target.value)} />
              </div>
              <div>
                <Label>Firma *</Label>
                <div className="relative mt-1 border-2 border-dashed border-gray-300 rounded-lg bg-white" style={{ height: 150 }}>
                  <canvas ref={canvasRef} className="w-full h-full rounded-lg" style={{ touchAction: 'none' }} />
                  <button
                    onClick={() => sigPadRef.current?.clear()}
                    className="absolute top-2 right-2 text-xs text-gray-400 hover:text-gray-600 flex items-center gap-1"
                  >
                    <RotateCcw className="h-3 w-3" /> Limpiar
                  </button>
                </div>
                <p className="text-xs text-gray-400 mt-1">Dibuja tu firma con el mouse o con el dedo en pantalla táctil</p>
              </div>
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setAccion('idle')} disabled={enviando}>Cancelar</Button>
                <Button className="flex-1 bg-green-600 hover:bg-green-700" onClick={handleAprobar} disabled={enviando}>
                  {enviando ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />Enviando…</> : '✅ Confirmar aprobación'}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Panel: Solicitar cambios */}
        {accion === 'cambios' && (
          <Card className="border-blue-200">
            <CardHeader><CardTitle className="text-base text-blue-800">¿Qué cambios necesitas?</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <Textarea
                placeholder="Describe los cambios que necesitas (precios, conceptos, cantidades, etc.)"
                value={comentario} onChange={e => setComentario(e.target.value)} rows={4}
              />
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setAccion('idle')} disabled={enviando}>Cancelar</Button>
                <Button className="flex-1 bg-blue-600 hover:bg-blue-700 text-white" onClick={handleCambios} disabled={enviando}>
                  {enviando ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />Enviando…</> : '💬 Enviar comentarios'}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Panel: Rechazar */}
        {accion === 'rechazar' && (
          <Card className="border-red-200">
            <CardHeader><CardTitle className="text-base text-red-800">Motivo de rechazo</CardTitle></CardHeader>
            <CardContent className="space-y-4">
              <Textarea
                placeholder="Cuéntanos por qué rechazas esta cotización para mejorar nuestra propuesta"
                value={comentario} onChange={e => setComentario(e.target.value)} rows={4}
              />
              <div className="flex gap-3">
                <Button variant="outline" onClick={() => setAccion('idle')} disabled={enviando}>Cancelar</Button>
                <Button className="flex-1 bg-red-600 hover:bg-red-700 text-white" onClick={handleRechazar} disabled={enviando}>
                  {enviando ? <><Loader2 className="mr-2 h-4 w-4 animate-spin" />Enviando…</> : '❌ Confirmar rechazo'}
                </Button>
              </div>
            </CardContent>
          </Card>
        )}

        {/* Footer */}
        <div className="text-center text-xs text-gray-400 pb-4">
          <p>IDEALLY · Arte · Diseño · Ingeniería · Puebla, México</p>
          <p className="mt-1">Este link es único y personal. Válido hasta {cot.token_expira_en ? new Date(cot.token_expira_en).toLocaleDateString('es-MX') : 'la fecha de vigencia'}.</p>
        </div>
      </div>
    </div>
  );
}
