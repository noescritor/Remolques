import React from 'react';
import { OrdenTrabajo } from '../../types';

interface OrdenTrabajoPDFProps {
  orden: OrdenTrabajo;
}

export function OrdenTrabajoPDF({ orden }: OrdenTrabajoPDFProps) {
  const caracteristicas = orden.caracteristicas || {};
  
  return (
    <div className="bg-white text-black p-8 max-w-4xl mx-auto text-sm print:p-0 print:max-w-none font-sans">
      <div className="flex justify-between items-start border-b-2 border-black pb-4 mb-4">
        <div>
          <h1 className="text-xl font-bold">ORDEN DE TRABAJO PARA REMOLQUE</h1>
          <p className="text-xs mt-2 font-bold">Armadora LEOLCA S.A de C.V.</p>
          <p className="text-xs">Camino a San Antonio Buenavista</p>
          <p className="text-xs">Localidad San Miguel Ayotla</p>
          <p className="text-xs">Ahuazotepec, Puebla, 73180</p>
        </div>
        <div className="text-right">
          <h2 className="text-2xl font-black">{orden.nomenclatura_id}</h2>
          <p className="text-xs mt-2 text-gray-500">GRUPO INDUSTRIAL LEOLCA</p>
        </div>
      </div>

      <div className="grid grid-cols-2 gap-4 mb-6 border border-black p-2">
        <div>
          <p><strong>NOMBRE DE CLIENTE:</strong> {orden.cliente?.nombre}</p>
          <p><strong>TELÉFONO:</strong> {orden.cliente?.telefono || 'N/A'}</p>
          <p><strong>FECHA DEL PEDIDO:</strong> {new Date(orden.created_at).toLocaleDateString()}</p>
        </div>
        <div>
          <p><strong>ID EQUIPO/UNIDAD:</strong> {orden.nomenclatura_id}</p>
          <p><strong>NIV:</strong> {orden.niv || 'PENDIENTE'}</p>
          <p><strong>MODELO:</strong> {orden.modelo || 'N/A'}</p>
        </div>
      </div>

      <div className="border border-black mb-6">
        <div className="bg-gray-200 text-center font-bold border-b border-black py-1">
          DESCRIPCIÓN DEL TRABAJO
        </div>
        <div className="p-2 border-b border-black font-bold">
          CANTIDAD: 1 - {caracteristicas.descripcion_corta || 'Remolque'}
        </div>
        
        <div className="bg-gray-100 text-center font-bold border-b border-black py-1">
          CARACTERÍSTICAS
        </div>
        
        <table className="w-full text-left border-collapse">
          <tbody>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">EJES</td>
              <td className="p-1">{caracteristicas.ejes || 'Por definir'}</td>
            </tr>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">SUSPENSIÓN</td>
              <td className="p-1">{caracteristicas.suspension || 'Por definir'}</td>
            </tr>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">PATINES</td>
              <td className="p-1">{caracteristicas.patines || 'Por definir'}</td>
            </tr>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">COLOR</td>
              <td className="p-1">{caracteristicas.color || 'Por definir'}</td>
            </tr>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">PISO</td>
              <td className="p-1">{caracteristicas.piso || 'N/A'}</td>
            </tr>
            <tr className="border-b border-gray-300">
              <td className="w-1/3 p-1 font-bold border-r border-gray-300">LLANTAS Y RINES</td>
              <td className="p-1">{caracteristicas.llantas || 'N/A'} / {caracteristicas.rines || 'N/A'}</td>
            </tr>
          </tbody>
        </table>

        <div className="bg-gray-100 text-center font-bold border-y border-black py-1 mt-4">
          OBSERVACIONES Y EXTRAS
        </div>
        <div className="p-4 min-h-[100px]">
          {caracteristicas.observaciones || 'Sin observaciones adicionales.'}
        </div>
      </div>

      <div className="grid grid-cols-2 gap-8 mt-16 text-center">
        <div>
          <div className="border-b border-black mb-2 mx-8"></div>
          <p className="font-bold">TRABAJO AUTORIZADO POR</p>
        </div>
        <div>
          <div className="border-b border-black mb-2 mx-8"></div>
          <p className="font-bold">APROBACIÓN DEL CLIENTE</p>
        </div>
      </div>
    </div>
  );
}
