import Group5 from '../../imports/Group5';

interface PDFTemplateProps {
  cotizacion: any;
  cliente: any;
  items: any[];
  ajustes: any;
}

// Estilos específicos para PDF con colores RGB compatibles con html2canvas
const pdfStyles = `
  #pdf-content {
    --background: #ffffff !important;
    --foreground: #262626 !important;
    --card: #ffffff !important;
    --card-foreground: #262626 !important;
    --primary: #030213 !important;
    --primary-foreground: #ffffff !important;
    --secondary: #f1f5f9 !important;
    --secondary-foreground: #030213 !important;
    --muted: #ececf0 !important;
    --muted-foreground: #717182 !important;
    --accent: #e9ebef !important;
    --accent-foreground: #030213 !important;
    --border: rgba(0, 0, 0, 0.1) !important;
    --ring: #6b7280 !important;
    -webkit-print-color-adjust: exact !important;
    color-adjust: exact !important;
    background: white !important;
    color: #262626 !important;
  }
  #pdf-content * {
    -webkit-print-color-adjust: exact !important;
    color-adjust: exact !important;
  }
  #pdf-content .bg-gray-50 {
    background-color: #f9fafb !important;
  }
  #pdf-content .bg-gray-100 {
    background-color: #f3f4f6 !important;
  }
  #pdf-content .bg-white {
    background-color: #ffffff !important;
  }
  #pdf-content .text-gray-600 {
    color: #4b5563 !important;
  }
  #pdf-content .text-gray-700 {
    color: #374151 !important;
  }
  #pdf-content .text-gray-500 {
    color: #6b7280 !important;
  }
  #pdf-content .border-gray-200 {
    border-color: #e5e7eb !important;
  }
  #pdf-content .border-gray-300 {
    border-color: #d1d5db !important;
  }
`;

function formatearFecha(fecha: string) {
  return new Date(fecha).toLocaleDateString('es-ES');
}

function formatearMoneda(cantidad: number) {
  return new Intl.NumberFormat('es-MX', {
    style: 'currency',
    currency: 'MXN'
  }).format(cantidad);
}

