import React from 'react';
import { createPortal } from 'react-dom';
import { Printer, X } from 'lucide-react';
import { Button } from '../ui/button';
import { decidirLogoEncabezado } from '../../utils/logo';
import {
  PlantillaCalidad,
  ResultadoInspeccionCalidad,
  agruparResultadosPorClave,
  claveResultado,
  etiquetaResultado,
  normalizarConfigPlantilla,
} from './calidadUtils';

interface CalidadImpresionProps {
  plantilla: PlantillaCalidad;
  inspeccion?: {
    folio?: string;
    evaluado_por?: string | null;
    fecha_inicio?: string | null;
    fecha_liberacion?: string | null;
    liberado_por?: string | null;
    nota?: string | null;
  } | null;
  orden?: {
    etiqueta?: string | null;
    cliente_nombre?: string | null;
    modelo?: string | null;
    niv?: string | null;
  } | null;
  resultados?: ResultadoInspeccionCalidad[];
  ajustes?: any;
  enBlanco?: boolean;
  onCerrar: () => void;
}

export function CalidadImpresion({
  plantilla,
  inspeccion,
  orden,
  resultados = [],
  ajustes,
  enBlanco = false,
  onCerrar,
}: CalidadImpresionProps) {
  const config = normalizarConfigPlantilla(plantilla.config);
  const etq = config.etiquetas_resultado;
  const mapaResultados = enBlanco ? new Map() : agruparResultadosPorClave(resultados);
  const grupos = [...(plantilla.grupos || [])].sort((a, b) => a.orden - b.orden);
  const decisionLogo = decidirLogoEncabezado(ajustes);

  const esControlTotal = plantilla.formato === 'control_total';
  const titulo = esControlTotal
    ? 'CONTROL DE CALIDAD TOTAL'
    : 'INSPECCIÓN CONTROL DE CALIDAD DE UNIDAD EN PRODUCTO TERMINADO';

  const nombreEmpresa = ajustes?.nombre_empresa || 'ARMADORA LEOLCA';
  const direccionEmpresa = ajustes?.direccion || 'Carretera Federal Puebla - Tehuacán Km 22, Puebla';
  const telefonoEmpresa = ajustes?.telefono || '';
  const emailEmpresa = ajustes?.email || 'leolcaarmadora100@gmail.com';

  const clienteTexto = enBlanco ? '' : (orden?.cliente_nombre || orden?.etiqueta || '');
  const equipoTexto = enBlanco ? '' : (orden?.modelo || orden?.etiqueta || '');
  const folioTexto = enBlanco ? '' : (inspeccion?.folio || '');
  const nivTexto = enBlanco ? '' : (orden?.niv || '');

  return createPortal(
    <div className="fixed inset-0 z-[100] bg-black/80 overflow-y-auto p-4 sm:p-6">
      <style>{`
        @media print {
          @page { size: letter; margin: 10mm; }
          body * { visibility: hidden !important; }
          #calidad-print-sheet, #calidad-print-sheet * { visibility: visible !important; }
          #calidad-print-sheet {
            position: absolute !important;
            left: 0 !important;
            top: 0 !important;
            width: 100% !important;
            margin: 0 !important;
            padding: 0 !important;
            box-shadow: none !important;
          }
          #calidad-print-sheet thead { display: table-header-group; }
          #calidad-print-sheet tr { break-inside: avoid; page-break-inside: avoid; }
          #calidad-print-sheet .calidad-grupo-row { break-after: avoid; page-break-after: avoid; }
        }
      `}</style>

      {/* Barra de controles (no se imprime) */}
      <div className="print:hidden max-w-[900px] mx-auto mb-3 flex items-center justify-between gap-2 bg-card border border-border rounded-lg p-3">
        <div className="text-sm font-medium text-foreground">
          Vista de impresión ({enBlanco ? 'Formato en blanco' : 'Con datos capturados'})
        </div>
        <div className="flex items-center gap-2">
          <Button onClick={() => window.print()} size="sm">
            <Printer className="h-4 w-4 mr-2" />
            Imprimir / Guardar PDF
          </Button>
          <Button variant="outline" size="sm" onClick={onCerrar}>
            <X className="h-4 w-4 mr-1" />
            Cerrar
          </Button>
        </div>
      </div>

      {/* Hoja Carta */}
      <div
        id="calidad-print-sheet"
        className="max-w-[900px] mx-auto bg-white text-black p-6 shadow-lg font-sans text-[11px] leading-tight"
      >
        {/* Encabezado corporativo */}
        <div className="flex items-start justify-between border-b-2 border-black pb-2 mb-3 gap-4">
          <div className="space-y-0.5">
            <div className="font-extrabold text-sm uppercase tracking-wide">{nombreEmpresa}</div>
            <div className="text-[10px] text-slate-700">{direccionEmpresa}</div>
            {(telefonoEmpresa || emailEmpresa) && (
              <div className="text-[10px] text-slate-700">
                {[telefonoEmpresa, emailEmpresa].filter(Boolean).join(' · ')}
              </div>
            )}
          </div>
          <div className="text-right flex flex-col items-end">
            {decisionLogo.url ? (
              decisionLogo.usarContenedorNegro ? (
                <div className="bg-black text-white px-2.5 py-1 rounded inline-flex items-center justify-center mb-1">
                  <img src={decisionLogo.url} alt="Logo" className="max-h-10 max-w-[140px] object-contain" />
                </div>
              ) : (
                <img src={decisionLogo.url} alt="Logo" className="max-h-10 max-w-[140px] object-contain mb-1" />
              )
            ) : null}
            <div className="font-bold text-[10px] uppercase">{titulo}</div>
          </div>
        </div>

        {/* Metadatos del formato */}
        {esControlTotal ? (
          <table className="w-full border-collapse border border-black mb-3 text-[10px]">
            <tbody>
              <tr className="border-b border-black">
                <td className="w-[15%] bg-slate-200 font-bold p-1 border-r border-black">FOLIO</td>
                <td className="w-[35%] p-1 border-r border-black font-mono">{folioTexto || '\u00A0'}</td>
                <td className="w-[18%] bg-slate-200 font-bold p-1 border-r border-black">REVISIÓN</td>
                <td className="w-[32%] p-1">{plantilla.revision_formato || '\u00A0'}</td>
              </tr>
              <tr className="border-b border-black">
                <td className="bg-slate-200 font-bold p-1 border-r border-black">CLIENTE</td>
                <td className="p-1 border-r border-black">{clienteTexto || '\u00A0'}</td>
                <td className="bg-slate-200 font-bold p-1 border-r border-black">FECHA DE REVISIÓN</td>
                <td className="p-1">{plantilla.fecha_revision_formato || '\u00A0'}</td>
              </tr>
              <tr className="border-b border-black">
                <td className="bg-slate-200 font-bold p-1 border-r border-black">EQUIPO EVALUADO</td>
                <td className="p-1 border-r border-black">{equipoTexto || '\u00A0'}</td>
                <td className="bg-slate-200 font-bold p-1 border-r border-black">EVALUADO POR</td>
                <td className="p-1">{enBlanco ? '\u00A0' : (inspeccion?.evaluado_por || '\u00A0')}</td>
              </tr>
              <tr>
                <td className="bg-slate-200 font-bold p-1 border-r border-black">FECHA DE INICIO</td>
                <td className="p-1 border-r border-black">{enBlanco ? '\u00A0' : (inspeccion?.fecha_inicio || '\u00A0')}</td>
                <td className="bg-slate-200 font-bold p-1 border-r border-black">FECHA DE LIBERACIÓN</td>
                <td className="p-1">{enBlanco ? '\u00A0' : (inspeccion?.fecha_liberacion || '\u00A0')}</td>
              </tr>
            </tbody>
          </table>
        ) : (
          <>
            <table className="w-full border-collapse border border-black mb-2 text-[10px]">
              <tbody>
                <tr className="border-b border-black">
                  <td className="w-[15%] bg-slate-200 font-bold p-1 border-r border-black">FOLIO</td>
                  <td className="w-[35%] p-1 border-r border-black font-mono">{folioTexto || '\u00A0'}</td>
                  <td className="w-[15%] bg-slate-200 font-bold p-1 border-r border-black">FECHA</td>
                  <td className="w-[35%] p-1">{enBlanco ? '\u00A0' : (inspeccion?.fecha_inicio || '\u00A0')}</td>
                </tr>
                <tr className="border-b border-black">
                  <td className="bg-slate-200 font-bold p-1 border-r border-black">CLIENTE</td>
                  <td className="p-1 border-r border-black">{clienteTexto || '\u00A0'}</td>
                  <td className="bg-slate-200 font-bold p-1 border-r border-black">NIP / NIV</td>
                  <td className="p-1 font-mono">{nivTexto || '\u00A0'}</td>
                </tr>
                <tr>
                  <td className="bg-slate-200 font-bold p-1 border-r border-black">EQUIPO</td>
                  <td className="p-1 border-r border-black">{equipoTexto || '\u00A0'}</td>
                  <td className="bg-slate-200 font-bold p-1 border-r border-black">REVISIÓN</td>
                  <td className="p-1">
                    {[plantilla.revision_formato, plantilla.fecha_revision_formato].filter(Boolean).join(' · ') || '\u00A0'}
                  </td>
                </tr>
              </tbody>
            </table>
            <div className="text-[10px] font-bold border border-black bg-slate-100 px-2 py-1 mb-2 flex items-center gap-6">
              <span>PRODUCTO CONFORME ({etq.conforme})</span>
              <span>NO CONFORME ({etq.no_conforme})</span>
              <span>NO APLICA (N/A)</span>
            </div>
          </>
        )}

        {/* Tabla principal */}
        {esControlTotal ? (
          <table className="w-full border-collapse border border-black text-[9.5px]">
            <thead>
              <tr className="bg-slate-200 border-b border-black text-center font-bold">
                <th className="p-1 border-r border-black w-[7%]">NÚMERO DE ACTIVIDAD</th>
                <th className="p-1 border-r border-black text-left w-[35%]">ACTIVIDAD</th>
                <th className="p-1 border-r border-black w-[15%]">COLABORADOR RESPONSABLE</th>
                <th className="p-1 border-r border-black w-[11%]">FECHA DE INSPECCIÓN</th>
                <th className="p-1 border-r border-black w-[7%]">CONFORMIDAD ({etq.conforme})</th>
                <th className="p-1 border-r border-black w-[7%]">NO CONFORMIDAD ({etq.no_conforme})</th>
                <th className="p-1 text-left w-[18%]">OBSERVACIONES</th>
              </tr>
            </thead>
            <tbody>
              {grupos.map((g, gi) => (
                <React.Fragment key={g.id || gi}>
                  <tr className="calidad-grupo-row bg-slate-100 border-b border-black font-bold">
                    <td colSpan={7} className="p-1 uppercase">
                      PROCESO {g.numero_original || g.orden} ({g.nombre})
                    </td>
                  </tr>
                  {[...(g.items || [])]
                    .sort((a, b) => a.orden - b.orden)
                    .map((it, ii) => {
                      const res = it.id ? mapaResultados.get(claveResultado(it.id, 1)) : null;
                      const esConf = !enBlanco && res?.resultado === 'conforme';
                      const esNoConf = !enBlanco && res?.resultado === 'no_conforme';
                      const esNa = !enBlanco && res?.resultado === 'no_aplica';
                      return (
                        <tr key={it.id || ii} className="border-b border-black">
                          <td className="p-1 border-r border-black text-center font-mono">{it.numero}</td>
                          <td className="p-1 border-r border-black">
                            {it.texto}
                            {it.aplica_si ? <span className="text-slate-600"> ({it.aplica_si})</span> : null}
                          </td>
                          <td className="p-1 border-r border-black text-center">
                            {enBlanco ? '\u00A0' : (res?.colaborador || '\u00A0')}
                          </td>
                          <td className="p-1 border-r border-black text-center">
                            {enBlanco ? '\u00A0' : (res?.fecha_inspeccion || '\u00A0')}
                          </td>
                          <td className="p-1 border-r border-black text-center font-bold">
                            {esConf ? etq.conforme : esNa ? 'N/A' : '\u00A0'}
                          </td>
                          <td className="p-1 border-r border-black text-center font-bold">
                            {esNoConf ? etq.no_conforme : '\u00A0'}
                          </td>
                          <td className="p-1">
                            {enBlanco ? '\u00A0' : (res?.observaciones || '\u00A0')}
                          </td>
                        </tr>
                      );
                    })}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        ) : (
          <table className="w-full border-collapse border border-black text-[9.5px]">
            <thead>
              <tr className="bg-slate-200 border-b border-black text-center font-bold">
                <th className="p-1 border-r border-black w-[6%]">No.</th>
                <th className="p-1 border-r border-black text-left w-[44%]">INSPECCIÓN</th>
                {config.unidades.map((uNombre, ui) => (
                  <th key={ui} className="p-1 border-r border-black w-[12%]">
                    {config.unidades.length === 1 && uNombre === 'Única'
                      ? `${etq.conforme} / ${etq.no_conforme}`
                      : uNombre.toUpperCase()}
                  </th>
                ))}
                <th className="p-1 text-left">OBSERVACIONES</th>
              </tr>
            </thead>
            <tbody>
              {grupos.map((g, gi) => (
                <React.Fragment key={g.id || gi}>
                  <tr className="calidad-grupo-row bg-slate-100 border-b border-black font-bold">
                    <td colSpan={3 + config.unidades.length} className="p-1 uppercase">
                      {g.nombre}
                    </td>
                  </tr>
                  {[...(g.items || [])]
                    .sort((a, b) => a.orden - b.orden)
                    .map((it, ii) => {
                      const obsList: string[] = [];
                      return (
                        <tr key={it.id || ii} className="border-b border-black">
                          <td className="p-1 border-r border-black text-center font-mono">{it.numero}</td>
                          <td className="p-1 border-r border-black">
                            {it.texto}
                            {it.aplica_si ? <span className="text-slate-600"> ({it.aplica_si})</span> : null}
                          </td>
                          {config.unidades.map((_, ui) => {
                            const res = it.id ? mapaResultados.get(claveResultado(it.id, ui + 1)) : null;
                            if (!enBlanco && res?.observaciones) obsList.push(res.observaciones);
                            const marca = enBlanco ? '\u00A0' : etiquetaResultado(res?.resultado, config);
                            return (
                              <td key={ui} className="p-1 border-r border-black text-center font-bold">
                                {marca || '\u00A0'}
                              </td>
                            );
                          })}
                          <td className="p-1">{enBlanco ? '\u00A0' : (obsList.join(' | ') || '\u00A0')}</td>
                        </tr>
                      );
                    })}
                </React.Fragment>
              ))}
            </tbody>
          </table>
        )}

        {/* Pie con liberado por y línea de firma */}
        <div className="mt-6 pt-4 grid grid-cols-2 gap-8 text-[10px]">
          <div>
            <div className="font-bold uppercase mb-6">
              LIBERADO POR: <span className="font-normal">{enBlanco ? '' : (inspeccion?.liberado_por || '')}</span>
            </div>
            <div className="border-t border-black pt-1 text-center font-semibold">
              NOMBRE Y FIRMA DE QUIEN LIBERA
            </div>
          </div>
          <div>
            <div className="font-bold uppercase mb-6">
              FECHA DE LIBERACIÓN: <span className="font-normal">{enBlanco ? '' : (inspeccion?.fecha_liberacion || '')}</span>
            </div>
            <div className="border-t border-black pt-1 text-center font-semibold">
              FIRMA DE INSPECCIÓN / CALIDAD
            </div>
          </div>
        </div>
      </div>
    </div>,
    document.body
  );
}
