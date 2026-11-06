import React, { useState, useEffect, useMemo } from 'react';
import { OrdenTrabajo } from '../../types';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from '../ui/dialog';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import {
  ClipboardCheck,
  PackageCheck,
  CheckCircle2,
  AlertCircle,
  Printer,
  RefreshCw,
  RotateCcw,
  Plus,
  Trash2,
  Edit2,
  ChevronDown,
  ChevronRight,
  ShieldAlert,
  FileSpreadsheet,
} from 'lucide-react';
import { BASE_URL } from '../../utils/api';

interface ChecklistDespieceModalProps {
  orden: OrdenTrabajo | null;
  open: boolean;
  onOpenChange: (open: boolean) => void;
}

function resolverModeloChecklist(ord: any): string {
  if (!ord) return 'Modelo';
  if (ord.caracteristicas?.ficha?.cantidad_texto) {
    return ord.caracteristicas.ficha.cantidad_texto;
  }
  if (ord.caracteristicas?.descripcion_corta && ord.caracteristicas.descripcion_corta.toUpperCase().includes('GONDOLA')) {
    const match = ord.caracteristicas.descripcion_corta.match(/GONDOLA\s+\d+\s+EJES(?:\s+\d+\s+M3)?/i);
    if (match) return match[0].toUpperCase();
  }
  const tipo = (ord.tipo_equipo || ord.modelo || '').toLowerCase();
  const esGondola = tipo.includes('gondola') || ord.caracteristicas?.grupos?.volumen !== undefined;
  if (esGondola) {
    const vol = ord.caracteristicas?.grupos?.volumen?.includes?.('30') ? '30 M3' : '45 M3';
    if (ord.modelo && !ord.modelo.includes('M3') && !ord.modelo.includes('m3')) {
      return `${ord.modelo} ${vol}`;
    }
  }
  return ord.modelo || 'Modelo';
}

