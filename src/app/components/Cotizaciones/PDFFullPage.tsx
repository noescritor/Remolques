import { useState } from 'react';
import { Button } from '../ui/button';
import { PDFTemplateModern } from './PDFTemplateModern';
import { ArrowLeft, Download, Printer } from 'lucide-react';

interface PDFFullPageProps {
  cotizacion: any;
  cliente: any;
  productos: any[];
  ajustes: any;
  onVolver: () => void;
  onExportPDF: (cotizacion: any) => void;
}

export function PDFFullPage({ 
  cotizacion, 
  cliente, 
  productos, 
  ajustes, 
  onVolver, 
  onExportPDF 
}: PDFFullPageProps) {
  const [isExporting, setIsExporting] = useState(false);

  // Preparar items con información completa del producto
  const items = cotizacion?.items?.map((item: any) => {
    const producto = productos.find(p => p.id === item.numero_proyecto);
    return {
      ...item,
      descripcion: producto?.nombre || item.descripcion || 'Producto no encontrado',
      unidad: producto?.unidad || item.unidad || 'PZA',
      total: item.cantidad * item.precio_unitario
    };
  }) || [];

  const handleExportPDF = () => {
    setIsExporting(true);
    
    try {
      // Método ultra-simple: solo usar window.print()
      const toolbar = document.getElementById('pdf-toolbar');
      if (toolbar) {
        toolbar.style.display = 'none';
      }
      
      // Usar setTimeout para evitar bloqueos
      setTimeout(() => {
        window.print();
        
        // Restaurar toolbar
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
      // Método simple y confiable
      const toolbar = document.getElementById('pdf-toolbar');
      if (toolbar) {
        toolbar.style.display = 'none';
      }
      
      // Usar setTimeout para aplicar cambios antes de imprimir
      setTimeout(() => {
        window.print();
        
        // Restaurar toolbar después de imprimir
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
    <div className="min-h-screen bg-gray-50">
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
                <h1 className="text-lg font-medium">Vista Previa - PDF Cotización {cotizacion?.folio}</h1>
                <p className="text-sm text-gray-500">
                  Previsualiza el documento PDF antes de exportar o imprimir
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
                {isExporting ? 'Preparando...' : 'Imprimir / Exportar PDF'}
              </Button>
            </div>
          </div>
        </div>
      </div>

      {/* Contenido del PDF */}
      <div className="py-8">
        <div className="w-full max-w-none sm:max-w-2xl md:max-w-3xl lg:max-w-4xl xl:max-w-5xl mx-auto px-2 sm:px-4 md:px-6 lg:px-8 py-2 sm:py-4">
          <div className="bg-white border border-gray-200 rounded-lg sm:rounded-xl overflow-hidden min-h-[600px] sm:min-h-[700px] lg:min-h-[800px]">
            <div 
              id="pdf-content" 
              className="bg-white" 
              style={{ 
                width: '816px',
                height: '1056px',
                padding: '48px 60px',
                margin: '0 auto',
                transform: 'scale(0.8)',
                transformOrigin: 'top center',
                overflow: 'visible',
                boxSizing: 'border-box'
              }}
            >
              <PDFTemplateModern
                cotizacion={cotizacion}
                cliente={cliente}
                productos={productos}
                ajustes={ajustes}
              />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}