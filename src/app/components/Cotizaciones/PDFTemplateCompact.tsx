import { Cotizacion, Cliente, Producto, Ajustes } from '../../types';
import { formatearMoneda, formatearFecha, calcularTotalesCotizacion, calcularTotalesCotizacionServiciosAware, totalItemServicio } from '../../utils/calculations';
import { LogoIdeally } from './LogoIdeally';

interface PDFTemplateCompactProps {
  cotizacion: Cotizacion;
  cliente?: Cliente | null;
  productos: Producto[];
  ajustes: Ajustes;
}

export function PDFTemplateCompact({ cotizacion, cliente, productos, ajustes }: PDFTemplateCompactProps) {
  // Crear índice de productos para búsquedas rápidas
  const productosIdx = productos.reduce((acc, producto) => {
    if (producto?.id) {
      acc[producto.id] = producto;
    }
    return acc;
  }, {} as Record<string, Producto>);
  
  const totales = calcularTotalesCotizacionServiciosAware(
    cotizacion.items || [], 
    productosIdx, 
    ajustes.iva_por_defecto, 
    cotizacion.con_factura !== false
  );
  
  const shouldShowLogo = (!ajustes.nombre_empresa || 
                          ajustes.nombre_empresa === '' || 
                          ajustes.nombre_empresa.toUpperCase() === 'IDEALLY');

  return (
    <div id="pdf-content" className="bg-white p-6 text-gray-900 max-w-4xl mx-auto min-h-[297mm]" style={{ fontFamily: 'system-ui, -apple-system, sans-serif', fontSize: '14px', lineHeight: '1.4' }}>
      
      {/* HEADER - Logo y Información de la Empresa */}
      <div className="border-b-2 border-blue-600 pb-4 mb-6">
        <div className="flex justify-between items-start">
          {/* Logo y Nombre */}
          <div className="flex items-center gap-4">
            {shouldShowLogo && (
              <LogoIdeally size={48} />
            )}
            <div>
              <h1 className="text-2xl font-bold text-blue-600 leading-none">{ajustes.nombre_empresa || 'IDEALLY'}</h1>
              <p className="text-gray-600 text-sm mt-1">{ajustes.tagline || 'Arte . Diseño . Ingeniería'}</p>
            </div>
          </div>
          
          {/* Información de Contacto */}
          <div className="text-right text-sm text-gray-600">
            {ajustes.direccion && <p className="font-semibold text-gray-900">{ajustes.direccion}</p>}
            {ajustes.email && <p>{ajustes.email}</p>}
            {ajustes.telefono && <p>{ajustes.telefono}</p>}
            {ajustes.sitio_web && <p>{ajustes.sitio_web}</p>}
          </div>
        </div>
      </div>

      {/* INFORMACIÓN PRINCIPAL */}
      <div className="grid grid-cols-2 gap-8 mb-6">
        {/* Datos del Cliente */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-3 border-b border-gray-300 pb-1">FACTURAR A</h2>
          <div className="text-sm space-y-1">
            <p className="font-semibold text-gray-900">{cliente?.nombre_razon_social || 'Cliente no disponible'}</p>
            {cliente?.nombre_contacto && <p>Atención: {cliente.nombre_contacto}</p>}
            {cliente?.direccion && <p>{cliente.direccion}</p>}
            {cliente?.ciudad && <p>{cliente.ciudad}, {cliente.estado || ''}</p>}
            {cliente?.correo && <p className="text-blue-600">{cliente.correo}</p>}
            {cliente?.telefono && <p>{cliente.telefono}</p>}
          </div>
        </div>

        {/* Datos de la Cotización */}
        <div>
          <h2 className="text-lg font-bold text-gray-900 mb-3 border-b border-gray-300 pb-1">COTIZACIÓN</h2>
          <div className="grid grid-cols-2 gap-4 text-sm">
            <div>
              <p className="font-semibold text-gray-700">Número:</p>
              <p className="text-lg font-bold text-blue-600">{cotizacion.folio}</p>
            </div>
            <div>
              <p className="font-semibold text-gray-700">Fecha:</p>
              <p>{formatearFecha(cotizacion.fecha)}</p>
            </div>
            <div>
              <p className="font-semibold text-gray-700">Vigencia:</p>
              <p>{cotizacion.validez_dias} días</p>
            </div>
            <div>
              <p className="font-semibold text-gray-700">Estado:</p>
              <span className={`px-2 py-1 rounded text-xs font-medium ${
                cotizacion.estado === 'Aprobada' ? 'bg-green-100 text-green-800' :
                cotizacion.estado === 'Enviada' ? 'bg-blue-100 text-blue-800' :
                cotizacion.estado === 'Borrador' ? 'bg-gray-100 text-gray-800' :
                'bg-red-100 text-red-800'
              }`}>
                {cotizacion.estado}
              </span>
            </div>
          </div>
        </div>
      </div>

      {/* DESCRIPCIÓN */}
      {cotizacion.descripcion && (
        <div className="mb-4 p-3 bg-blue-50 border border-blue-200 rounded">
          <p className="text-sm font-semibold text-blue-900 mb-1">Descripción del proyecto:</p>
          <p className="text-sm text-blue-800">{cotizacion.descripcion}</p>
        </div>
      )}

      {/* TABLA DE SERVICIOS */}
      <div className="mb-6">
        <h2 className="text-lg font-bold text-gray-900 mb-3">SERVICIOS / PRODUCTOS</h2>
        
        <table className="w-full border-collapse border border-gray-300 text-sm">
          <thead>
            <tr className="bg-gray-100">
              <th className="border border-gray-300 p-2 text-left font-semibold">DESCRIPCIÓN</th>
              <th className="border border-gray-300 p-2 text-center font-semibold w-20">CANT.</th>
              <th className="border border-gray-300 p-2 text-right font-semibold w-24">PRECIO UNIT.</th>
              <th className="border border-gray-300 p-2 text-right font-semibold w-24">TOTAL</th>
            </tr>
          </thead>
          <tbody>
            {cotizacion.items?.map((item, index) => {
              const producto = item.producto_id ? productosIdx[item.producto_id] : 
                              productos.find(p => p.id === item.numero_proyecto);
              
              const esServicio = producto?.tipo === 'servicio';
              let totalCalculado = { total: 0, subtotal: 0 };
              
              if (esServicio && producto?.servicio) {
                totalCalculado = totalItemServicio(item, producto, cotizacion.con_factura !== false ? ajustes.iva_por_defecto : 0);
              } else {
                const subtotal = (item.cantidad || 0) * (item.precio_unitario || 0);
                const iva = cotizacion.con_factura !== false ? subtotal * ajustes.iva_por_defecto : 0;
                totalCalculado = { subtotal, total: subtotal + iva };
              }
              
              return (
                <tr key={index} className="hover:bg-gray-50">
                  <td className="border border-gray-300 p-2">
                    <div>
                      <p className="font-medium text-gray-900">
                        {producto?.nombre || item.descripcion}
                      </p>
                      {producto?.descripcion && (
                        <p className="text-xs text-gray-600 mt-1 leading-tight">
                          {producto.descripcion}
                        </p>
                      )}
                      {esServicio && producto?.servicio && (
                        <div className="text-xs text-blue-600 mt-1 space-y-1">
                          {(producto.servicio.modo === 'unico' || producto.servicio.modo === 'hibrido') && item.incluir_setup && (
                            <div>• Setup incluido</div>
                          )}
                          {(producto.servicio.modo === 'suscripcion' || producto.servicio.modo === 'hibrido') && (
                            <div>• {item.meses_cobrados || 1} meses de servicio</div>
                          )}
                          {producto.servicio.por_asiento && item.asientos_extra && (
                            <div>• {item.asientos_extra} asientos extra</div>
                          )}
                        </div>
                      )}
                    </div>
                  </td>
                  <td className="border border-gray-300 p-2 text-center">
                    {item.cantidad} {item.unidad}
                  </td>
                  <td className="border border-gray-300 p-2 text-right">
                    {esServicio && producto?.servicio ? (
                      <div className="text-xs">
                        {producto.servicio.modo === 'unico' && (
                          <span>{formatearMoneda(producto.servicio.setup_precio || 0)}</span>
                        )}
                        {producto.servicio.modo === 'suscripcion' && (
                          <span>{formatearMoneda(producto.servicio.recur_precio || 0)}/{producto.servicio.periodo}</span>
                        )}
                        {producto.servicio.modo === 'hibrido' && (
                          <div className="space-y-0.5">
                            <div>Setup: {formatearMoneda(producto.servicio.setup_precio || 0)}</div>
                            <div>{formatearMoneda(producto.servicio.recur_precio || 0)}/{producto.servicio.periodo}</div>
                          </div>
                        )}
                      </div>
                    ) : (
                      formatearMoneda(item.precio_unitario || 0)
                    )}
                  </td>
                  <td className="border border-gray-300 p-2 text-right font-medium">
                    {formatearMoneda(totalCalculado.total)}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* RESUMEN DE SERVICIOS */}
      {(() => {
        const servicios = (cotizacion.items || []).filter(item => {
          const producto = item.producto_id ? productosIdx[item.producto_id] : productos.find(p => p.id === item.numero_proyecto);
          return producto?.tipo === 'servicio';
        });
        
        if (servicios.length === 0) return null;
        
        return (
          <div className="mb-6 bg-blue-50 border border-blue-200 rounded-lg p-4">
            <h3 className="font-bold text-blue-900 mb-3">{ajustes?.resumen_servicios?.titulo || 'RESUMEN DE SERVICIOS'}</h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              {servicios.map((item, index) => {
                const producto = item.producto_id ? productosIdx[item.producto_id] : productos.find(p => p.id === item.numero_proyecto);
                const servicio = producto?.servicio;
                
                if (!servicio) return null;
                
                return (
                  <div key={index} className="border border-blue-200 rounded p-3 bg-white">
                    <p className="font-semibold text-blue-900 mb-2">{producto?.nombre || item.descripcion}</p>
                    
                    {servicio.modo === 'unico' && (
                      <div className="space-y-1">
                        <p className="text-blue-700">• {ajustes?.resumen_servicios?.pago_unico || 'Servicio de pago único'}</p>
                        <p className="text-blue-600">• {ajustes?.resumen_servicios?.setup_completo || 'Incluye setup completo'}</p>
                      </div>
                    )}
                    
                    {servicio.modo === 'suscripcion' && (
                      <div className="space-y-1">
                        <p className="text-blue-700">• {ajustes?.resumen_servicios?.suscripcion || 'Servicio de suscripción'}</p>
                        <p className="text-blue-600">• {ajustes?.resumen_servicios?.periodo_label || 'Periodo:'} {servicio.periodo}</p>
                        <p className="text-blue-600">• {ajustes?.resumen_servicios?.meses_contratados_label || 'Meses contratados:'} {item.meses_cobrados || 1}</p>
                        {servicio.min_meses > 1 && (
                          <p className="text-blue-600">• {ajustes?.resumen_servicios?.permanencia_minima_label || 'Permanencia mínima:'} {servicio.min_meses} meses</p>
                        )}
                      </div>
                    )}
                    
                    {servicio.modo === 'hibrido' && (
                      <div className="space-y-1">
                        <p className="text-blue-700">• {ajustes?.resumen_servicios?.hibrido || 'Servicio híbrido'}</p>
                        {item.incluir_setup && <p className="text-blue-600">• {ajustes?.resumen_servicios?.setup_inicial || 'Incluye setup inicial'}</p>}
                        <p className="text-blue-600">• Suscripción {servicio.periodo}</p>
                        <p className="text-blue-600">• {ajustes?.resumen_servicios?.meses_contratados_label || 'Meses contratados:'} {item.meses_cobrados || 1}</p>
                      </div>
                    )}
                    
                    {servicio.por_asiento && (
                      <div className="mt-2 pt-2 border-t border-blue-200">
                        <p className="text-blue-600">• {ajustes?.resumen_servicios?.base_asientos_label || 'Base:'} {servicio.asientos_incluidos} asientos incluidos</p>
                        {item.asientos_extra && item.asientos_extra > 0 && (
                          <p className="text-blue-600">• {ajustes?.resumen_servicios?.asientos_adicionales_label || 'Asientos adicionales:'} {item.asientos_extra}</p>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>
          </div>
        );
      })()}

      {/* TOTALES Y OBSERVACIONES */}
      <div className="grid grid-cols-3 gap-6 mb-6">
        {/* Observaciones */}
        <div className="col-span-2">
          <h3 className="font-bold text-gray-900 mb-2">TÉRMINOS Y CONDICIONES</h3>
          <div className="text-sm text-gray-700 space-y-1">
            {cotizacion.nota ? (
              <div>
                {cotizacion.nota.split('\n').map((line, i) => (
                  <p key={i} className="mb-1">{line}</p>
                ))}
              </div>
            ) : (
              <div>
                <p>• El 50% de anticipo es requerido para iniciar el proyecto</p>
                <p>• El saldo restante se paga al finalizar el proyecto</p>
                <p>• Esta cotización tiene una vigencia de {cotizacion.validez_dias} días</p>
                <p>• {cotizacion.con_factura ? 'Los precios incluyen IVA (18%)' : 'Cotización SIN FACTURA - No incluye IVA'}</p>
              </div>
            )}
          </div>
          
          {/* Métodos de Pago */}
          <div className="mt-4">
            <h4 className="font-semibold text-gray-900 mb-1">MÉTODOS DE PAGO</h4>
            <div className="text-sm text-gray-700">
              <p>• Transferencia Bancaria</p>
              <p>• PayPal</p>
              <p>• Bitcoin</p>
              {ajustes.cuenta_bancaria && (
                <p className="mt-1 text-xs bg-gray-100 p-2 rounded">
                  Cuenta: {ajustes.cuenta_bancaria}
                </p>
              )}
            </div>
          </div>
        </div>

        {/* Totales */}
        <div>
          <div className="bg-gray-50 border border-gray-300 p-4 rounded-lg">
            <div className="flex justify-between items-center mb-2">
              <h3 className="font-bold text-gray-900">RESUMEN</h3>
              {!cotizacion.con_factura && (
                <span className="bg-orange-100 text-orange-800 px-2 py-1 rounded text-xs font-medium">
                  SIN FACTURA
                </span>
              )}
            </div>
            
            <div className="space-y-2 text-sm">
              <div className="flex justify-between">
                <span className="text-gray-700">Subtotal:</span>
                <span className="font-medium">{formatearMoneda(totales.subtotal)}</span>
              </div>
              
              {totales.iva > 0 && (
                <div className="flex justify-between">
                  <span className="text-gray-700">IVA ({(ajustes.iva_por_defecto * 100).toFixed(0)}%):</span>
                  <span className="font-medium">{formatearMoneda(totales.iva)}</span>
                </div>
              )}
              
              <div className="border-t border-gray-300 pt-2 mt-2">
                <div className="flex justify-between items-center">
                  <span className="font-bold text-gray-900">TOTAL:</span>
                  <span className="font-bold text-xl text-blue-600">
                    {formatearMoneda(totales.total)}
                  </span>
                </div>
              </div>
            </div>
          </div>
          
          {/* QR Code Placeholder */}

        </div>
      </div>

      {/* FOOTER */}
      <div className="border-t border-gray-300 pt-4 text-center">
        <div className="grid grid-cols-3 gap-4 text-sm text-gray-600">
          <div>
            <p className="font-semibold text-gray-900">Gracias por su confianza</p>
            <p>¿Preguntas? Contáctanos</p>
          </div>
          <div>
            {ajustes.email && <p>{ajustes.email}</p>}
            {ajustes.telefono && <p>{ajustes.telefono}</p>}
          </div>
          <div>
            {ajustes.sitio_web && <p>{ajustes.sitio_web}</p>}
            <p className="text-xs text-gray-400 mt-1">
              Cotización generada el {formatearFecha(new Date().toISOString())}
            </p>
          </div>
        </div>
      </div>
    </div>
  );
}