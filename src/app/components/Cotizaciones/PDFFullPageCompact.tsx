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

export function PDFFullPageCompact({ 
  cotizacion, 
  cliente, 
  productos, 
  ajustes, 
  onVolver, 
  onExportPDF 
}: PDFFullPageCompactProps) {
  const [isExporting, setIsExporting] = useState(false);

  const handleExportPDF = () => {
    setIsExporting(true);
    
    try {
      // Ocultar toolbar antes de imprimir
      const toolbar = document.getElementById('pdf-toolbar');
      if (toolbar) {
        toolbar.style.display = 'none';
      }
      
      setTimeout(() => {
        window.print();
        
        // Restaurar toolbar después de imprimir
        setTimeout(() => {
          if (toolbar) {
            toolbar.style.display = 'flex';
          }
          setIsExporting(false);
        }, 500);
      }, 100);
      
    } catch (error) {
      console.error('Error al imprimir:', error);
      alert('Error al imprimir. Usa Ctrl+P desde tu navegador.');
      setIsExporting(false);
    }
  };

  const handlePrint = () => {
    try {
      const toolbar = document.getElementById('pdf-toolbar');
      if (toolbar) {
        toolbar.style.display = 'none';
      }
      
      setTimeout(() => {
        window.print();
        
        setTimeout(() => {
          if (toolbar) {
            toolbar.style.display = 'flex';
          }
        }, 500);
      }, 100);
      
    } catch (error) {
      console.error('Error al imprimir:', error);
      alert('Error al imprimir. Usa Ctrl+P manualmente desde tu navegador.');
    }
  };

  return (
    <div className="min-h-screen bg-gray-100">
      {/* Barra de herramientas fija */}
      <div 
        id="pdf-toolbar"
        className="sticky top-0 z-10 bg-white border-b border-gray-200 shadow-sm print:hidden"
      >
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
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
                onClick={handlePrint}
                className="flex items-center gap-2"
              >
                <Printer className="h-4 w-4" />
                Imprimir
              </Button>
              <Button
                onClick={handleExportPDF}
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
      <div className="py-8">
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