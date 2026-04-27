import { useState } from 'react';
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '../ui/dialog';
import { Button } from '../ui/button';
import { PDFTemplate } from './PDFTemplate';
import { Download, X, Printer } from 'lucide-react';

interface PDFPreviewProps {
  isOpen: boolean;
  onClose: () => void;
  cotizacion: any;
  cliente: any;
  productos: any[];
  ajustes: any;
  onExportPDF: (cotizacion: any) => void;
}

export function PDFPreview({ 
  isOpen, 
  onClose, 
  cotizacion, 
  cliente, 
  productos, 
  ajustes, 
  onExportPDF 
}: PDFPreviewProps) {
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

  const handleExportPDF = async () => {
    setIsExporting(true);
    try {
      await onExportPDF(cotizacion);
    } catch (error) {
      console.error('Error al exportar PDF:', error);
    } finally {
      setIsExporting(false);
    }
  };

  const handlePrint = () => {
    window.print();
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="max-w-7xl h-[90vh] flex flex-col">
        <DialogHeader className="flex-shrink-0">
          <div className="flex items-center justify-between">
            <div>
              <DialogTitle>Vista Previa - PDF Cotización {cotizacion?.folio}</DialogTitle>
              <DialogDescription>
                Previsualiza el documento PDF antes de exportar o imprimir
              </DialogDescription>
            </div>
            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={handlePrint}
                className="flex items-center gap-2"
              >
                <Printer className="h-4 w-4" />
                Imprimir
              </Button>
              <Button
                onClick={handleExportPDF}
                disabled={isExporting}
                size="sm"
                className="flex items-center gap-2"
              >
                <Download className="h-4 w-4" />
                {isExporting ? 'Exportando...' : 'Descargar PDF'}
              </Button>
              <Button
                variant="ghost"
                size="sm"
                onClick={onClose}
                className="h-8 w-8 p-0"
              >
                <X className="h-4 w-4" />
              </Button>
            </div>
          </div>
        </DialogHeader>
        
        <div className="flex-1 overflow-auto bg-gray-50 p-4">
          <div className="max-w-5xl mx-auto">
            <PDFTemplate
              cotizacion={cotizacion}
              cliente={cliente}
              items={items}
              ajustes={ajustes}
            />
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}