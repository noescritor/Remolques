import { useState } from 'react';
import { Button } from '../ui/button';
import { PDFTemplateLeolca } from './PDFTemplateLeolca';
import { ArrowLeft, Printer } from 'lucide-react';

interface PDFFullPageLeolcaProps {
  cotizacion: any;
  cliente: any;
  productos: any[];
  ajustes: any;
  onVolver: () => void;
}

export function PDFFullPageLeolca({ 
  cotizacion, 
  cliente, 
  productos, 
  ajustes, 
  onVolver
}: PDFFullPageLeolcaProps) {
  
  const handlePrint = () => {
    // Hide UI elements not meant for print
    const toolbar = document.getElementById('pdf-toolbar');
    if (toolbar) toolbar.style.display = 'none';
    
    // Set body background to white for printing
    const originalBg = document.body.style.backgroundColor;
    document.body.style.backgroundColor = 'white';
    
    window.print();
    
    // Restore
    if (toolbar) toolbar.style.display = 'flex';
    document.body.style.backgroundColor = originalBg;
  };

  return (
    <div className="min-h-screen bg-gray-100 pb-12">
      {/* TOOLBAR (Solo visible en pantalla) */}
      <div id="pdf-toolbar" className="sticky top-0 z-50 bg-white border-b shadow-sm p-4 flex items-center justify-between mb-8 print:hidden">
        <div className="flex items-center gap-4">
          <Button variant="outline" size="sm" onClick={onVolver}>
            <ArrowLeft className="h-4 w-4 mr-2" />
            Volver a la Cotización
          </Button>
          <span className="font-medium text-gray-700 hidden sm:inline-block">
            Vista Previa de Impresión - Formato Leolca
          </span>
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={handlePrint} className="bg-red-700 hover:bg-red-800 text-white">
            <Printer className="h-4 w-4 mr-2" />
            Imprimir / Guardar PDF
          </Button>
        </div>
      </div>

      {/* RENDER DEL DOCUMENTO */}
      <div className="print:m-0 print:p-0 print:shadow-none overflow-x-auto overflow-y-hidden pb-10">
        <PDFTemplateLeolca 
          cotizacion={cotizacion}
          cliente={cliente}
          productos={productos}
          ajustes={ajustes}
        />
      </div>
    </div>
  );
}
