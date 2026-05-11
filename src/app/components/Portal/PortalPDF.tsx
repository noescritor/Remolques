import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { PDFTemplateCompact } from '../Cotizaciones/PDFTemplateCompact';
import { Button } from '../ui/button';
import { ArrowLeft, Download, Loader2, AlertCircle } from 'lucide-react';

const BASE_URL = `${import.meta.env.VITE_SUPABASE_URL}/functions/v1/make-server-feea4382`;

// CSS inyectado una sola vez para print media
const PRINT_STYLES = `
  @media print {
    @page { size: A4 portrait; margin: 0 !important; }
    html, body, #root { margin: 0 !important; padding: 0 !important; background: #fff !important; width: 100% !important; height: auto !important; }
    #pdf-toolbar { display: none !important; }
    #pdf-preview-wrapper { padding: 0 !important; margin: 0 !important; background: #fff !important; }
    #pdf-preview-wrapper > div { padding: 0 !important; margin: 0 !important; max-width: none !important; }
    #pdf-preview-wrapper > div > div { box-shadow: none !important; border-radius: 0 !important; width: 100% !important; }
  }
`;

export function PortalPDF() {
  const { token } = useParams<{ token: string }>();
  const navigate = useNavigate();
  const [cotizacion, setCotizacion] = useState<any>(null);
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!token) return;
    fetch(`${BASE_URL}/portal/${token}`)
      .then(r => r.json())
      .then(data => {
        if (data.error) setError(data.error);
        else setCotizacion(data);
      })
      .catch(() => setError('No se pudo cargar la cotización.'))
      .finally(() => setLoading(false));
  }, [token]);

  const handleExportPDF = () => {
    const toolbar = document.getElementById('pdf-toolbar');
    if (toolbar) toolbar.style.display = 'none';
    setTimeout(() => {
      window.print();
      setTimeout(() => {
        if (toolbar) toolbar.style.display = 'flex';
      }, 500);
    }, 100);
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
      </div>
    </div>
  );

  const cot = cotizacion;
  const cliente = cot.cliente || {};
  const ajustes = cot.ajustes || {};

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Estilos de impresión inyectados en <head> */}
      <style dangerouslySetInnerHTML={{ __html: PRINT_STYLES }} />

      {/* Toolbar */}
      <div id="pdf-toolbar" className="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm" style={{ display: 'flex' }}>
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <Button variant="outline" onClick={() => navigate(`/cotizacion/${token}`)}>
                <ArrowLeft className="mr-2 h-4 w-4" />
                Volver al portal
              </Button>
              <div>
                <h1 className="text-lg font-medium">Cotización {cot.folio}</h1>
                <p className="text-sm text-gray-500">Vista de descarga</p>
              </div>
            </div>
            <Button onClick={handleExportPDF} className="flex items-center gap-2">
              <Download className="h-4 w-4" />
              Descargar PDF
            </Button>
          </div>
        </div>
      </div>

      {/* Contenido del PDF */}
      <div id="pdf-preview-wrapper" className="py-8 bg-gray-100">
        <div className="max-w-5xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <PDFTemplateCompact
              cotizacion={cot}
              cliente={cliente}
              productos={[]}
              ajustes={ajustes}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
