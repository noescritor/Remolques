import { Cotizacion, Cliente, Producto, Ajustes } from '../../types';
import { formatearMoneda, formatearFecha, calcularTotalesCotizacion } from '../../utils/calculations';

interface PDFTemplateLeolcaProps {
  cotizacion: Cotizacion;
  cliente: Cliente;
  productos: Producto[];
  ajustes: Ajustes;
}

export function PDFTemplateLeolca({ cotizacion, cliente, productos, ajustes }: PDFTemplateLeolcaProps) {
  const totales = calcularTotalesCotizacion(cotizacion.items, productos, cotizacion.con_factura ? ajustes.iva_por_defecto : 0);

  return (
    <div className="bg-white min-h-[1056px] w-[816px] mx-auto text-black font-sans shadow-lg" style={{ fontFamily: "'Helvetica Neue', Helvetica, Arial, sans-serif" }}>
      {/* HEADER CORPORATIVO LEOLCA */}
      <div className="flex justify-between items-start border-b-4 border-red-700 pb-6 mb-6 pt-10 px-10">
        <div>
          {/* Logo Placeholder - En el futuro se puede inyectar el SVG/IMG de Leolca */}
          <h1 className="text-4xl font-black text-red-700 tracking-tighter">LEOLCA</h1>
          <p className="text-sm font-semibold tracking-widest text-gray-500 mt-1 uppercase">Remolques y Carrocerías</p>
        </div>
        <div className="text-right">
          <h2 className="text-3xl font-light text-gray-400 mb-2">COTIZACIÓN</h2>
          <div className="flex flex-col text-sm text-gray-600 gap-1">
            <p><span className="font-bold">Folio:</span> {cotizacion.folio}</p>
            <p><span className="font-bold">Fecha:</span> {formatearFecha(cotizacion.fecha)}</p>
            <p><span className="font-bold">Vigencia:</span> {cotizacion.validez_dias} días</p>
          </div>
        </div>
      </div>

      <div className="px-10 pb-10">
        {/* INFO CLIENTE */}
        <div className="bg-gray-50 p-4 rounded-lg mb-8 border border-gray-200">
          <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3">Datos del Cliente</h3>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="font-bold text-lg text-gray-800">{cliente.nombre_razon_social}</p>
              {cliente.nombre_contacto && <p className="text-gray-600">Atención: {cliente.nombre_contacto}</p>}
            </div>
            <div className="text-right text-gray-600">
              {cliente.telefono && <p>Tel: {cliente.telefono}</p>}
              {cliente.correo && <p>Email: {cliente.correo}</p>}
              {cliente.ciudad && <p>{cliente.ciudad}, {cliente.estado}</p>}
            </div>
          </div>
        </div>

        {/* DETALLE DE EQUIPOS (BOM) */}
        <div className="mb-10">
          <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-3 border-b pb-2">Descripción del Equipo</h3>
          
          <div className="space-y-8 mt-4">
            {cotizacion.items.map((item, idx) => {
              const esTerminado = item.sub_items && item.sub_items.length > 0;
              return (
                <div key={item.id} className="break-inside-avoid">
                  {/* Título del equipo y Precio */}
                  <div className="flex justify-between items-start bg-gray-800 text-white p-3 rounded-t-md">
                    <div>
                      <h4 className="text-lg font-bold">{item.cantidad}x {item.descripcion}</h4>
                      {item.nota && <p className="text-xs text-gray-300 mt-1">{item.nota}</p>}
                    </div>
                    <div className="text-right font-bold text-lg">
                      {formatearMoneda((item.cantidad || 1) * (item.precio_unitario || 0))}
                    </div>
                  </div>

                  {/* Lista de sub-componentes (BOM Configurado) */}
                  {item.metadata?.configuracion?.resumen_lineas ? (
                    <div className="border border-t-0 border-gray-200 p-4 rounded-b-md bg-white">
                      <p className="text-sm font-semibold text-gray-700 mb-3">Especificaciones Técnicas / Componentes:</p>
                      <ul className="grid grid-cols-2 gap-x-8 gap-y-2 text-sm text-gray-600 list-disc pl-5">
                        {item.metadata.configuracion.resumen_lineas.map((linea: string, i: number) => {
                          const [lbl, ...rest] = linea.split(':');
                          const val = rest.join(':').trim();
                          return (
                            <li key={i}>
                              <span className="font-semibold">{lbl}:</span> {val}
                            </li>
                          );
                        })}
                      </ul>
                    </div>
                  ) : item.sub_items?.length ? (
                    <div className="border border-t-0 border-gray-200 p-4 rounded-b-md bg-white">
                      <p className="text-sm font-semibold text-gray-700 mb-3">Especificaciones Técnicas / Componentes:</p>
                      <ul className="grid grid-cols-2 gap-x-8 gap-y-2 text-sm text-gray-600 list-disc pl-5">
                        {item.sub_items.map((sub, i) => (
                          <li key={i}>
                            <span className="font-medium text-gray-800">{sub.cantidad}x</span> {sub.nombre}
                          </li>
                        ))}
                      </ul>
                    </div>
                  ) : (
                    <div className="border border-t-0 border-gray-200 p-2 rounded-b-md bg-white text-sm text-gray-500">
                      Componente unitario.
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        </div>

        {/* TOTALES */}
        <div className="flex justify-end mb-12">
          <div className="w-64">
            <div className="flex justify-between py-2 border-b border-gray-200 text-sm">
              <span className="text-gray-500 font-medium">Subtotal</span>
              <span className="font-bold text-gray-800">{formatearMoneda(totales.subtotal)}</span>
            </div>
            {cotizacion.con_factura && (
              <div className="flex justify-between py-2 border-b border-gray-200 text-sm">
                <span className="text-gray-500 font-medium">IVA (16%)</span>
                <span className="font-bold text-gray-800">{formatearMoneda(totales.iva)}</span>
              </div>
            )}
            <div className="flex justify-between py-3 border-b-2 border-gray-800 text-lg">
              <span className="text-gray-800 font-black">TOTAL</span>
              <span className="font-black text-red-700">{formatearMoneda(totales.total)}</span>
            </div>
          </div>
        </div>

        {/* CONDICIONES LEGALES Y FIRMAS */}
        <div className="mt-auto pt-8 border-t border-gray-200">
          <div className="grid grid-cols-2 gap-12">
            <div>
              <h3 className="text-xs font-bold text-gray-400 uppercase tracking-wider mb-2">Términos Comerciales</h3>
              <ul className="text-[11px] text-gray-500 space-y-1 list-disc pl-4">
                <li>Los precios están sujetos a cambios sin previo aviso.</li>
                <li>Tiempo de entrega: A convenir según disponibilidad de planta.</li>
                <li>Garantía de 1 año contra defectos de fabricación en estructura.</li>
                <li>Las especificaciones pueden variar ligeramente por motivos de producción.</li>
              </ul>
            </div>
            
            <div className="text-center pt-8">
              <div className="border-t border-gray-400 w-full mb-2"></div>
              <p className="text-xs font-bold text-gray-700">Firma de Aceptación</p>
              <p className="text-[10px] text-gray-500 mt-1">{cliente.nombre_razon_social}</p>
            </div>
          </div>
        </div>
        
      </div>
      
      <style>{`
        @media print {
          body { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
          @page { margin: 0; size: letter; }
        }
      `}</style>
    </div>
  );
}
