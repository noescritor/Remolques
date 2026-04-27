import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Textarea } from '../ui/textarea';
import { Alert, AlertDescription } from '../ui/alert';
import { Mail, Send, Loader2, Info } from 'lucide-react';
import { toast } from "sonner";
import { supabase } from '../../utils/supabase/client';

interface EnviarEmailDialogProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  cotizacionId: string;
  cotizacionFolio: string;
  clienteEmail?: string;
  clienteNombre?: string;
}

export function EnviarEmailDialog({
  open,
  onOpenChange,
  cotizacionId,
  cotizacionFolio,
  clienteEmail,
  clienteNombre
}: EnviarEmailDialogProps) {
  const [destinatario, setDestinatario] = useState(clienteEmail || '');
  const [asunto, setAsunto] = useState(`Cotización ${cotizacionFolio} - IDEALLY`);
  const [mensaje, setMensaje] = useState(
    clienteNombre
      ? `Estimado/a ${clienteNombre},\n\nEs un placer enviarle nuestra cotización ${cotizacionFolio}.\n\nQuedo a sus órdenes para cualquier duda o aclaración.\n\nSaludos cordiales.`
      : `Estimado/a cliente,\n\nEs un placer enviarle nuestra cotización ${cotizacionFolio}.\n\nQuedo a sus órdenes para cualquier duda o aclaración.\n\nSaludos cordiales.`
  );
  const [enviando, setEnviando] = useState(false);

  const handleEnviar = async () => {
    if (!destinatario.trim()) {
      toast.error('Ingresa el correo del destinatario');
      return;
    }

    // Validación básica de email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(destinatario)) {
      toast.error('Ingresa un correo electrónico válido');
      return;
    }

    if (!asunto.trim()) {
      toast.error('Ingresa el asunto del email');
      return;
    }

    setEnviando(true);

    try {
      const { data: { session } } = await supabase.auth.getSession();
      const token = session?.access_token || import.meta.env.VITE_SUPABASE_ANON_KEY;

      const response = await fetch(
        `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382/enviar-email`,
        {
          method: 'POST',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': `Bearer ${token}`
          },
          body: JSON.stringify({
            destinatario: destinatario.trim(),
            asunto: asunto.trim(),
            mensaje: mensaje.trim(),
            cotizacionId
          })
        }
      );

      const data = await response.json();

      if (!response.ok) {
        console.error('Error sending email:', data);
        
        // Show detailed error with hint
        const errorMsg = data.error || 'Error al enviar el email';
        const hint = data.hint;
        
        if (hint) {
          toast.error(errorMsg, {
            description: hint,
            duration: 8000
          });
        } else {
          toast.error(errorMsg);
        }
        
        setEnviando(false);
        return;
      }

      toast.success(`Email enviado exitosamente a ${destinatario}`);
      onOpenChange(false);
      
      // Reset form
      setDestinatario(clienteEmail || '');
      setAsunto(`Cotización ${cotizacionFolio} - IDEALLY`);
      setMensaje(
        clienteNombre
          ? `Estimado/a ${clienteNombre},\n\nEs un placer enviarle nuestra cotización ${cotizacionFolio}.\n\nQuedo a sus órdenes para cualquier duda o aclaración.\n\nSaludos cordiales.`
          : `Estimado/a cliente,\n\nEs un placer enviarle nuestra cotización ${cotizacionFolio}.\n\nQuedo a sus órdenes para cualquier duda o aclaración.\n\nSaludos cordiales.`
      );

    } catch (error) {
      console.error('Error sending email:', error);
      toast.error(
        error instanceof Error ? error.message : 'Error al enviar el email',
        {
          description: 'Verifica tu conexión a internet y la configuración de Resend',
          duration: 6000
        }
      );
      setEnviando(false);
    }
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[600px]">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2">
            <Mail className="w-5 h-5 text-purple-600" />
            Enviar Cotización por Email
          </DialogTitle>
          <DialogDescription>
            Envía la cotización {cotizacionFolio} directamente al correo del cliente
          </DialogDescription>
        </DialogHeader>

        <div className="space-y-4 py-4">
          <Alert className="bg-blue-50 border-blue-200">
            <Info className="h-4 w-4 text-blue-600" />
            <AlertDescription className="text-sm text-blue-900 space-y-2">
              <div>
                <strong>Configuración de Resend:</strong> Para enviar emails, necesitas una API key de Resend.
                {' '}
                <a 
                  href="https://resend.com/api-keys" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="underline hover:text-blue-700"
                >
                  Obtén una gratis aquí
                </a>
                {' y configúrala en los secretos de Supabase (RESEND_API_KEY).'}
              </div>
              <div className="pt-2 border-t border-blue-300">
                <strong>💡 Tip:</strong> Para enviar desde tu propio dominio (ej: ventas@ideally.com.mx), 
                primero verifica tu dominio en{' '}
                <a 
                  href="https://resend.com/domains" 
                  target="_blank" 
                  rel="noopener noreferrer"
                  className="underline hover:text-blue-700"
                >
                  Resend
                </a>
                {' y luego configúralo en Ajustes > Configuración de Emails.'}
              </div>
            </AlertDescription>
          </Alert>

          <div className="space-y-2">
            <Label htmlFor="destinatario">Destinatario *</Label>
            <Input
              id="destinatario"
              type="email"
              placeholder="cliente@ejemplo.com"
              value={destinatario}
              onChange={(e) => setDestinatario(e.target.value)}
              disabled={enviando}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="asunto">Asunto *</Label>
            <Input
              id="asunto"
              placeholder="Asunto del correo"
              value={asunto}
              onChange={(e) => setAsunto(e.target.value)}
              disabled={enviando}
            />
          </div>

          <div className="space-y-2">
            <Label htmlFor="mensaje">Mensaje (opcional)</Label>
            <Textarea
              id="mensaje"
              placeholder="Escribe un mensaje personalizado..."
              value={mensaje}
              onChange={(e) => setMensaje(e.target.value)}
              rows={6}
              disabled={enviando}
            />
            <p className="text-xs text-gray-500">
              El email incluirá automáticamente los detalles de la cotización
            </p>
          </div>
        </div>

        <DialogFooter>
          <Button
            variant="outline"
            onClick={() => onOpenChange(false)}
            disabled={enviando}
          >
            Cancelar
          </Button>
          <Button
            onClick={handleEnviar}
            disabled={enviando}
            className="bg-purple-600 hover:bg-purple-700"
          >
            {enviando ? (
              <>
                <Loader2 className="w-4 h-4 mr-2 animate-spin" />
                Enviando...
              </>
            ) : (
              <>
                <Send className="w-4 h-4 mr-2" />
                Enviar Email
              </>
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
