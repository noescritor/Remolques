import { useState } from 'react';
import { Button } from '../ui/button';
import { PDFTemplateCompact } from './PDFTemplateCompact';
import { ArrowLeft, Download, Printer } from 'lucide-react';

interface PDFFullPageCompactProps {
  cotizacion: any;
  cliente: any;
  productos: any[];
  ajustes: any;
  onVolver: () => void;
  onExportPDF: (cotizacion: any) => void;
}

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

function triggerPrint(onDone?: () => void) {
  const toolbar = document.getElementById('pdf-toolbar');
  if (toolbar) toolbar.style.display = 'none';

  requestAnimationFrame(() => {
    setTimeout(() => {
      window.print();
      setTimeout(() => {
        if (toolbar) toolbar.style.display = 'flex';
        onDone?.();
      }, 600);
    }, 120);
  });
}

export function PDFFullPageCompact({ 
  cotizacion, 
  cliente, 
  productos, 
  ajustes, 
  onVolver, 
  onExportPDF 
}: PDFFullPageCompactProps) {
  const [isExporting, setIsExporting] = useState(false);

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Estilos de impresión inyectados en <head> */}
      <style dangerouslySetInnerHTML={{ __html: PRINT_STYLES }} />

      {/* Barra de herramientas fija */}
      <div 
        id="pdf-toolbar"
        className="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm"
        style={{ display: 'flex' }}
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 w-full">
          <div className="flex items-center justify-between h-16">
            <div className="flex items-center gap-4">
              <Button variant="outline" onClick={onVolver}>
                <ArrowLeft className="mr-2 h-4 w-4" />
                Volver
              </Button>
              <div>
                <h1 className="text-lg font-medium">Cotización PDF - {cotizacion?.folio}</h1>
                <p className="text-sm text-gray-500">
                  Diseño compacto optimizado para una página
                </p>
              </div>
            </div>
            
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                onClick={() => triggerPrint()}
                className="flex items-center gap-2"
              >
                <Printer className="h-4 w-4" />
                Imprimir
              </Button>
              <Button
                onClick={() => {
                  setIsExporting(true);
                  triggerPrint(() => setIsExporting(false));
                }}
                disabled={isExporting}
                className="flex items-center gap-2"
              >
                <Download className="h-4 w-4" />
                {isExporting ? 'Preparando...' : 'Exportar PDF'}
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Contenido del PDF */}
      <div id="pdf-preview-wrapper" className="py-8 bg-gray-100">
        <div className="max-w-5xl mx-auto px-4">
          <div className="bg-white rounded-lg shadow-lg overflow-hidden">
            <PDFTemplateCompact
              cotizacion={cotizacion}
              cliente={cliente}
              productos={productos}
              ajustes={ajustes}
            />
          </div>
        </div>
      </div>
    </div>
  );
}