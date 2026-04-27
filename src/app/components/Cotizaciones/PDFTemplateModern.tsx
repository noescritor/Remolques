import { Cotizacion, Cliente, Producto, Ajustes } from '../../types';
import { formatearMoneda, formatearFecha, calcularTotalesCotizacion } from '../../utils/calculations';
import svgPaths from "../../imports/svg-pqfvhu2ekl";

interface PDFTemplateModernProps {
  cotizacion: Cotizacion;
  cliente: Cliente;
  productos: Producto[];
  ajustes: Ajustes;
}

function LogoSection() {
  return (
    <div className="flex items-center gap-4">
      {/* Logo SVG */}
      <div className="relative w-14 h-18">
        <svg className="w-full h-full" fill="none" preserveAspectRatio="none" viewBox="0 0 52 70">
          <g>
            <path d={svgPaths.p2e60300} fill="black" />
            <path d={svgPaths.p2ab27150} fill="black" />
          </g>
        </svg>
      </div>
      
      {/* Company Name */}
      <div className="flex flex-col">
        <div className="font-black text-2xl tracking-wider">
          NOCTURNO
        </div>
        <div className="font-normal text-2xl tracking-wider">
          STUDIO
        </div>
      </div>
    </div>
  );
}

function Header({ cotizacion, ajustes }: { cotizacion: Cotizacion; ajustes: Ajustes }) {
  return (
    <div className="border-b-2 border-gray-300 pb-8 mb-8">
      <div className="grid grid-cols-3 gap-8 items-start">
        
        {/* Logo */}
        <div className="col-span-1">
          <LogoSection />
        </div>

        {/* Title */}
        <div className="col-span-1 text-center">
          <h1 className="text-6xl font-semibold text-gray-900 tracking-tight">
            Cotización
          </h1>
          <p className="text-2xl text-gray-700 mt-2">
            {cotizacion.descripcion || cotizacion.nota || 'Servicios profesionales'}
          </p>
        </div>

        {/* Quote Details */}
        <div className="col-span-1 text-right space-y-4">
          <div className="border-l-2 border-gray-300 pl-8">
            <div className="mb-4">
              <p className="text-2xl font-semibold text-gray-900 tracking-tight">
                Cotización #
              </p>
              <p className="text-2xl text-gray-700">
                {cotizacion.folio}
              </p>
            </div>
            
            <div className="mb-4">
              <p className="text-2xl font-semibold text-gray-900 tracking-tight">
                Fecha de emisión
              </p>
              <p className="text-2xl text-gray-700">
                {formatearFecha(cotizacion.fecha || '')}
              </p>
            </div>
            
            <div>
              <p className="text-2xl font-semibold text-gray-900 tracking-tight">
                Vigencia
              </p>
              <p className="text-2xl text-gray-700">
                {cotizacion.validez_dias || 30} días
              </p>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function ClientInfo({ cliente, cotizacion, ajustes }: { cliente: Cliente; cotizacion: Cotizacion; ajustes: Ajustes }) {
  const totales = calcularTotalesCotizacion(cotizacion, ajustes.iva_por_defecto);
  
  return (
    <div className="grid grid-cols-2 gap-8 mb-8">
      {/* Client Info */}
      <div>
        <h3 className="text-2xl font-semibold text-gray-900 mb-3">
          Cotización para:
        </h3>
        <div className="text-xl text-gray-700 space-y-1">
          <p className="font-medium">{cliente.nombre_razon_social}</p>
          {cliente.direccion && <p>{cliente.direccion}</p>}
          {cliente.ciudad && <p>{cliente.ciudad}</p>}
          {cliente.correo && <p>{cliente.correo}</p>}
          {cliente.telefono && <p>{cliente.telefono}</p>}
        </div>
      </div>

      {/* Total */}
      <div className="text-right">
        <p className="text-2xl font-semibold text-gray-900 mb-2">
          Total:
        </p>
        <p className="text-6xl font-semibold text-gray-900 tracking-tight">
          {formatearMoneda(totales.total)}
        </p>
      </div>
    </div>
  );
}

function ServicesTable({ cotizacion, productos }: { cotizacion: Cotizacion; productos: Producto[] }) {
  return (
    <div className="border-2 border-gray-300 mb-8">
      {/* Table Header */}
      <div className="bg-white border-b-2 border-gray-300 p-6">
        <div className="grid grid-cols-12 gap-4">
          <div className="col-span-6">
            <h3 className="text-lg font-bold text-gray-900 tracking-wide uppercase">
              CARGOS
            </h3>
          </div>
          <div className="col-span-3 text-center">
            <h3 className="text-lg font-bold text-gray-900 tracking-wide uppercase">
              CANTIDAD
            </h3>
          </div>
          <div className="col-span-3 text-right">
            <h3 className="text-lg font-bold text-gray-900 tracking-wide uppercase">
              TOTAL
            </h3>
          </div>
        </div>
      </div>

      {/* Table Body */}
      <div className="p-6">
        {cotizacion.items?.map((item, index) => {
          const producto = productos.find(p => p.id === item.numero_proyecto);
          return (
            <div key={index} className="border-b border-gray-300 pb-6 mb-6 last:border-b-0 last:mb-0">
              <div className="grid grid-cols-12 gap-4 items-start">
                {/* Description */}
                <div className="col-span-6">
                  <h4 className="text-2xl font-medium text-gray-900 mb-2">
                    {producto?.nombre || item.descripcion}
                  </h4>
                  {item.descripcion && item.descripcion !== producto?.nombre && (
                    <p className="text-lg text-gray-600 mb-4 leading-relaxed">
                      {item.descripcion}
                    </p>
                  )}
                  
                  {/* Additional Details */}
                  {item.observaciones && (
                    <div className="text-lg text-gray-600 space-y-2">
                      <p><strong>Entregables:</strong></p>
                      <div className="ml-4">
                        {item.observaciones.split('\n').map((line, i) => (
                          <p key={i}>{line}</p>
                        ))}
                      </div>
                    </div>
                  )}
                </div>

                {/* Quantity */}
                <div className="col-span-3 text-center">
                  <p className="text-2xl font-medium text-gray-900">
                    {item.cantidad}
                  </p>
                </div>

                {/* Total */}
                <div className="col-span-3 text-right">
                  <p className="text-2xl font-medium text-gray-900">
                    {formatearMoneda(item.total || 0)}
                  </p>
                </div>
              </div>
            </div>
          );
        })}
      </div>
    </div>
  );
}

function TotalsSection({ cotizacion, ajustes }: { cotizacion: Cotizacion; ajustes: Ajustes }) {
  const totales = calcularTotalesCotizacion(cotizacion, ajustes.iva_por_defecto);
  
  return (
    <div className="flex justify-end mb-8">
      <div className="border-2 border-gray-300 p-6 w-80">
        <div className="flex justify-between items-center mb-4">
          <span className="text-2xl font-semibold text-gray-900">Totales</span>
          {!cotizacion.con_factura && (
            <span className="bg-orange-100 text-orange-800 px-2 py-1 rounded text-sm font-medium">
              SIN FACTURA
            </span>
          )}
        </div>
        <div className="space-y-4">
          <div className="flex justify-between items-center text-2xl font-medium">
            <span className="text-gray-900">Sub-Total</span>
            <span className="text-gray-900">{formatearMoneda(totales.subtotal)}</span>
          </div>
          
          {totales.iva > 0 && (
            <div className="flex justify-between items-center text-2xl font-medium">
              <span className="text-gray-900">IVA (18%)</span>
              <span className="text-gray-900">{formatearMoneda(totales.iva)}</span>
            </div>
          )}
          
          <div className="border-t-2 border-gray-900 pt-4">
            <div className="flex justify-between items-center text-2xl font-semibold">
              <span className="text-gray-900">Total</span>
              <span className="text-gray-900">{formatearMoneda(totales.total)}</span>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function NotesSection({ cotizacion }: { cotizacion: Cotizacion }) {
  const defaultNotes = [
    "Nuestro cliente deberá pagar el 50% de anticipo del servicio y el otro 50% se deberá pagar al finalizar el proyecto o el mes."
  ];
  
  const notes = cotizacion.observaciones ? 
    cotizacion.observaciones.split('\n').filter(note => note.trim()) : 
    defaultNotes;

  return (
    <div className="mb-8">
      <h3 className="text-2xl font-semibold text-gray-900 mb-4">
        Observaciones:
      </h3>
      <ol className="list-decimal list-inside space-y-2">
        {notes.map((note, index) => (
          <li key={index} className="text-lg text-gray-700 leading-relaxed">
            {note.trim()}
          </li>
        ))}
      </ol>
    </div>
  );
}

function Footer({ ajustes }: { ajustes: Ajustes }) {
  return (
    <div className="border-t-2 border-gray-300 pt-8">
      <div className="grid grid-cols-3 gap-8">
        
        {/* Payment Methods */}
        <div>
          <h3 className="text-2xl font-semibold text-gray-900 mb-4">
            Pagos:
          </h3>
          <p className="text-xl text-gray-700">
            Transferencia bancaria
          </p>
          {ajustes.cuenta_bancaria && (
            <p className="text-lg text-gray-600 mt-2">
              {ajustes.cuenta_bancaria}
            </p>
          )}
        </div>

        {/* Contact */}
        <div>
          <h3 className="text-2xl font-semibold text-gray-900 mb-4">
            Contacto:
          </h3>
          <div className="text-xl text-gray-700 space-y-1">
            <p>{ajustes.nombre_empresa || 'Empresa'}</p>
            <p>{ajustes.email || 'contacto@empresa.com'}</p>
            {ajustes.sitio_web && (
              <p>
                Web: <span className="underline">{ajustes.sitio_web}</span>
              </p>
            )}
            <p>{ajustes.telefono || '+51 999 999 999'}</p>
          </div>
        </div>

        {/* QR or Additional Payment Methods */}
        <div className="text-center">
          <h3 className="text-2xl font-semibold text-gray-900 mb-4">
            Otros métodos de pago
          </h3>
          <div className="w-32 h-32 bg-gray-200 mx-auto flex items-center justify-center rounded-lg">
            <span className="text-gray-500 text-sm">QR Code</span>
          </div>
        </div>
      </div>
    </div>
  );
}

export function PDFTemplateModern({ cotizacion, cliente, productos, ajustes }: PDFTemplateModernProps) {
  return (
    <div id="pdf-content" className="bg-white max-w-5xl mx-auto p-8 text-gray-900" style={{ fontFamily: 'Manrope, sans-serif' }}>
      {/* Header */}
      <Header cotizacion={cotizacion} ajustes={ajustes} />
      
      {/* Client Info and Total */}
      <ClientInfo cliente={cliente} cotizacion={cotizacion} ajustes={ajustes} />
      
      {/* Services Table */}
      <ServicesTable cotizacion={cotizacion} productos={productos} />
      
      {/* Totals */}
      <TotalsSection cotizacion={cotizacion} ajustes={ajustes} />
      
      {/* Notes */}
      <NotesSection cotizacion={cotizacion} />
      
      {/* Footer */}
      <Footer ajustes={ajustes} />
    </div>
  );
}