import React, { useState, useEffect, useCallback } from 'react';
import { useSearchParams } from 'react-router-dom';
import { Tabs, TabsList, TabsTrigger, TabsContent } from '../ui/tabs';
import { LayoutDashboard, FileText, DollarSign, Scale, ShoppingCart } from 'lucide-react';
import { toast } from 'sonner';
import { BASE_URL } from '../../utils/api';
import { supabase } from '../../utils/supabase/client';
import { CxpResumenTab } from './CxpResumenTab';
import { CxpFacturasTab } from './CxpFacturasTab';
import { CxpPagosTab } from './CxpPagosTab';
import { CxpConciliacionTab } from './CxpConciliacionTab';
import { CuentasPorPagar } from './CuentasPorPagar';
import { CompraProveedor, PagoProveedor, Proveedor, Producto } from '../../types';

export interface CuentasPorPagarMainProps {
  compras: CompraProveedor[];
  pagos: PagoProveedor[];
  proveedores: Proveedor[];
  productos: Producto[];
  loading: boolean;
  onCrearPago: (pago: any) => Promise<void>;
  session?: any;
}

export function CuentasPorPagarMain(props: CuentasPorPagarMainProps) {
  const [searchParams, setSearchParams] = useSearchParams();

  // Tab activo sincronizado con URL
  const tabUrl = searchParams.get('tab') || 'resumen';
  const [activeTab, setActiveTab] = useState<string>(
    ['resumen', 'facturas', 'pagos', 'conciliacion', 'compras'].includes(tabUrl) ? tabUrl : 'resumen'
  );

  // Filtro de proveedor
  const [proveedorFiltro, setProveedorFiltro] = useState<string>('');

  // Estados de Resumen y Tipo de Cambio
  const [fechaCorte, setFechaCorte] = useState<string>(() => new Date().toISOString().slice(0, 10));
  const [tipoCambioInput, setTipoCambioInput] = useState<string>('');
  const [resumenData, setResumenData] = useState<any>(null);
  const [cargandoResumen, setCargandoResumen] = useState(false);
  const [guardandoTC, setGuardandoTC] = useState(false);

  // Estados de Facturas
  const [facturas, setFacturas] = useState<any[]>([]);
  const [cargandoFacturas, setCargandoFacturas] = useState(false);

  useEffect(() => {
    const tabFromUrl = searchParams.get('tab');
    if (tabFromUrl && ['resumen', 'facturas', 'pagos', 'conciliacion', 'compras'].includes(tabFromUrl)) {
      setActiveTab(tabFromUrl);
    }
  }, [searchParams]);

  const handleTabChange = (nuevoTab: string) => {
    setActiveTab(nuevoTab);
    const params = new URLSearchParams(searchParams);
    params.set('tab', nuevoTab);
    setSearchParams(params, { replace: true });
  };

  const getAuthToken = async () => {
    const { data: { session } } = await supabase.auth.getSession();
    return session?.access_token || '';
  };

  // Cargar Resumen General
  const fetchResumen = useCallback(async () => {
    setCargandoResumen(true);
    try {
      const token = await getAuthToken();
      let url = `${BASE_URL}/cxp/resumen?corte=${fechaCorte}`;
      if (tipoCambioInput && Number(tipoCambioInput) > 0) {
        url += `&tc=${tipoCambioInput}`;
      }

      const res = await fetch(url, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        throw new Error(`Error ${res.status}: ${res.statusText}`);
      }

      const data = await res.json();
      setResumenData(data);
      if (data.tc && !tipoCambioInput) {
        setTipoCambioInput(String(data.tc));
      }
    } catch (err: any) {
      console.error('Error al cargar resumen CXP:', err);
      toast.error(`Error al cargar resumen: ${err.message}`);
    } finally {
      setCargandoResumen(false);
    }
  }, [fechaCorte, tipoCambioInput]);

  // Cargar Facturas
  const fetchFacturas = useCallback(async () => {
    setCargandoFacturas(true);
    try {
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/cxp/facturas`, {
        headers: { Authorization: `Bearer ${token}` },
      });

      if (!res.ok) {
        throw new Error(`Error ${res.status}: ${res.statusText}`);
      }

      const data = await res.json();
      setFacturas(data.facturas || []);
    } catch (err: any) {
      console.error('Error al cargar facturas CXP:', err);
      toast.error(`Error al cargar facturas: ${err.message}`);
    } finally {
      setCargandoFacturas(false);
    }
  }, []);

  useEffect(() => {
    fetchResumen();
  }, [fetchResumen]);

  useEffect(() => {
    fetchFacturas();
  }, [fetchFacturas]);

  // Guardar Tipo de Cambio para hoy
  const handleGuardarTipoCambioHoy = async () => {
    if (!tipoCambioInput || Number(tipoCambioInput) <= 0) {
      toast.error('Ingrese un tipo de cambio válido mayor a 0');
      return;
    }

    setGuardandoTC(true);
    try {
      const token = await getAuthToken();
      const hoyLocal = new Date().toISOString().slice(0, 10);

      const res = await fetch(`${BASE_URL}/cxp/tipos-cambio`, {
        method: 'PUT',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({
          fecha: hoyLocal,
          valor: Number(tipoCambioInput),
          fuente: 'manual',
          notas: 'Capturado desde pantalla Cuentas por Pagar',
        }),
      });

      const data = await res.json();
      if (!res.ok) {
        throw new Error(data.error || 'Error al guardar tipo de cambio');
      }

      toast.success(`Tipo de cambio guardado para hoy (${hoyLocal}): $${Number(tipoCambioInput).toFixed(4)}`);
      fetchResumen();
    } catch (err: any) {
      console.error('Error al guardar tipo de cambio:', err);
      toast.error(`Error: ${err.message}`);
    } finally {
      setGuardandoTC(false);
    }
  };

  // Acciones sobre Facturas
  const handleCrearFactura = async (payload: any) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/cxp/facturas`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || 'Error al crear factura');
    }

    toast.success(`Factura ${payload.folio} registrada`);
    await Promise.all([fetchFacturas(), fetchResumen()]);
  };

  const handleActualizarFactura = async (id: string, payload: any) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/cxp/facturas/${id}`, {
      method: 'PUT',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || 'Error al actualizar factura');
    }

    toast.success('Factura actualizada');
    await Promise.all([fetchFacturas(), fetchResumen()]);
  };

  const handleCancelarFactura = async (id: string) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/cxp/facturas/${id}/cancelar`, {
      method: 'POST',
      headers: { Authorization: `Bearer ${token}` },
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || 'Error al cancelar factura');
    }

    toast.success('Factura cancelada');
    await Promise.all([fetchFacturas(), fetchResumen()]);
  };

  const handleRegistrarPago = async (facturaId: string, payload: any) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/cxp/facturas/${facturaId}/pagos`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify(payload),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || 'Error al registrar abono');
    }

    toast.success('Abono registrado con éxito');
    await Promise.all([fetchFacturas(), fetchResumen()]);
  };

  const handleAnularPago = async (pagoId: string, motivo: string) => {
    const token = await getAuthToken();
    const res = await fetch(`${BASE_URL}/cxp/pagos/${pagoId}/anular`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
      },
      body: JSON.stringify({ motivo }),
    });

    const data = await res.json();
    if (!res.ok) {
      throw new Error(data.error || 'Error al anular abono');
    }

    toast.success('Abono anulado. Saldo de factura restaurado.');
    await Promise.all([fetchFacturas(), fetchResumen()]);
  };

  const handleSeleccionarProveedorParaFacturas = (pId: string) => {
    setProveedorFiltro(pId);
    handleTabChange('facturas');
  };

  return (
    <div className="space-y-6">
      {/* Encabezado del Módulo */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-bold tracking-tight text-foreground">
            Cuentas por Pagar
          </h1>
          <p className="text-sm text-muted-foreground mt-1">
            Control de facturas, vencimientos, abonos parciales, divisas USD/MXN y conciliación contra estados de cuenta de proveedores.
          </p>
        </div>
      </div>

      {/* Navegación por Pestañas */}
      <Tabs value={activeTab} onValueChange={handleTabChange} className="space-y-6">
        <TabsList className="bg-muted p-1 rounded-lg border border-border inline-flex h-auto w-full md:w-auto overflow-x-auto justify-start">
          <TabsTrigger
            value="resumen"
            className="flex items-center gap-2 py-2 px-4 text-xs font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md transition-all"
          >
            <LayoutDashboard className="h-4 w-4" />
            Resumen General
          </TabsTrigger>

          <TabsTrigger
            value="facturas"
            className="flex items-center gap-2 py-2 px-4 text-xs font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md transition-all"
          >
            <FileText className="h-4 w-4" />
            Facturas
          </TabsTrigger>

          <TabsTrigger
            value="pagos"
            className="flex items-center gap-2 py-2 px-4 text-xs font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md transition-all"
          >
            <DollarSign className="h-4 w-4" />
            Abonos
          </TabsTrigger>

          <TabsTrigger
            value="conciliacion"
            className="flex items-center gap-2 py-2 px-4 text-xs font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md transition-all"
          >
            <Scale className="h-4 w-4" />
            Conciliación
          </TabsTrigger>

          <TabsTrigger
            value="compras"
            className="flex items-center gap-2 py-2 px-4 text-xs font-medium data-[state=active]:bg-background data-[state=active]:text-foreground data-[state=active]:shadow-sm rounded-md transition-all"
          >
            <ShoppingCart className="h-4 w-4" />
            Por compras
          </TabsTrigger>
        </TabsList>

        <TabsContent value="resumen" className="mt-0 focus-visible:outline-none focus-visible:ring-0">
          <CxpResumenTab
            resumenData={resumenData}
            cargando={cargandoResumen}
            fechaCorte={fechaCorte}
            onCambiarFechaCorte={setFechaCorte}
            tipoCambio={tipoCambioInput}
            onCambiarTipoCambio={setTipoCambioInput}
            onGuardarTipoCambioHoy={handleGuardarTipoCambioHoy}
            guardandoTC={guardandoTC}
            onSeleccionarProveedor={handleSeleccionarProveedorParaFacturas}
          />
        </TabsContent>

        <TabsContent value="facturas" className="mt-0 focus-visible:outline-none focus-visible:ring-0">
          <CxpFacturasTab
            facturas={facturas}
            proveedores={props.proveedores || []}
            cargando={cargandoFacturas}
            proveedorFiltro={proveedorFiltro}
            onCambiarProveedorFiltro={setProveedorFiltro}
            tipoCambioActual={resumenData?.tc || (tipoCambioInput ? Number(tipoCambioInput) : null)}
            onCrearFactura={handleCrearFactura}
            onActualizarFactura={handleActualizarFactura}
            onCancelarFactura={handleCancelarFactura}
            onRegistrarPago={handleRegistrarPago}
            onAnularPago={handleAnularPago}
          />
        </TabsContent>

        <TabsContent value="pagos" className="mt-0 focus-visible:outline-none focus-visible:ring-0">
          <CxpPagosTab />
        </TabsContent>

        <TabsContent value="conciliacion" className="mt-0 focus-visible:outline-none focus-visible:ring-0">
          <CxpConciliacionTab
            proveedores={props.proveedores || []}
            proveedorInicial={proveedorFiltro}
          />
        </TabsContent>

        <TabsContent value="compras" className="mt-0 focus-visible:outline-none focus-visible:ring-0">
          <CuentasPorPagar
            compras={props.compras}
            pagos={props.pagos}
            proveedores={props.proveedores}
            productos={props.productos}
            loading={props.loading}
            onCrearPago={props.onCrearPago}
          />
        </TabsContent>
      </Tabs>
    </div>
  );
}