export function ChecklistDespieceModal({ orden, open, onOpenChange }: ChecklistDespieceModalProps) {
  const [loading, setLoading] = useState(false);
  const [generando, setGenerando] = useState(false);
  const [datos, setDatos] = useState<any>(null);
  const [operarios, setOperarios] = useState<any[]>([]);
  const [fasesExpandidas, setFasesExpandidas] = useState<Record<string, boolean>>({});
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [equipoFiltro, setEquipoFiltro] = useState<string>('todos');

  // Modal registrar entrega / reposicion
  const [modalEntregaOpen, setModalEntregaOpen] = useState(false);
  const [lineaSeleccionada, setLineaSeleccionada] = useState<any>(null);
  const [tipoEntrega, setTipoEntrega] = useState<'entrega' | 'reposicion'>('entrega');
  const [cantEntrega, setCantEntrega] = useState<number>(1);
  const [operarioId, setOperarioId] = useState<string>('');
  const [operarioNombreManual, setOperarioNombreManual] = useState<string>('');
  const [motivoEntrega, setMotivoEntrega] = useState<string>('');
  const [procesandoAccion, setProcesandoAccion] = useState(false);

  // Modal anular
  const [modalAnularOpen, setModalAnularOpen] = useState(false);
  const [entregaAAnular, setEntregaAAnular] = useState<any>(null);
  const [motivoAnulacion, setMotivoAnulacion] = useState('');

  // Modal agregar partida manual
  const [modalAgregarOpen, setModalAgregarOpen] = useState(false);
  const [manualFaseClave, setManualFaseClave] = useState('paso_1');
  const [manualDesc, setManualDesc] = useState('');
  const [manualUnidad, setManualUnidad] = useState('pz');
  const [manualCant, setManualCant] = useState(1);

  // Modal ajustar cantidad requerida
  const [modalAjustarOpen, setModalAjustarOpen] = useState(false);
  const [lineaAAjustar, setLineaAAjustar] = useState<any>(null);
  const [nuevaCantRequerida, setNuevaCantRequerida] = useState<number>(1);
  const [motivoAjuste, setMotivoAjuste] = useState('');

  // Modal entregar fase completa
  const [modalEntregarFaseOpen, setModalEntregarFaseOpen] = useState(false);
  const [faseAEntregar, setFaseAEntregar] = useState<{ clave: string; nombre: string; pendientes: number } | null>(null);
  const [faseOperarioId, setFaseOperarioId] = useState<string>('');
  const [faseOperarioNombreManual, setFaseOperarioNombreManual] = useState<string>('');

  // Modal historial de entregas por partida
  const [modalHistorialOpen, setModalHistorialOpen] = useState(false);
  const [lineaHistorial, setLineaHistorial] = useState<any>(null);

  // Avisos de generación (cambios no aplicados, receta cruda, sin fase)
  const [cambiosPresupuesto, setCambiosPresupuesto] = useState<any[]>([]);
  const [avisoSinFase, setAvisoSinFase] = useState<number>(0);
  const [avisoRecetaCruda, setAvisoRecetaCruda] = useState<boolean>(false);

  const cargarDatosDespiece = async (filtroEquipo = equipoFiltro) => {
    if (!orden) return;
    setLoading(true);
    setErrorMsg(null);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const query = filtroEquipo !== 'todos' ? `?equipo_indice=${encodeURIComponent(filtroEquipo)}` : '';
      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece${query}`, { headers });
      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || `Error ${res.status}: ${res.statusText}`);
      }
      const data = await res.json();
      setDatos(data);

      // Cargar lista de operarios si no se ha cargado
      if (operarios.length === 0) {
        const resOps = await fetch(`${BASE_URL}/operarios`, { headers });
        if (resOps.ok) {
          const opsData = await resOps.json();
          setOperarios(opsData || []);
        }
      }
    } catch (err: any) {
      console.error('Error cargando checklist:', err);
      setErrorMsg(err.message || 'Error al cargar despiece');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    if (open && orden) {
      cargarDatosDespiece(equipoFiltro);
    }
  }, [open, orden?.id, equipoFiltro]);

  const handleGenerarDespiece = async (forzar = false) => {
    if (!orden) return;
    setGenerando(true);
    setErrorMsg(null);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/generar`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ forzar }),
      });
      const dataJson = await res.json().catch(() => ({}));
      if (!res.ok) {
        const errorDesc = dataJson.codigo === 'bom_ambiguo' && dataJson.conceptos?.length
          ? `${dataJson.error}: ${dataJson.conceptos.map((c: any) => c.descripcion).join(', ')}`
          : dataJson.error || 'Error al generar despiece';
        throw new Error(errorDesc);
      }

      if (dataJson.cambios_no_aplicados && dataJson.cambios_no_aplicados.length > 0) {
        setCambiosPresupuesto(dataJson.cambios_no_aplicados);
      } else {
        setCambiosPresupuesto([]);
      }
      if (dataJson.sin_fase) {
        setAvisoSinFase(dataJson.sin_fase);
      } else {
        setAvisoSinFase(0);
      }
      setAvisoRecetaCruda(dataJson.advertencia === 'receta_cruda');

      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      console.error('Error generando despiece:', err);
      setErrorMsg(err.message || 'No se pudo generar el despiece');
    } finally {
      setGenerando(false);
    }
  };

  const handleAbrirEntrega = (linea: any, tipo: 'entrega' | 'reposicion') => {
    setLineaSeleccionada(linea);
    setTipoEntrega(tipo);
    setCantEntrega(tipo === 'entrega' ? Number(linea.cantidad_pendiente) : 1);
    setMotivoEntrega('');
    setModalEntregaOpen(true);
  };

  const handleConfirmarEntrega = async () => {
    if (!lineaSeleccionada || !orden) return;
    if (tipoEntrega === 'reposicion' && !motivoEntrega.trim()) {
      alert('El motivo de reposición es obligatorio');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const opSeleccionado = operarios.find((o) => o.id === operarioId);
      const nombreOp = opSeleccionado?.nombre || operarioNombreManual || 'Operario de taller';

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/entregar`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          linea_id: lineaSeleccionada.linea_id,
          cantidad: cantEntrega,
          tipo: tipoEntrega,
          operario_id: operarioId || null,
          operario_nombre: nombreOp,
          motivo: motivoEntrega.trim() || null,
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al registrar entrega');
      }

      setModalEntregaOpen(false);
      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al entregar');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleAbrirEntregarFase = (faseClave: string, faseNombre: string, pendientes: number) => {
    setFaseAEntregar({ clave: faseClave, nombre: faseNombre, pendientes });
    setFaseOperarioId('');
    setFaseOperarioNombreManual('');
    setModalEntregarFaseOpen(true);
  };

  const handleConfirmarEntregarFase = async () => {
    if (!faseAEntregar || !orden) return;
    const opNombre = faseOperarioId
      ? operarios.find((o) => o.id === faseOperarioId)?.nombre || faseOperarioNombreManual
      : faseOperarioNombreManual;

    if (!opNombre || !opNombre.trim()) {
      alert('Debe especificar el operario que recibe los materiales de la fase');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/entregar-fase`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          fase_clave: faseAEntregar.clave,
          operario_id: faseOperarioId || null,
          operario_nombre: opNombre.trim(),
          equipo_indice: equipoFiltro === 'todos' ? (orden.caracteristicas?.unidad || undefined) : parseInt(equipoFiltro, 10),
        }),
      });

      const resData = await res.json().catch(() => ({}));
      if (!res.ok) {
        throw new Error(resData.error || 'Error al entregar fase');
      }

      setModalEntregarFaseOpen(false);
      if (resData.mensaje) {
        alert(resData.mensaje);
      }
      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al entregar fase');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleAbrirAnular = (entrega: any) => {
    setEntregaAAnular(entrega);
    setMotivoAnulacion('');
    setModalAnularOpen(true);
  };

  const handleConfirmarAnulacion = async () => {
    if (!entregaAAnular || !orden) return;
    if (!motivoAnulacion.trim()) {
      alert('El motivo de anulación es requerido');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/anular-entrega`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          entrega_id: entregaAAnular.id,
          motivo: motivoAnulacion.trim(),
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al anular entrega');
      }

      setModalAnularOpen(false);
      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al anular');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleAgregarLineaManual = async () => {
    if (!orden || !manualDesc.trim()) return;
    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/lineas`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          fase_clave: manualFaseClave,
          descripcion: manualDesc.trim(),
          unidad: manualUnidad.trim() || 'pz',
          cantidad_requerida: Number(manualCant) || 1,
          equipo_indice: equipoFiltro !== 'todos' ? Number(equipoFiltro) : (orden.caracteristicas?.unidad || 1),
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al agregar partida');
      }

      setModalAgregarOpen(false);
      setManualDesc('');
      setManualCant(1);
      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al agregar partida manual');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleAbrirAjustar = (linea: any) => {
    setLineaAAjustar(linea);
    setNuevaCantRequerida(Number(linea.cantidad_requerida) || 1);
    setMotivoAjuste('');
    setModalAjustarOpen(true);
  };

  const handleConfirmarAjustar = async () => {
    if (!lineaAAjustar || !orden) return;
    if (!motivoAjuste.trim()) {
      alert('El motivo del ajuste es obligatorio');
      return;
    }

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = { 'Content-Type': 'application/json' };
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/lineas/${lineaAAjustar.linea_id}`, {
        method: 'PUT',
        headers,
        body: JSON.stringify({
          cantidad_requerida: Number(nuevaCantRequerida),
          motivo: motivoAjuste.trim(),
        }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al ajustar cantidad');
      }

      setModalAjustarOpen(false);
      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al ajustar cantidad');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleEliminarLineaManual = async (lineaId: string, desc: string) => {
    if (!orden) return;
    if (!window.confirm(`¿Estás seguro de eliminar la partida manual "${desc}"?`)) return;

    setProcesandoAccion(true);
    try {
      const { supabase: supa } = await import('../../utils/supabase/client');
      const session = (await supa.auth.getSession()).data.session;
      const token = session?.access_token;
      const orgId = session?.user?.user_metadata?.organizacion_id || localStorage.getItem('org_id');

      const headers: Record<string, string> = {};
      if (token) headers['Authorization'] = `Bearer ${token}`;
      if (orgId) headers['x-org-id'] = orgId;

      const res = await fetch(`${BASE_URL}/ordenes-trabajo/${orden.id}/despiece/lineas/${lineaId}`, {
        method: 'DELETE',
        headers,
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || 'Error al eliminar línea');
      }

      await cargarDatosDespiece(equipoFiltro);
    } catch (err: any) {
      alert(err.message || 'Error al eliminar partida');
    } finally {
      setProcesandoAccion(false);
    }
  };

  const handleExportarCSV = () => {
    if (!datos?.lineas || datos.lineas.length === 0) {
      alert('No hay líneas de despiece para exportar');
      return;
    }
    const headers = [
      'Fase',
      'Descripción',
      'Unidad',
      'Cantidad Requerida',
      'Cantidad Entregada',
      'Cantidad Pendiente',
      'Estado',
      'Última Entrega Fecha',
      'Último Operario',
      'Origen',
      'Equipo',
    ];
    const rows = datos.lineas.map((l: any) => [
      `"${(l.fase_nombre || l.fase_clave || '').replace(/"/g, '""')}"`,
      `"${(l.descripcion || '').replace(/"/g, '""')}"`,
      `"${(l.unidad || 'pz').replace(/"/g, '""')}"`,
      Number(l.cantidad_requerida) || 0,
      Number(l.cantidad_entregada) || 0,
      Number(l.cantidad_pendiente) || 0,
      `"${(l.estado_entrega || '').replace(/"/g, '""')}"`,
      `"${(l.ultima_entrega?.fecha || '').replace(/"/g, '""')}"`,
      `"${(l.ultima_entrega?.operario_nombre || '').replace(/"/g, '""')}"`,
      `"${(l.origen || '').replace(/"/g, '""')}"`,
      l.equipo_indice || 1,
    ]);
    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `despiece_${orden?.nomenclatura_id || orden?.id || 'checklist'}.csv`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  const esc = (str: any): string => {
    if (str === null || str === undefined) return '';
    return String(str)
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  };

  const handleImprimirVale = (faseClaveFiltro?: string) => {
    if (!orden || !datos) return;
    const printWindow = window.open('', '_blank');
    if (!printWindow) {
      window.print();
      return;
    }
    const clienteNombre = orden?.cliente?.nombre_razon_social || (orden?.cliente as any)?.nombre || '-';
    const lineasFiltradas = (datos.lineas || []).filter(
      (l: any) => !faseClaveFiltro || l.fase_clave === faseClaveFiltro
    );
    const nombreFaseFiltro = faseClaveFiltro
      ? lineasFiltradas[0]?.fase_nombre || faseClaveFiltro
      : '';
    const faseTitulo = faseClaveFiltro ? ` — Fase: ${nombreFaseFiltro}` : '';

    const html = `
      <!DOCTYPE html>
      <html>
      <head>
        <title>Vale de Entrega - Despiece OT ${esc(orden.nomenclatura_id || orden.id)}${esc(faseTitulo)}</title>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; font-size: 11px; margin: 20px; color: #111; }
          h1 { font-size: 16px; margin-bottom: 4px; text-transform: uppercase; }
          .meta { margin-bottom: 12px; border-bottom: 1px solid #ccc; padding-bottom: 8px; font-size: 10px; }
          .meta p { margin: 2px 0; }
          table { width: 100%; border-collapse: collapse; margin-top: 8px; font-size: 10px; }
          th, td { border: 1px solid #ddd; padding: 4px 6px; text-align: left; }
          th { background: #f4f4f5; text-transform: uppercase; font-weight: 600; }
          .text-right { text-align: right; }
          .firmas { margin-top: 36px; display: flex; justify-content: space-between; }
          .firma-box { width: 45%; border-top: 1px solid #000; text-align: center; padding-top: 4px; font-size: 10px; }
        </style>
      </head>
      <body>
        <h1>Vale de Entrega de Materiales y Checklist${esc(faseTitulo)}</h1>
        <div class="meta">
          <p><strong>Orden de Trabajo:</strong> ${esc(orden.nomenclatura_id || orden.id)} | <strong>NIV:</strong> ${esc(orden.niv || 'N/A')}</p>
          <p><strong>Modelo:</strong> ${esc(resolverModeloChecklist(orden))} | <strong>Cliente:</strong> ${esc(clienteNombre)}</p>
          <p><strong>Fecha Impresión:</strong> ${esc(new Date().toLocaleDateString('es-MX'))} ${esc(new Date().toLocaleTimeString('es-MX'))}</p>
          <p><strong>Partidas:</strong> ${lineasFiltradas.length} | <strong>Avance Global:</strong> ${metricas.porcentaje_avance}% (${metricas.total_piezas_entregadas} de ${metricas.total_piezas_requeridas} pz)</p>
        </div>
        <table>
          <thead>
            <tr>
              <th>Fase</th>
              <th>Descripción</th>
              <th class="text-right">Req.</th>
              <th class="text-right">Entregado</th>
              <th class="text-right">Pendiente</th>
              <th>Estado</th>
              <th>Recibió</th>
            </tr>
          </thead>
          <tbody>
            ${lineasFiltradas.map((l: any) => `
              <tr>
                <td>${esc(l.fase_nombre || l.fase_clave)}</td>
                <td>${esc(l.descripcion)}</td>
                <td class="text-right">${esc(l.cantidad_requerida)} ${esc(l.unidad || 'pz')}</td>
                <td class="text-right">${esc(l.cantidad_entregada)}</td>
                <td class="text-right">${esc(l.cantidad_pendiente)}</td>
                <td>${esc(l.estado_entrega)}</td>
                <td>${l.ultima_entrega ? `${esc(l.ultima_entrega.operario_nombre)} (${esc(l.ultima_entrega.fecha)})` : '-'}</td>
              </tr>
            `).join('')}
          </tbody>
        </table>
        <div class="firmas">
          <div class="firma-box">Entrega (Almacén de Planta)</div>
          <div class="firma-box">Recibe (Línea de Ensamble)</div>
        </div>
        <script>
          window.onload = function() { window.print(); };
        </script>
      </body>
      </html>
    `;
    printWindow.document.write(html);
    printWindow.document.close();
  };

  const toggleFase = (clave: string) => {
    setFasesExpandidas((prev) => ({
      ...prev,
      [clave]: prev[clave] === undefined ? false : !prev[clave],
    }));
  };

  const metricas = datos?.metricas || {
    total_lineas: 0,
    lineas_completas: 0,
    total_piezas_requeridas: 0,
    total_piezas_entregadas: 0,
    total_piezas_pendientes: 0,
    porcentaje_avance: 0,
  };

  // Agrupar líneas por fase
  const lineas = datos?.lineas || [];
  const fases = datos?.fases || [];

  const equiposOpciones = useMemo(() => {
    const set = new Set<number>();
    lineas.forEach((l: any) => {
      if (l.equipo_indice) set.add(Number(l.equipo_indice));
    });
    if (set.size === 0) {
      const total = Number(orden?.caracteristicas?.total_equipos) || Number(orden?.caracteristicas?.unidad) || 1;
      for (let i = 1; i <= total; i++) set.add(i);
    }
    return Array.from(set).sort((a, b) => a - b);
  }, [lineas, orden]);

  const fasesAgrupadas = fases.map((f: any) => {
    const partidasDeFase = lineas.filter((l: any) => l.fase_clave === f.clave);
    const piezasReq = partidasDeFase.reduce((acc: number, l: any) => acc + (Number(l.cantidad_requerida) || 0), 0);
    const piezasEnt = partidasDeFase.reduce((acc: number, l: any) => acc + (Number(l.cantidad_entregada) || 0), 0);
    const completa = piezasReq > 0 && piezasEnt >= piezasReq;
    const avanceFase = piezasReq > 0 ? Math.round((piezasEnt / piezasReq) * 100) : 0;

    return {
      fase: f,
      partidas: partidasDeFase,
      piezasReq,
      piezasEnt,
      completa,
      avanceFase,
    };
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl max-h-[92vh] overflow-y-auto bg-background text-foreground border-border p-6">
        <DialogHeader className="border-b border-border/50 pb-4">
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4">
            <div>
              <DialogTitle className="text-2xl font-bold flex items-center gap-2">
                <ClipboardCheck className="h-6 w-6 text-primary" />
                Checklist de Almacén y Control de Entregas
              </DialogTitle>
              <div className="flex flex-wrap items-center gap-2 mt-1 text-xs text-muted-foreground">
                <span className="font-mono font-bold text-foreground">{orden?.nomenclatura_id}</span>
                {orden?.niv && <span>• NIV: {orden.niv}</span>}
                <span>• {resolverModeloChecklist(orden)}</span>
                <span>• Cliente: {orden?.cliente?.nombre_razon_social || (orden?.cliente as any)?.nombre || '-'}</span>
              </div>
            </div>

            <div className="flex items-center gap-2">
              <Button
                variant="outline"
                size="sm"
                onClick={() => cargarDatosDespiece(equipoFiltro)}
                disabled={loading}
                className="border-border text-xs"
              >
                <RefreshCw className={`h-3.5 w-3.5 mr-1.5 ${loading ? 'animate-spin' : ''}`} />
                Actualizar
              </Button>
            </div>
          </div>
        </DialogHeader>

        {errorMsg && (
          <div className="p-3 bg-destructive/10 text-destructive border border-destructive/20 rounded-md text-sm flex items-center gap-2 my-2">
            <AlertCircle className="h-4 w-4 shrink-0" />
            <span>{errorMsg}</span>
          </div>
        )}

        {/* Resumen de avance */}
        <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 my-4">
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Piezas Requeridas</p>
            <p className="text-xl font-bold font-mono text-foreground mt-0.5">{metricas.total_piezas_requeridas}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Entregadas</p>
            <p className="text-xl font-bold font-mono text-primary mt-0.5">{metricas.total_piezas_entregadas}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Pendientes</p>
            <p className="text-xl font-bold font-mono text-muted-foreground mt-0.5">{metricas.total_piezas_pendientes}</p>
          </div>
          <div className="bg-card/50 p-3 rounded-lg border border-border/50">
            <p className="text-[11px] text-muted-foreground uppercase tracking-wider font-mono">Avance de Armado</p>
            <div className="flex items-center gap-2 mt-1">
              <div className="flex-1 bg-muted rounded-full h-2.5 overflow-hidden">
                <div
                  className="bg-primary h-2.5 transition-all duration-500"
                  style={{ width: `${Math.min(100, metricas.porcentaje_avance)}%` }}
                />
              </div>
              <span className="text-xs font-mono font-bold text-foreground">{metricas.porcentaje_avance}%</span>
            </div>
          </div>
        </div>

        {/* Barra de herramientas y filtros */}
        <div className="flex flex-wrap items-center justify-between gap-3 py-2 border-y border-border/40 my-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-muted-foreground font-medium">Equipo:</span>
            <Select value={equipoFiltro} onValueChange={(val) => setEquipoFiltro(val)}>
              <SelectTrigger className="w-[145px] h-8 text-xs border-border bg-background">
                <SelectValue placeholder="Equipo" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="todos">Todos los equipos</SelectItem>
                {equiposOpciones.map((eq) => (
                  <SelectItem key={eq} value={String(eq)}>
                    Equipo {eq}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => setModalAgregarOpen(true)}
              className="border-border text-xs h-8"
            >
              <Plus className="h-3.5 w-3.5 mr-1" />
              Partida manual
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleExportarCSV}
              className="border-border text-xs h-8"
              disabled={!lineas.length}
            >
              <FileSpreadsheet className="h-3.5 w-3.5 mr-1" />
              Exportar CSV
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={handleImprimirVale}
              className="border-border text-xs h-8"
              disabled={!lineas.length}
            >
              <Printer className="h-3.5 w-3.5 mr-1" />
              Imprimir Vale
            </Button>
            {lineas.length > 0 && (
              <Button
                variant="ghost"
                size="sm"
                onClick={() => handleGenerarDespiece(false)}
                disabled={generando}
                className="text-xs h-8 text-muted-foreground hover:text-foreground"
                title="Sincronizar despiece con receta sin sobreescribir entregas"
              >
                <RotateCcw className={`h-3 w-3 mr-1 ${generando ? 'animate-spin' : ''}`} />
                Sincronizar BOM
              </Button>
            )}
          </div>
        </div>

        {/* Alertas y avisos contextuales */}
        <div className="space-y-2">
          {(avisoRecetaCruda || lineas.some((l: any) => l.origen === 'receta_cruda')) && (
            <div className="p-3 bg-amber-500/10 border border-amber-500/30 rounded-lg text-xs text-amber-700 dark:text-amber-300 flex items-start gap-2">
              <AlertCircle className="h-4 w-4 shrink-0 text-amber-500 mt-0.5" />
              <div>
                <span className="font-semibold">Despiece de receta base cruda:</span> Esta orden no tiene presupuesto detallado resuelto; las partidas provienen de la receta base sin opciones ni escalas dinámicas. Verifique cantidades y materiales antes de entregar a producción.
              </div>
            </div>
          )}

          {cambiosPresupuesto.length > 0 && (
            <div className="p-3 bg-blue-500/10 border border-blue-500/30 rounded-lg text-xs text-blue-700 dark:text-blue-300">
              <div className="flex items-center gap-2 font-semibold mb-1">
                <AlertCircle className="h-4 w-4 text-blue-500" />
                Se detectaron {cambiosPresupuesto.length} cambios en el presupuesto respecto a lo registrado:
              </div>
              <ul className="list-disc list-inside space-y-0.5 pl-2 opacity-90">
                {cambiosPresupuesto.slice(0, 5).map((c: any, idx: number) => (
                  <li key={idx}>
                    <strong>{c.descripcion}</strong>: {c.motivo === 'cantidad_distinta' ? `Cant. en presupuesto ${c.cantidad_nueva} vs ${c.cantidad_actual} actual` : c.motivo === 'fase_distinta' ? `Fase ${c.fase_nueva} vs ${c.fase_actual}` : `Cant. ${c.cantidad_nueva} y fase ${c.fase_nueva}`}
                  </li>
                ))}
                {cambiosPresupuesto.length > 5 && (
                  <li>... y {cambiosPresupuesto.length - 5} partidas más.</li>
                )}
              </ul>
              <p className="mt-1 text-[11px] opacity-75">
                Para preservar el historial de entregas, ajuste manualmente las partidas correspondientes usando el botón de edición.
              </p>
            </div>
          )}

          {avisoSinFase > 0 && (
            <div className="p-2.5 bg-muted border border-border/70 rounded-lg text-xs text-muted-foreground flex items-center gap-2">
              <AlertCircle className="h-4 w-4 text-muted-foreground shrink-0" />
              <span>
                {avisoSinFase} partidas no tienen asignada una equivalencia de fase registrada y se agruparon en Paso 1.
              </span>
            </div>
          )}
        </div>

        {/* Contenido principal */}
        {lineas.length === 0 ? (
          <div className="text-center py-12 bg-card/30 rounded-xl border border-dashed border-border/70 my-4">
            <PackageCheck className="h-12 w-12 text-muted-foreground mx-auto mb-3 opacity-60" />
            <h3 className="text-lg font-medium text-foreground mb-1">El despiece aún no ha sido cargado</h3>
            <p className="text-sm text-muted-foreground max-w-md mx-auto mb-4">
              Puedes generar el árbol de materiales por fases automáticamente a partir de la receta de producción o el presupuesto del cotizador.
            </p>
            <Button onClick={() => handleGenerarDespiece(false)} disabled={generando} className="bg-primary text-primary-foreground">
              <Plus className="h-4 w-4 mr-2" />
              {generando ? 'Generando despiece...' : 'Generar Despiece por Fases'}
            </Button>
          </div>
        ) : (
          <div className="space-y-4 my-2">
            {/* Acordeón de Fases */}
            {fasesAgrupadas.map(({ fase, partidas, piezasReq, piezasEnt, completa, avanceFase }: any) => {
              if (partidas.length === 0) return null;
              const expandida = fasesExpandidas[fase.clave] !== false; // Abierto por defecto

              return (
                <div key={fase.id || fase.clave} className="rounded-lg border border-border/60 overflow-hidden bg-card/30">
                  <div
                    className="p-3 bg-muted/40 flex items-center justify-between cursor-pointer select-none hover:bg-muted/60 transition-colors"
                    onClick={() => toggleFase(fase.clave)}
                  >
                    <div className="flex items-center gap-2.5">
                      {expandida ? (
                        <ChevronDown className="h-4 w-4 text-muted-foreground" />
                      ) : (
                        <ChevronRight className="h-4 w-4 text-muted-foreground" />
                      )}
                      <div>
                        <span className="font-semibold text-sm text-foreground">{fase.nombre}</span>
                        {fase.subtitulo && (
                          <span className="text-xs text-muted-foreground ml-2 hidden sm:inline">
                            — {fase.subtitulo}
                          </span>
                        )}
                      </div>
                    </div>

                    <div className="flex items-center gap-3" onClick={(e) => e.stopPropagation()}>
                      <div className="text-right text-xs font-mono">
                        <span className="text-primary font-bold">{piezasEnt}</span>
                        <span className="text-muted-foreground"> / {piezasReq} pz</span>
                      </div>

                      {completa ? (
                        <div className="flex items-center gap-2">
                          <Badge variant="outline" className="bg-primary/10 text-primary border-primary/30 text-[10px]">
                            Completa
                          </Badge>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="h-7 text-xs border border-border/50 text-muted-foreground hover:bg-muted"
                            onClick={() => handleImprimirVale(fase.clave)}
                            title="Imprimir vale de entrega de esta fase"
                          >
                            <Printer className="h-3.5 w-3.5 mr-1" />
                            Vale
                          </Button>
                        </div>
                      ) : (
                        <div className="flex items-center gap-2">
                          <Button
                            size="sm"
                            variant="outline"
                            className="h-7 text-xs border-border hover:bg-muted"
                            onClick={() => handleAbrirEntregarFase(fase.clave, fase.nombre, piezasReq - piezasEnt)}
                            disabled={procesandoAccion}
                          >
                            Entregar fase completa
                          </Button>
                          <Button
                            size="sm"
                            variant="ghost"
                            className="h-7 text-xs border border-border/50 text-muted-foreground hover:bg-muted"
                            onClick={() => handleImprimirVale(fase.clave)}
                            title="Imprimir vale de entrega de esta fase"
                          >
                            <Printer className="h-3.5 w-3.5 mr-1" />
                            Vale
                          </Button>
                        </div>
                      )}
                    </div>
                  </div>

                  {expandida && (
                    <div className="p-3 border-t border-border/40 overflow-x-auto">
                      <table className="w-full text-xs text-left">
                        <thead className="bg-muted/20 text-muted-foreground uppercase font-mono border-b border-border/40">
                          <tr>
                            <th className="p-2">Partida / Material</th>
                            <th className="p-2 text-right">Req.</th>
                            <th className="p-2 text-right">Entregado</th>
                            <th className="p-2 text-right">Pendiente</th>
                            <th className="p-2">Última Entrega</th>
                            <th className="p-2 text-right">Acción</th>
                          </tr>
                        </thead>
                        <tbody className="divide-y divide-border/30">
                          {partidas.map((l: any) => {
                            const esCompleto = l.estado_entrega === 'completo';
                            const ult = l.ultima_entrega;

                            return (
                              <tr key={l.linea_id} className="hover:bg-muted/10">
                                <td className="p-2">
                                  <div className="font-medium text-foreground">{l.descripcion}</div>
                                  <div className="flex flex-wrap items-center gap-1.5 mt-0.5">
                                    <span className="text-[10px] text-muted-foreground uppercase font-mono">
                                      {l.unidad || 'pz'}
                                    </span>
                                    {l.equipo_indice && (
                                      <Badge variant="outline" className="text-[9px] px-1 py-0 border-border">
                                        Eq. {l.equipo_indice}
                                      </Badge>
                                    )}
                                    {l.sin_costo && (
                                      <Badge
                                        variant="outline"
                                        className="text-[9px] border-destructive/40 text-destructive bg-destructive/10 px-1 py-0"
                                      >
                                        Sin costo cargado
                                      </Badge>
                                    )}
                                    {l.origen === 'receta_cruda' && (
                                      <Badge
                                        variant="outline"
                                        className="text-[9px] border-amber-500/40 text-amber-600 dark:text-amber-400 bg-amber-500/10 px-1 py-0"
                                      >
                                        Receta cruda
                                      </Badge>
                                    )}
                                    {l.origen === 'manual' && (
                                      <Badge variant="secondary" className="text-[9px] px-1 py-0">
                                        Manual
                                      </Badge>
                                    )}
                                  </div>
                                </td>
                                <td className="p-2 text-right font-mono">{l.cantidad_requerida}</td>
                                <td className="p-2 text-right font-mono font-bold text-primary">
                                  {l.cantidad_entregada}
                                </td>
                                <td className="p-2 text-right font-mono font-bold text-muted-foreground">
                                  {l.cantidad_pendiente}
                                </td>
                                <td className="p-2 text-xs text-muted-foreground">
                                  {ult ? (
                                    <div className="flex items-center justify-between gap-1">
                                      <div>
                                        <div className="font-medium text-foreground">{ult.operario_nombre}</div>
                                        <div className="text-[10px] opacity-75">{ult.fecha} {ult.tipo === 'reposicion' ? '(reposición)' : ''}</div>
                                      </div>
                                      <div className="flex items-center gap-1">
                                        <Button
                                          variant="ghost"
                                          size="sm"
                                          onClick={() => handleAbrirAnular(ult)}
                                          className="h-5 text-[10px] px-1 text-muted-foreground hover:text-destructive"
                                          title="Anular esta entrega"
                                        >
                                          Anular
                                        </Button>
                                        <Button
                                          variant="ghost"
                                          size="sm"
                                          onClick={() => {
                                            const entregasDeLinea = (datos?.entregas || []).filter((e: any) => e.linea_id === l.linea_id);
                                            setLineaHistorial({ ...l, entregas: entregasDeLinea });
                                            setModalHistorialOpen(true);
                                          }}
                                          className="h-5 text-[10px] px-1 text-primary hover:underline"
                                          title="Ver historial de movimientos"
                                        >
                                          Historial
                                        </Button>
                                      </div>
                                    </div>
                                  ) : (
                                    <span className="italic opacity-50">Sin entregas</span>
                                  )}
                                </td>
                                <td className="p-2 text-right space-x-1 whitespace-nowrap">
                                  {esCompleto ? (
                                    <div className="inline-flex flex-col items-end align-middle mr-1">
                                      <Badge
                                        variant="outline"
                                        className="bg-primary/10 text-primary border-primary/20 text-[10px]"
                                      >
                                        ✓ Completa
                                      </Badge>
                                      <span className="text-[9px] text-muted-foreground mt-0.5">
                                        Ya entregada completa {ult?.fecha ? `el ${ult.fecha}` : ''} {ult?.operario_nombre ? `a ${ult.operario_nombre}` : ''}
                                      </span>
                                    </div>
                                  ) : (
                                    <Button
                                      size="sm"
                                      className="h-6 text-[11px] px-2 bg-primary text-primary-foreground"
                                      onClick={() => handleAbrirEntrega(l, 'entrega')}
                                    >
                                      Entregar
                                    </Button>
                                  )}

                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    className="h-6 text-[11px] px-1.5 text-muted-foreground hover:text-foreground"
                                    onClick={() => handleAbrirEntrega(l, 'reposicion')}
                                    title="Registrar reposición por daño o sustitución"
                                  >
                                    + Reponer
                                  </Button>

                                  <Button
                                    size="sm"
                                    variant="ghost"
                                    className="h-6 text-[11px] px-1.5 text-muted-foreground hover:text-foreground"
                                    onClick={() => handleAbrirAjustar(l)}
                                    title="Ajustar cantidad requerida"
                                  >
                                    <Edit2 className="h-3 w-3" />
                                  </Button>

                                  {l.origen === 'manual' && Number(l.cantidad_entregada) === 0 && (
                                    <Button
                                      size="sm"
                                      variant="ghost"
                                      className="h-6 text-[11px] px-1 text-destructive hover:bg-destructive/10"
                                      onClick={() => handleEliminarLineaManual(l.linea_id, l.descripcion)}
                                      title="Eliminar partida manual"
                                    >
                                      <Trash2 className="h-3 w-3" />
                                    </Button>
                                  )}
                                </td>
                              </tr>
                            );
                          })}
                        </tbody>
                      </table>
                    </div>
                  )}
                </div>
              );
            })}
          </div>
        )}

        <DialogFooter className="border-t border-border/50 pt-4 mt-4 flex items-center justify-between">
          <div className="text-xs text-muted-foreground">
            Control de despiece — Leolca Producción & Almacén
          </div>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cerrar
          </Button>
        </DialogFooter>

        {/* Modal Registrar Entrega / Reposición */}
        <Dialog open={modalEntregaOpen} onOpenChange={setModalEntregaOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                {tipoEntrega === 'entrega' ? (
                  <PackageCheck className="h-5 w-5 text-primary" />
                ) : (
                  <ShieldAlert className="h-5 w-5 text-destructive" />
                )}
                {tipoEntrega === 'entrega' ? 'Registrar Entrega de Material' : 'Registrar Reposición de Pieza'}
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <div>
                <Label className="text-xs text-muted-foreground">Pieza</Label>
                <p className="font-semibold text-sm text-foreground">{lineaSeleccionada?.descripcion}</p>
                <div className="flex gap-4 mt-1 text-xs font-mono text-muted-foreground">
                  <span>Requerida: {lineaSeleccionada?.cantidad_requerida}</span>
                  <span>Ya entregada: {lineaSeleccionada?.cantidad_entregada}</span>
                  <span className="text-primary font-bold">Pendiente: {lineaSeleccionada?.cantidad_pendiente}</span>
                </div>
              </div>

              <div className="space-y-1.5">
                <Label>Cantidad a {tipoEntrega === 'entrega' ? 'entregar' : 'reponer'}</Label>
                <Input
                  type="number"
                  step="0.01"
                  min="0.01"
                  value={cantEntrega}
                  onChange={(e) => setCantEntrega(parseFloat(e.target.value))}
                  className="font-mono border-border"
                />
              </div>

              <div className="space-y-1.5">
                <Label>Operario que recibe</Label>
                <Select value={operarioId} onValueChange={setOperarioId}>
                  <SelectTrigger className="border-border">
                    <SelectValue placeholder="Seleccionar operario registrado" />
                  </SelectTrigger>
                  <SelectContent>
                    {operarios.map((op) => (
                      <SelectItem key={op.id} value={op.id}>
                        {op.nombre} {op.puesto ? `(${op.puesto})` : ''}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
                {!operarioId && (
                  <Input
                    placeholder="O escribe nombre del operario..."
                    value={operarioNombreManual}
                    onChange={(e) => setOperarioNombreManual(e.target.value)}
                    className="mt-1 text-xs border-border"
                  />
                )}
              </div>

              <div className="space-y-1.5">
                <Label>
                  Motivo {tipoEntrega === 'reposicion' ? '(Obligatorio)' : '(Opcional)'}
                </Label>
                <Input
                  placeholder={
                    tipoEntrega === 'reposicion'
                      ? 'Ej. Pieza doblada en montaje, defecto de fábrica...'
                      : 'Notas de entrega'
                  }
                  value={motivoEntrega}
                  onChange={(e) => setMotivoEntrega(e.target.value)}
                  className="border-border"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalEntregaOpen(false)}>
                Cancelar
              </Button>
              <Button
                onClick={handleConfirmarEntrega}
                disabled={procesandoAccion}
                className={tipoEntrega === 'entrega' ? 'bg-primary text-primary-foreground' : 'bg-destructive text-destructive-foreground'}
              >
                {procesandoAccion ? 'Registrando...' : 'Confirmar Entrega'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Modal Anular Entrega */}
        <Dialog open={modalAnularOpen} onOpenChange={setModalAnularOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                <RotateCcw className="h-5 w-5 text-destructive" />
                Anular Entrega Registrada
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <p className="text-xs text-muted-foreground">
                Al anular esta entrega, el material regresará al saldo pendiente de la partida.
              </p>
              <div className="space-y-1.5">
                <Label>Motivo de anulación (Obligatorio)</Label>
                <Input
                  placeholder="Ej. Error de captura, material devuelto al almacén..."
                  value={motivoAnulacion}
                  onChange={(e) => setMotivoAnulacion(e.target.value)}
                  className="border-border"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalAnularOpen(false)}>
                Cancelar
              </Button>
              <Button
                variant="destructive"
                onClick={handleConfirmarAnulacion}
                disabled={procesandoAccion || !motivoAnulacion.trim()}
              >
                {procesandoAccion ? 'Anulando...' : 'Confirmar Anulación'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Modal Agregar Partida Manual */}
        <Dialog open={modalAgregarOpen} onOpenChange={setModalAgregarOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                <Plus className="h-5 w-5 text-primary" />
                Agregar Partida Manual al Despiece
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <div className="space-y-1.5">
                <Label>Fase de Producción</Label>
                <Select value={manualFaseClave} onValueChange={setManualFaseClave}>
                  <SelectTrigger className="border-border">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {(datos?.fases || []).map((f: any) => (
                      <SelectItem key={f.clave} value={f.clave}>
                        {f.nombre}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>

              <div className="space-y-1.5">
                <Label>Descripción de la pieza / material</Label>
                <Input
                  placeholder="Ej. Perno reforzado 3/4 x 5..."
                  value={manualDesc}
                  onChange={(e) => setManualDesc(e.target.value)}
                  className="border-border"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-1.5">
                  <Label>Cantidad Requerida</Label>
                  <Input
                    type="number"
                    step="0.01"
                    min="0.01"
                    value={manualCant}
                    onChange={(e) => setManualCant(parseFloat(e.target.value) || 1)}
                    className="font-mono border-border"
                  />
                </div>
                <div className="space-y-1.5">
                  <Label>Unidad</Label>
                  <Input
                    value={manualUnidad}
                    onChange={(e) => setManualUnidad(e.target.value)}
                    className="border-border"
                    placeholder="pz, m, kg..."
                  />
                </div>
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalAgregarOpen(false)}>
                Cancelar
              </Button>
              <Button
                onClick={handleAgregarLineaManual}
                disabled={procesandoAccion || !manualDesc.trim()}
                className="bg-primary text-primary-foreground"
              >
                {procesandoAccion ? 'Guardando...' : 'Agregar Partida'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Modal Ajustar Cantidad Requerida */}
        <Dialog open={modalAjustarOpen} onOpenChange={setModalAjustarOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                <Edit2 className="h-5 w-5 text-primary" />
                Ajustar Cantidad Requerida
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <div>
                <Label className="text-xs text-muted-foreground">Pieza</Label>
                <p className="font-semibold text-sm text-foreground">{lineaAAjustar?.descripcion}</p>
                <div className="flex gap-4 mt-1 text-xs font-mono text-muted-foreground">
                  <span>Requerida actual: {lineaAAjustar?.cantidad_requerida}</span>
                  <span>Ya entregada: {lineaAAjustar?.cantidad_entregada}</span>
                </div>
              </div>

              <div className="space-y-1.5">
                <Label>Nueva Cantidad Requerida</Label>
                <Input
                  type="number"
                  step="0.01"
                  min={Number(lineaAAjustar?.cantidad_entregada) || 0}
                  value={nuevaCantRequerida}
                  onChange={(e) => setNuevaCantRequerida(parseFloat(e.target.value) || 0)}
                  className="font-mono border-border"
                />
                <p className="text-[11px] text-muted-foreground">
                  No puede ser menor que la cantidad ya entregada ({lineaAAjustar?.cantidad_entregada || 0}).
                </p>
              </div>

              <div className="space-y-1.5">
                <Label>Motivo del Ajuste (Obligatorio)</Label>
                <Input
                  placeholder="Ej. Cambio de especificación en ingeniería, sobrante..."
                  value={motivoAjuste}
                  onChange={(e) => setMotivoAjuste(e.target.value)}
                  className="border-border"
                />
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalAjustarOpen(false)}>
                Cancelar
              </Button>
              <Button
                onClick={handleConfirmarAjustar}
                disabled={procesandoAccion || !motivoAjuste.trim()}
                className="bg-primary text-primary-foreground"
              >
                {procesandoAccion ? 'Ajustando...' : 'Guardar Ajuste'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Modal Entregar Fase Completa con selección de operario */}
        <Dialog open={modalEntregarFaseOpen} onOpenChange={setModalEntregarFaseOpen}>
          <DialogContent className="max-w-md bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                <PackageCheck className="h-5 w-5 text-primary" />
                Entregar Fase Completa: {faseAEntregar?.nombre}
              </DialogTitle>
            </DialogHeader>

            <div className="space-y-4 py-2">
              <div className="p-3 bg-muted/40 rounded-lg text-xs space-y-1">
                <p><strong>Fase:</strong> {faseAEntregar?.nombre} ({faseAEntregar?.clave})</p>
                <p><strong>Partidas pendientes:</strong> {faseAEntregar?.pendientes} piezas por entregar en total</p>
                <p className="text-muted-foreground text-[11px] mt-1">
                  Esta acción registrará atómicamente la entrega de todas las piezas pendientes de esta fase en almacén.
                </p>
              </div>

              <div className="space-y-1.5">
                <Label>Operario que recibe en línea de ensamble (Obligatorio)</Label>
                {operarios.length > 0 ? (
                  <div className="space-y-2">
                    <Select
                      value={faseOperarioId}
                      onValueChange={(val) => {
                        setFaseOperarioId(val);
                        if (val !== 'otro') {
                          const op = operarios.find((o) => o.id === val);
                          if (op) setFaseOperarioNombreManual(op.nombre);
                        }
                      }}
                    >
                      <SelectTrigger className="border-border">
                        <SelectValue placeholder="Seleccionar operario registrado" />
                      </SelectTrigger>
                      <SelectContent>
                        {operarios.map((op) => (
                          <SelectItem key={op.id} value={op.id}>
                            {op.nombre} {op.especialidad ? `(${op.especialidad})` : ''}
                          </SelectItem>
                        ))}
                        <SelectItem value="otro">Otro (especificar nombre)</SelectItem>
                      </SelectContent>
                    </Select>

                    {(faseOperarioId === 'otro' || !faseOperarioId) && (
                      <Input
                        placeholder="Nombre completo del operario que recibe..."
                        value={faseOperarioNombreManual}
                        onChange={(e) => setFaseOperarioNombreManual(e.target.value)}
                        className="border-border"
                      />
                    )}
                  </div>
                ) : (
                  <Input
                    placeholder="Nombre completo del operario que recibe..."
                    value={faseOperarioNombreManual}
                    onChange={(e) => setFaseOperarioNombreManual(e.target.value)}
                    className="border-border"
                  />
                )}
              </div>
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalEntregarFaseOpen(false)}>
                Cancelar
              </Button>
              <Button
                onClick={handleConfirmarEntregarFase}
                disabled={procesandoAccion || (!faseOperarioId && !faseOperarioNombreManual.trim())}
                className="bg-primary text-primary-foreground"
              >
                {procesandoAccion ? 'Entregando fase...' : 'Confirmar Entrega de Fase'}
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>

        {/* Modal Historial de Movimientos de la Partida */}
        <Dialog open={modalHistorialOpen} onOpenChange={setModalHistorialOpen}>
          <DialogContent className="max-w-2xl bg-background border-border">
            <DialogHeader>
              <DialogTitle className="text-lg flex items-center gap-2">
                <ClipboardCheck className="h-5 w-5 text-primary" />
                Historial de Entregas y Movimientos
              </DialogTitle>
            </DialogHeader>

            <div className="py-2 space-y-3">
              <div>
                <p className="font-semibold text-sm text-foreground">{lineaHistorial?.descripcion}</p>
                <div className="flex gap-4 mt-1 text-xs font-mono text-muted-foreground">
                  <span>Requerida: {lineaHistorial?.cantidad_requerida} {lineaHistorial?.unidad || 'pz'}</span>
                  <span>Entregada: {lineaHistorial?.cantidad_entregada}</span>
                  <span className="text-primary font-bold">Pendiente: {lineaHistorial?.cantidad_pendiente}</span>
                </div>
              </div>

              {(!lineaHistorial?.entregas || lineaHistorial.entregas.length === 0) ? (
                <p className="text-xs text-muted-foreground italic py-4 text-center">
                  No hay movimientos registrados para esta partida.
                </p>
              ) : (
                <div className="overflow-x-auto border border-border/50 rounded-lg">
                  <table className="w-full text-xs text-left">
                    <thead className="bg-muted/30 text-muted-foreground uppercase font-mono border-b border-border/40">
                      <tr>
                        <th className="p-2">Fecha/Hora</th>
                        <th className="p-2">Tipo</th>
                        <th className="p-2 text-right">Cantidad</th>
                        <th className="p-2">Operario</th>
                        <th className="p-2">Motivo</th>
                        <th className="p-2">Estado</th>
                        <th className="p-2 text-right">Acción</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-border/30">
                      {lineaHistorial.entregas.map((e: any) => (
                        <tr key={e.id} className={`hover:bg-muted/10 ${e.anulada ? 'opacity-60 bg-muted/20 line-through' : ''}`}>
                          <td className="p-2 font-mono whitespace-nowrap">{e.fecha} {e.hora}</td>
                          <td className="p-2">
                            <Badge variant={e.tipo === 'reposicion' ? 'destructive' : 'outline'} className="text-[10px] px-1 py-0">
                              {e.tipo}
                            </Badge>
                          </td>
                          <td className="p-2 text-right font-mono font-bold">{e.cantidad}</td>
                          <td className="p-2">{e.operario_nombre || e.operarios?.nombre || '-'}</td>
                          <td className="p-2 text-[11px] max-w-[150px] truncate" title={e.motivo || ''}>{e.motivo || '-'}</td>
                          <td className="p-2">
                            {e.anulada ? (
                              <span className="text-destructive font-semibold text-[10px]" title={e.motivo_anulacion || 'Anulada'}>
                                Anulada
                              </span>
                            ) : (
                              <span className="text-primary font-semibold text-[10px]">Activa</span>
                            )}
                          </td>
                          <td className="p-2 text-right">
                            {!e.anulada && (
                              <Button
                                size="sm"
                                variant="ghost"
                                onClick={() => {
                                  setModalHistorialOpen(false);
                                  handleAbrirAnular(e);
                                }}
                                className="h-6 text-[10px] px-2 text-destructive hover:bg-destructive/10"
                                title="Anular este movimiento"
                              >
                                Anular
                              </Button>
                            )}
                          </td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
              )}
            </div>

            <DialogFooter>
              <Button variant="outline" onClick={() => setModalHistorialOpen(false)}>
                Cerrar
              </Button>
            </DialogFooter>
          </DialogContent>
        </Dialog>
      </DialogContent>
    </Dialog>
  );
}
