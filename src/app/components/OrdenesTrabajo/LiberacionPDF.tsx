import React from 'react';
import { OrdenTrabajo } from '../../types';

interface LiberacionPDFProps {
  ordenes: OrdenTrabajo[];
}

export function LiberacionPDF({ ordenes }: LiberacionPDFProps) {
  if (ordenes.length === 0) return null;
  const cliente = ordenes[0].cliente;
  const today = new Date().toLocaleDateString('es-MX', { year: 'numeric', month: 'long', day: 'numeric' });

  return (
    <div className="bg-white text-black p-10 max-w-4xl mx-auto text-sm print:p-0 print:max-w-none font-sans">
      <div className="flex justify-between items-start border-b-4 border-blue-900 pb-4 mb-8">
        <div>
          <h1 className="text-2xl font-black tracking-widest">LEOLCA</h1>
          <p className="text-xs font-bold mt-1">GRUPO INDUSTRIAL</p>
        </div>
        <div className="text-right text-xs">
          <p className="font-bold">REMOLQUES "LEOLCA"</p>
          <p>FABRICACIÓN DE REMOLQUES</p>
          <p>San Miguel Ayotla, Ahuazotepec, Puebla</p>
          <p>armadora_leolca@gmail.com</p>
        </div>
      </div>

      <div className="text-right mb-12">
        <p>San Miguel Ayotla, Ahuazotepec, Puebla a {today}</p>
      </div>

      <div className="mb-8 text-justify leading-relaxed">
        El C. <strong>{cliente?.nombre}</strong> recibe de <strong>ARMADORA LEOLCA S.A. DE C.V.</strong> las siguientes unidades:
      </div>

      <div className="space-y-8">
        {ordenes.map((orden, idx) => {
          const caracteristicas = orden.caracteristicas || {};
          return (
            <table key={orden.id} className="w-full text-left border-collapse border border-black">
              <tbody>
                <tr className="border-b border-black">
                  <td className="w-1/3 p-2 font-bold border-r border-black bg-gray-100">SEMI-REMOLQUE TIPO:</td>
                  <td className="p-2 uppercase">{caracteristicas.descripcion_corta || 'REMOLQUE'}</td>
                </tr>
                <tr className="border-b border-black">
                  <td className="w-1/3 p-2 font-bold border-r border-black bg-gray-100">NÚMERO DE IDENTIFICACIÓN VEHICULAR:</td>
                  <td className="p-2 font-mono uppercase">{orden.niv || 'PENDIENTE'}</td>
                </tr>
                <tr className="border-b border-black">
                  <td className="w-1/3 p-2 font-bold border-r border-black bg-gray-100">MODELO:</td>
                  <td className="p-2">{orden.modelo || 'N/A'}</td>
                </tr>
                <tr className="border-b border-black">
                  <td className="w-1/3 p-2 font-bold border-r border-black bg-gray-100">COLOR:</td>
                  <td className="p-2 uppercase">{caracteristicas.color || 'N/A'}</td>
                </tr>
                <tr>
                  <td className="w-1/3 p-2 font-bold border-r border-black bg-gray-100">EJES:</td>
                  <td className="p-2">{caracteristicas.ejes || 'N/A'}</td>
                </tr>
              </tbody>
            </table>
          )
        })}
      </div>

      <div className="mt-32 grid grid-cols-2 gap-16 text-center">
        <div>
          <div className="border-b border-black mb-2 mx-4"></div>
          <p className="font-bold">NOMBRE Y FIRMA DE QUIEN RECIBE</p>
        </div>
        <div>
          <div className="border-b border-black mb-2 mx-4"></div>
          <p className="font-bold">ARMADORA LEOLCA S.A DE C.V</p>
        </div>
      </div>
    </div>
  );
}
