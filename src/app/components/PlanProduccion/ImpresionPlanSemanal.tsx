import React from 'react';
import { PlanTarea, diasDeSemana, etiquetaDia, rangoSemanaTexto, totalesPersonal } from '../../utils/planProduccion';

interface ImpresionPlanSemanalProps {
  areaNombre: string;
  esReparaciones: boolean;
  lunes: string;
  mostrarSabado: boolean;
  frentes: Array<{ id: string; nombre: string }>;
  tareas: PlanTarea[];
}

export function ImpresionPlanSemanal({
  areaNombre,
  esReparaciones,
  lunes,
  mostrarSabado,
  frentes,
  tareas,
}: ImpresionPlanSemanalProps) {
  const dias = diasDeSemana(lunes, { sabado: mostrarSabado });
  const rangoTexto = rangoSemanaTexto(lunes, { sabado: mostrarSabado });
  const totales = totalesPersonal(tareas);

  // Mapa dia -> frenteId -> tareas[]
  const mapa: Record<string, Record<string, PlanTarea[]>> = {};
  for (const t of tareas) {
    if (t.estado === 'cancelada') continue;
    const dia = t.fecha ? t.fecha.split('T')[0] : '';
    if (!dia) continue;
    if (!mapa[dia]) mapa[dia] = {};
    if (!mapa[dia][t.frente_id]) mapa[dia][t.frente_id] = [];
    mapa[dia][t.frente_id].push(t);
  }

  return (
    <div className="impresion-plan-contenedor hidden print:block text-black bg-white p-4 font-sans text-[11px] leading-tight">
      <style>{`
        @media print {
          @page {
            size: landscape;
            margin: 8mm;
          }
          body {
            background: white !important;
            color: black !important;
          }
          .impresion-plan-contenedor {
            display: block !important;
          }
          .no-print {
            display: none !important;
          }
        }
      `}</style>

      {/* Encabezado exacto del Excel */}
      <div className="border border-black p-2 mb-2 bg-gray-100 flex justify-between items-center font-bold">
        <div className="text-base tracking-wide uppercase">
          PLAN DE TRABAJO {areaNombre}
        </div>
        <div className="text-sm tracking-wide">
          FECHA: {rangoTexto}
        </div>
      </div>

      {/* Tabla Cuadrícula */}
      <table className="w-full border-collapse border border-black table-fixed text-[10px]">
        <thead>
          <tr className="bg-gray-200">
            <th className="border border-black p-1 text-center font-bold w-[12%]">DÍA</th>
            {frentes.map((f) => (
              <th key={f.id} className="border border-black p-1 text-center font-bold uppercase truncate" title={f.nombre}>
                {f.nombre}
              </th>
            ))}
            <th className="border border-black p-1 text-center font-bold w-[7%]">TOT</th>
          </tr>
        </thead>
        <tbody>
          {dias.map((dia) => {
            const totDia = totales.porDia[dia] || 0;
            return (
              <tr key={dia} className="align-top">
                {/* Columna Día */}
                <td className="border border-black p-1 font-bold text-center bg-gray-50">
                  {etiquetaDia(dia)}
                </td>

                {/* Columnas de cada Frente */}
                {frentes.map((f) => {
                  const tareasCelda = (mapa[dia] && mapa[dia][f.id]) || [];
                  return (
                    <td key={f.id} className="border border-black p-1">
                      {tareasCelda.length === 0 ? (
                        <div className="text-gray-300 text-center italic py-2">-</div>
                      ) : (
                        <div className="space-y-1.5">
                          {tareasCelda.map((t, idx) => {
                            const opsTexto = (t.operarios || [])
                              .map((o: any) => (typeof o === 'string' ? o : o.nombre))
                              .filter(Boolean)
                              .join(', ');

                            const matsTexto = (t.materiales || [])
                              .map((m) => `${m.cantidad} ${m.unidad} ${m.descripcion}`)
                              .join('; ');

                            return (
                              <div
                                key={t.id || idx}
                                className={idx > 0 ? 'pt-1.5 border-t border-dashed border-gray-400' : ''}
                              >
                                {esReparaciones && t.descripcion && (
                                  <div>
                                    <span className="font-bold">DESCRIPCIÓN: </span>
                                    <span>{t.descripcion}</span>
                                  </div>
                                )}
                                <div>
                                  <span className="font-bold">OPERARIO: </span>
                                  <span>{opsTexto || 'Sin asignar'}</span>
                                </div>
                                {t.movilidad && (
                                  <div>
                                    <span className="font-bold">MOVILIDAD: </span>
                                    <span>{t.movilidad}</span>
                                  </div>
                                )}
                                {matsTexto && (
                                  <div>
                                    <span className="font-bold">MATERIALES: </span>
                                    <span>{matsTexto}</span>
                                  </div>
                                )}
                                {t.observaciones && (
                                  <div>
                                    <span className="font-bold">OBS: </span>
                                    <span>{t.observaciones}</span>
                                  </div>
                                )}
                                {t.orden_trabajo && (
                                  <div className="text-[9px] text-gray-700 italic">
                                    OT: {t.orden_trabajo.nomenclatura_id || t.orden_trabajo.modelo || 'Remolque'}
                                  </div>
                                )}
                              </div>
                            );
                          })}
                        </div>
                      )}
                    </td>
                  );
                })}

                {/* Columna TOT */}
                <td className="border border-black p-1 font-bold text-center bg-gray-100 text-sm align-middle">
                  {totDia}
                </td>
              </tr>
            );
          })}
        </tbody>
        <tfoot>
          <tr className="bg-gray-200 font-bold">
            <td className="border border-black p-1 text-center uppercase">
              TOTAL DE PERSONAL
            </td>
            {frentes.map((f) => {
              const totFrente = totales.porFrente[f.id] || 0;
              return (
                <td key={f.id} className="border border-black p-1 text-center">
                  {totFrente}
                </td>
              );
            })}
            <td className="border border-black p-1 text-center bg-gray-300">
              {totales.totalAsignaciones}
            </td>
          </tr>
        </tfoot>
      </table>
    </div>
  );
}
