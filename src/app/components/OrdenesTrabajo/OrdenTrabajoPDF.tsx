import React, { useState } from 'react';
import { OrdenTrabajo } from '../../types';
import { decidirLogoEncabezado } from '../../utils/logo';
import { Button } from '../ui/button';
import { RefreshCw, AlertCircle } from 'lucide-react';
import { toast } from 'sonner';

interface OrdenTrabajoPDFProps {
  orden: OrdenTrabajo;
  ajustes?: any;
  onRegenerarFicha?: (id: string) => Promise<void>;
}

export function OrdenTrabajoPDF({ orden, ajustes, onRegenerarFicha }: OrdenTrabajoPDFProps) {
  const [regenerando, setRegenerando] = useState(false);
  const ficha = orden.caracteristicas?.ficha;

  const handleRegenerar = async () => {
    if (!onRegenerarFicha) return;
    setRegenerando(true);
    try {
      await onRegenerarFicha(orden.id);
      toast.success('Ficha técnica regenerada con éxito');
    } catch (e: any) {
      toast.error('Error al regenerar ficha: ' + (e.message || 'Error desconocido'));
    } finally {
      setRegenerando(false);
    }
  };

  if (!ficha) {
    return (
      <div className="bg-white text-black p-8 rounded-lg shadow border border-slate-300 font-sans max-w-4xl mx-auto my-4">
        <div className="flex items-start gap-4 p-4 bg-amber-50 border border-amber-200 rounded-lg mb-6">
          <AlertCircle className="w-6 h-6 text-amber-600 shrink-0 mt-0.5" />
          <div className="flex-1">
            <h3 className="font-bold text-amber-900 text-sm">Esta orden se generó antes del formato nuevo</h3>
            <p className="text-xs text-amber-700 mt-1">
              Para visualizar la Orden de Trabajo en el formato oficial de una página, es necesario reconstruir la ficha técnica a partir de los datos actuales de la cotización.
            </p>
            {onRegenerarFicha && (
              <Button
                onClick={handleRegenerar}
                disabled={regenerando}
                size="sm"
                className="mt-3 bg-amber-600 hover:bg-amber-700 text-white"
              >
                <RefreshCw className={`w-3.5 h-3.5 mr-2 ${regenerando ? 'animate-spin' : ''}`} />
                {regenerando ? 'Regenerando ficha...' : 'Regenerar ficha'}
              </Button>
            )}
          </div>
        </div>

        {/* Resumen básico de compatibilidad para órdenes legacy */}
        <div className="text-xs space-y-2 text-slate-600">
          <p><strong>Nomenclatura:</strong> {orden.nomenclatura_id}</p>
          <p><strong>NIV:</strong> {orden.niv || 'Pendiente'}</p>
          <p><strong>Modelo:</strong> {orden.modelo || 'Sin modelo'}</p>
          <p><strong>Descripción:</strong> {orden.caracteristicas?.descripcion_corta || 'Remolque'}</p>
        </div>
      </div>
    );
  }

  const { cabecera, cantidad_texto, caracteristicas, accesorios_extra, nota } = ficha;
  const decisionLogo = decidirLogoEncabezado(ajustes, 'claro');

  return (
    <div className="bg-white text-black p-6 sm:p-8 max-w-[800px] mx-auto text-[11px] leading-tight print:p-0 print:max-w-none print:text-[10px] font-sans selection:bg-none print:m-0">
      <style>{`
        @page {
          size: A4 portrait;
          margin: 8mm 10mm;
        }
        @media print {
          body {
            -webkit-print-color-adjust: exact !important;
            print-color-adjust: exact !important;
          }
          .no-print {
            display: none !important;
          }
        }
      `}</style>

      {/* ENCABEZADO */}
      <div className="border-b-2 border-black pb-2 mb-3">
        <h1 className="text-center font-extrabold text-base sm:text-lg tracking-wide uppercase mb-3">
          ORDEN DE TRABAJO PARA REMOLQUE
        </h1>

        <div className="flex justify-between items-start gap-4">
          {/* Bloque Empresa */}
          <div className="text-[10px] sm:text-[11px] space-y-0.5 max-w-[60%]">
            <p className="font-bold uppercase tracking-wider text-black">
              {ajustes?.nombre_empresa || 'Armadora LEOLCA S.A de C.V.'}
            </p>
            <p className="text-slate-700">
              {ajustes?.direccion || 'Camino a San Antonio Buenavista, Localidad San Miguel Ayotla'}
            </p>
            <p className="text-slate-700">
              {ajustes?.ciudad ? `${ajustes.ciudad}, ` : ''}
              {ajustes?.estado ? `${ajustes.estado}, ` : 'Ahuazotepec, Puebla, '}
              {ajustes?.codigo_postal || '73180'}
            </p>
            <p className="text-slate-700">
              Tel: {ajustes?.telefono || '55-36-52-62-80'}
            </p>
            <p className="text-slate-700">
              {ajustes?.email || 'leolcaarmadora100@gmail.com'}
            </p>
          </div>

          {/* Bloque Logo y Nomenclatura */}
          <div className="text-right flex flex-col items-end">
            {decisionLogo.url ? (
              decisionLogo.usarContenedorNegro ? (
                <div className="bg-black text-white px-3 py-1.5 rounded-lg inline-flex items-center justify-center mb-1">
                  <img
                    src={decisionLogo.url}
                    alt="Logo"
                    className="max-h-12 max-w-[150px] object-contain"
                  />
                </div>
              ) : (
                <img
                  src={decisionLogo.url}
                  alt="Logo"
                  className="max-h-12 max-w-[150px] object-contain mb-1"
                />
              )
            ) : (
              <div className="text-right mb-1">
                <span className="font-extrabold text-xs uppercase tracking-wider">
                  {ajustes?.nombre_empresa || 'LEOLCA'}
                </span>
              </div>
            )}
            <div className="font-mono text-[10px] font-bold text-slate-800">
              ID: {orden.nomenclatura_id}
            </div>
            {orden.niv && (
              <div className="font-mono text-[9px] text-slate-600">
                NIV: {orden.niv}
              </div>
            )}
          </div>
        </div>
      </div>

      {/* METADATOS GRID */}
      <table className="w-full border-collapse border border-black mb-3 text-[10px] sm:text-[10.5px]">
        <tbody>
          {/* Fila 1 */}
          <tr className="border-b border-black">
            <td className="w-[18%] bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              NOMBRE DE CLIENTE
            </td>
            <td className="w-[48%] p-1 font-semibold uppercase border-r border-black">
              {cabecera.cliente || '\u00A0'}
            </td>
            <td className="w-[18%] bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              NÚMERO DE PEDIDO
            </td>
            <td className="w-[16%] p-1 font-mono font-semibold">
              {cabecera.numero_pedido || '\u00A0'}
            </td>
          </tr>

          {/* Fila 2 */}
          <tr className="border-b border-black">
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              TELÉFONO DEL CLIENTE
            </td>
            <td className="p-1 border-r border-black">
              {cabecera.telefono || '\u00A0'}
            </td>
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              CORREO ELECTRÓNICO
            </td>
            <td className="p-1">
              {cabecera.correo || '\u00A0'}
            </td>
          </tr>

          {/* Fila 3 */}
          <tr className="border-b border-black">
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              NOMBRE DEL PROYECTO
            </td>
            <td className="p-1 font-semibold border-r border-black">
              {cabecera.nombre_proyecto || '\u00A0'}
            </td>
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              FECHA DEL PEDIDO
            </td>
            <td className="p-1 font-medium">
              {cabecera.fecha_pedido || '\u00A0'}
            </td>
          </tr>

          {/* Fila 4 */}
          <tr className="border-b border-black">
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              PEDIDO RECIBIDO POR
            </td>
            <td className="p-1 border-r border-black">
              {cabecera.pedido_recibido_por || '\u00A0'}
            </td>
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              FECHA INICIO PREVISTA
            </td>
            <td className="p-1">
              {cabecera.fecha_inicio_prevista || '\u00A0'}
            </td>
          </tr>

          {/* Fila 5 */}
          <tr>
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              TRABAJO AUTORIZADO POR
            </td>
            <td className="p-1 border-r border-black">
              {cabecera.trabajo_autorizado_por || '\u00A0'}
            </td>
            <td className="bg-slate-200/90 font-bold p-1 uppercase border-r border-black">
              FINALIZACIÓN PREVISTA
            </td>
            <td className="p-1">
              {cabecera.fecha_fin_prevista || '\u00A0'}
            </td>
          </tr>
        </tbody>
      </table>

      {/* BLOQUE DESCRIPCIÓN DEL TRABAJO */}
      <div className="border border-black mb-3">
        {/* Banda Principal */}
        <div className="bg-slate-800 text-white font-extrabold text-center py-1 text-[11px] uppercase tracking-wider border-b border-black">
          DESCRIPCIÓN DEL TRABAJO
        </div>

        {/* Fila Cantidad */}
        <div className="flex border-b border-black text-[11px]">
          <div className="w-[28%] bg-slate-200/90 font-bold p-1.5 uppercase border-r border-black">
            CANTIDAD
          </div>
          <div className="w-[72%] p-1.5 font-bold uppercase tracking-wide">
            {cantidad_texto}
          </div>
        </div>

        {/* Banda Características */}
        <div className="bg-slate-300 font-extrabold text-center py-0.5 text-[10.5px] uppercase tracking-wider border-b border-black">
          CARACTERÍSTICAS
        </div>

        {/* Tabla de 14 Características */}
        <table className="w-full border-collapse text-[10px] sm:text-[10.5px]">
          <tbody>
            {caracteristicas.map((car, idx) => (
              <tr
                key={car.etiqueta}
                className={idx < caracteristicas.length - 1 ? 'border-b border-slate-300' : ''}
              >
                <td className="w-[35%] p-1 font-bold uppercase border-r border-black bg-slate-50/50">
                  {car.etiqueta}
                </td>
                <td className="w-[65%] p-1 pl-2 font-medium">
                  {car.valor}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Banda Accesorios Extra */}
        <div className="bg-slate-300 font-extrabold text-center py-0.5 text-[10.5px] uppercase tracking-wider border-y border-black">
          ACCESORIOS EXTRA
        </div>

        {/* Tabla de 4 Accesorios Extra */}
        <table className="w-full border-collapse text-[10px] sm:text-[10.5px]">
          <tbody>
            {accesorios_extra.map((acc, idx) => (
              <tr
                key={acc.etiqueta}
                className={idx < accesorios_extra.length - 1 ? 'border-b border-slate-300' : ''}
              >
                <td className="w-[35%] p-1 font-bold uppercase border-r border-black bg-slate-50/50">
                  {acc.etiqueta}
                </td>
                <td className="w-[65%] p-1 pl-2 font-medium">
                  {acc.valor}
                </td>
              </tr>
            ))}
          </tbody>
        </table>

        {/* Nota */}
        <div className="border-t border-black p-2 bg-slate-50/30 min-h-[36px] flex items-start text-[10.5px]">
          <span className="font-bold mr-1 shrink-0">Nota:</span>
          <span className="font-medium text-slate-800 break-words whitespace-pre-wrap">
            {nota || 'Ninguna observación adicional.'}
          </span>
        </div>
      </div>

      {/* PIE DE FIRMAS */}
      <div className="grid grid-cols-2 gap-8 pt-4 pb-2 text-center text-[10px]">
        <div>
          <div className="border-b border-black w-48 sm:w-56 mx-auto mb-1"></div>
          <p className="font-bold uppercase tracking-wider">
            ORDEN DE TRABAJO COMPILADA POR
          </p>
          {cabecera.compilada_por && (
            <p className="text-slate-700 font-medium">{cabecera.compilada_por}</p>
          )}
        </div>
        <div>
          <div className="border-b border-black w-48 sm:w-56 mx-auto mb-1"></div>
          <p className="font-bold uppercase tracking-wider">
            APROBACIÓN DEL CLIENTE
          </p>
        </div>
      </div>
    </div>
  );
}