function PDFHeader({ cotizacion, ajustes }: { cotizacion: any, ajustes: any }) {
  return (
    <div className="bg-[rgba(0,0,0,1)] text-white p-8 rounded-t-lg">
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 items-center">
        {/* Logo y nombre de empresa */}
        <div className="lg:col-span-2">
          <div className="mb-2">
            <div className="w-32 h-10">
              <Group5 />
            </div>
          </div>
          <div className="space-y-1 text-sm opacity-90">
            <p>Retorno Pascual Mendoza # 27, Inf. La Cienega</p>
            <p>Puebla, Puebla</p>
            <p>Tel: 221-120-29756 | Contacto: Luis Angel Hernández Hernández</p>
          </div>
        </div>

        {/* Información de cotización */}
        <div className="lg:text-right space-y-2">
          <h2 className="text-xl font-bold text-blue-200 font-[Abel] font-normal">COTIZACIÓN</h2>
          <div className="space-y-1 text-sm">
            <div className="flex justify-between lg:justify-end lg:gap-4">
              <span className="font-medium">Folio:</span>
              <span>{cotizacion?.folio}</span>
            </div>
            <div className="flex justify-between lg:justify-end lg:gap-4">
              <span className="font-medium">Fecha:</span>
              <span>{formatearFecha(cotizacion?.fechaCreacion)}</span>
            </div>
            <div className="flex justify-between lg:justify-end lg:gap-4">
              <span className="font-medium">Página:</span>
              <span>1 de 1</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ClienteInfo({ cliente }: { cliente: any }) {
  return (
    <div className="bg-gray-50 p-6 border-b">
      <h3 className="text-lg font-semibold mb-4 text-gray-800">Información del Cliente</h3>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">
            Nombre/Razón Social
          </label>
          <div className="bg-white p-3 rounded-md border border-gray-200">
            {cliente?.nombre_razon_social || 'No especificado'}
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">
            Contacto
          </label>
          <div className="bg-white p-3 rounded-md border border-gray-200">
            {cliente?.nombre_contacto || 'No especificado'}
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">
            Teléfono
          </label>
          <div className="bg-white p-3 rounded-md border border-gray-200">
            {cliente?.telefono || 'No especificado'}
          </div>
        </div>
        <div>
          <label className="block text-sm font-medium text-gray-600 mb-1">
            Correo
          </label>
          <div className="bg-white p-3 rounded-md border border-gray-200">
            {cliente?.correo || 'No especificado'}
          </div>
        </div>
      </div>
    </div>
  );
}

function TablaConceptos({ items, totales }: { items: any[], totales: any }) {
  return (
    <div className="p-6">
      <h3 className="text-lg font-semibold mb-4 text-gray-800">Conceptos</h3>
      
      {/* Tabla responsiva */}
      <div className="overflow-x-auto">
        <table className="w-full border-collapse border border-gray-300">
          <thead>
            <tr className="bg-gray-100">
              <th className="border border-gray-300 px-3 py-2 text-left text-sm font-semibold">Pos.</th>
              <th className="border border-gray-300 px-3 py-2 text-left text-sm font-semibold">Cant.</th>
              <th className="border border-gray-300 px-3 py-2 text-left text-sm font-semibold">Unidad</th>
              <th className="border border-gray-300 px-3 py-2 text-left text-sm font-semibold">Descripción</th>
              <th className="border border-gray-300 px-3 py-2 text-left text-sm font-semibold">No. Proyecto</th>
              <th className="border border-gray-300 px-3 py-2 text-right text-sm font-semibold">Precio Unit.</th>
              <th className="border border-gray-300 px-3 py-2 text-right text-sm font-semibold">Total + IVA</th>
            </tr>
          </thead>
          <tbody>
            {items.map((item, index) => (
              <tr key={index} className="hover:bg-gray-50">
                <td className="border border-gray-300 px-3 py-2 text-sm">{index + 1}</td>
                <td className="border border-gray-300 px-3 py-2 text-sm">{item.cantidad}</td>
                <td className="border border-gray-300 px-3 py-2 text-sm">{item.unidad}</td>
                <td className="border border-gray-300 px-3 py-2 text-sm">
                  <div className="max-w-xs truncate" title={item.descripcion}>
                    {item.descripcion}
                  </div>
                </td>
                <td className="border border-gray-300 px-3 py-2 text-sm">{item.numeroProyecto || '-'}</td>
                <td className="border border-gray-300 px-3 py-2 text-sm text-right">
                  {formatearMoneda(item.precioUnitario)}
                </td>
                <td className="border border-gray-300 px-3 py-2 text-sm text-right font-medium">
                  {formatearMoneda(item.total)}
                </td>
              </tr>
            ))}
            {items.length === 0 && (
              <tr>
                <td colSpan={7} className="border border-gray-300 px-3 py-8 text-center text-gray-500">
                  No hay conceptos en esta cotización
                </td>
              </tr>
            )}
          </tbody>
        </table>
      </div>

      {/* Totales */}
      <div className="mt-6 flex justify-end">
        <div className="w-full max-w-xs space-y-2">
          <div className="flex justify-between py-1">
            <span className="text-sm">Subtotal:</span>
            <span className="text-sm">{formatearMoneda(totales.subtotal)}</span>
          </div>
          <div className="flex justify-between py-1">
            <span className="text-sm">IVA (16%):</span>
            <span className="text-sm">{formatearMoneda(totales.iva)}</span>
          </div>
          <div className="border-t border-gray-300 pt-2">
            <div className="flex justify-between py-1">
              <span className="font-bold text-blue-600">Total:</span>
              <span className="font-bold text-blue-600">{formatearMoneda(totales.total)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function PDFFooter({ cotizacion }: { cotizacion: any }) {
  return (
    <div className="bg-gray-50 p-6 rounded-b-lg border-t">
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Nota Aclaratoria */}
        <div>
          <h4 className="font-medium text-gray-700 mb-2">Nota Aclaratoria</h4>
          <div className="bg-white p-4 rounded-md border border-gray-200 min-h-[120px]">
            <p className="text-sm text-gray-700 leading-relaxed">
              {cotizacion?.notaAclaratoria || 
                'Se requiere un adelanto del 60% para comenzar producci��n. Los precios incluyen IVA. Esta cotización tiene una vigencia de 30 días.'}
            </p>
          </div>
        </div>

        {/* Firma Digital */}
        <div>
          <h4 className="font-medium text-gray-700 mb-2">Firma Digital / Sello</h4>
          <div className="bg-white p-4 rounded-md border-2 border-dashed border-gray-300 min-h-[120px] flex items-center justify-center">
            <div className="text-center text-gray-500">
              <p className="text-sm">Espacio reservado para</p>
              <p className="text-sm font-medium">Firma Digital o Sello</p>
            </div>
          </div>
        </div>
      </div>

      {/* Pie de página */}
      <div className="mt-6 pt-4 border-t border-gray-300 text-center">
        <p className="text-sm text-gray-600">
          Esta cotización es válida por 30 días a partir de la fecha de emisión.
        </p>
      </div>
    </div>
  );
}

export function PDFTemplate({ cotizacion, cliente, items, ajustes }: PDFTemplateProps) {
  // Calcular totales
  const subtotal = items.reduce((sum, item) => sum + (item.total || 0), 0);
  const iva = subtotal * 0.16;
  const total = subtotal + iva;

  const totales = {
    subtotal,
    iva,
    total
  };

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: pdfStyles }} />
      <div className="bg-white w-full max-w-full mx-auto shadow-lg rounded-lg overflow-hidden">
        <PDFHeader cotizacion={cotizacion} ajustes={ajustes} />
        <ClienteInfo cliente={cliente} />
        <TablaConceptos items={items} totales={totales} />
        <PDFFooter cotizacion={cotizacion} />
      </div>
    </>
  );
}