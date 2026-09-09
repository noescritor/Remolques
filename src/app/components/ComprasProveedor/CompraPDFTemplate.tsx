import { CompraProveedor, Proveedor, Producto } from '../../types';
import { formatearMoneda, formatearFecha } from '../../utils/calculations';

interface CompraPDFTemplateProps {
  compra: CompraProveedor;
  proveedor?: Proveedor;
  productosLookup: Record<string, Producto>;
}

export function CompraPDFTemplate({ compra, proveedor, productosLookup }: CompraPDFTemplateProps) {
  return (
    <div className="bg-white text-black p-8 max-w-4xl mx-auto min-h-[1056px] relative" style={{ width: '210mm', minHeight: '297mm' }}>
      {/* Header */}
      <div className="flex justify-between items-start mb-8 border-b-2 border-slate-200 pb-6">
        <div>
          <h1 className="text-4xl font-bold text-slate-800 tracking-tight">ORDEN DE COMPRA</h1>
          <p className="text-slate-500 mt-2 font-medium">Folio: {compra.folio}</p>
          <p className="text-slate-500 text-sm">Fecha: {formatearFecha(compra.fecha)}</p>
        </div>
        <div className="text-right">
          <h2 className="text-xl font-bold text-slate-800">Tu Empresa de Remolques</h2>
          <p className="text-slate-600 text-sm mt-1">Av. Industrial 123</p>
          <p className="text-slate-600 text-sm">Monterrey, N.L., México</p>
        </div>
      </div>

      {/* Proveedor Info */}
      <div className="mb-8 bg-slate-50 p-6 rounded-lg border border-slate-100">
        <h3 className="text-sm font-bold text-slate-400 uppercase tracking-wider mb-2">Datos del Proveedor</h3>
        <p className="text-lg font-bold text-slate-800">{proveedor ? proveedor.nombre : 'Proveedor no asignado'}</p>
        {proveedor && (
          <div className="mt-2 grid grid-cols-2 gap-2 text-sm text-slate-600">
            {proveedor.rfc && <p><span className="font-semibold">RFC:</span> {proveedor.rfc}</p>}
            {proveedor.telefono && <p><span className="font-semibold">Tel:</span> {proveedor.telefono}</p>}
            {proveedor.correo && <p><span className="font-semibold">Email:</span> {proveedor.correo}</p>}
            {proveedor.dias_credito > 0 && <p><span className="font-semibold">Términos:</span> {proveedor.dias_credito} días de crédito</p>}
          </div>
        )}
      </div>

      {/* Items */}
      <div className="mb-8">
        <table className="w-full text-left border-collapse">
          <thead>
            <tr className="border-b-2 border-slate-800 text-slate-800">
              <th className="py-3 px-2 font-bold w-16 text-center">Cant.</th>
              <th className="py-3 px-2 font-bold">Descripción / Material</th>
              <th className="py-3 px-2 font-bold text-right w-32">Precio Unit.</th>
              <th className="py-3 px-2 font-bold text-right w-32">Importe</th>
            </tr>
          </thead>
          <tbody>
            {compra.items?.map((item, i) => {
              const material = productosLookup[item.material_id];
              const importe = item.cantidad * item.costo_unitario;
              return (
                <tr key={i} className="border-b border-slate-200">
                  <td className="py-4 px-2 text-center font-medium">{item.cantidad}</td>
                  <td className="py-4 px-2">
                    <p className="font-bold text-slate-800">{material?.nombre || 'Material Desconocido'}</p>
                  </td>
                  <td className="py-4 px-2 text-right">{formatearMoneda(item.costo_unitario)}</td>
                  <td className="py-4 px-2 text-right font-medium">{formatearMoneda(importe)}</td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>

      {/* Totals */}
      <div className="flex justify-end mb-12">
        <div className="w-64">
          <div className="flex justify-between py-2 font-bold text-lg border-t-2 border-slate-800">
            <span className="text-slate-800">Total:</span>
            <span className="text-slate-800">{formatearMoneda(compra.total)}</span>
          </div>
        </div>
      </div>

      {/* Footer / Condiciones */}
      <div className="absolute bottom-12 left-8 right-8 text-sm text-slate-500 border-t border-slate-200 pt-4">
        <p className="font-bold text-slate-700 mb-1">Condiciones e Instrucciones</p>
        <p>1. Favor de incluir el número de folio de esta orden en su factura.</p>
        <p>2. El material debe entregarse en las instalaciones indicadas arriba en horario hábil.</p>
      </div>
    </div>
  );
}
