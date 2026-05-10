import { useState, useEffect } from 'react';
import { ModernLayout } from './components/ModernLayout';
import { DashboardMain } from './components/Dashboard/DashboardMain';
import { CotizacionesList } from './components/Cotizaciones/CotizacionesList';
import { CotizacionEditor } from './components/Cotizaciones/CotizacionEditor';
import { CotizacionDetalle } from './components/Cotizaciones/CotizacionDetalle';
import { PDFFullPageCompact } from './components/Cotizaciones/PDFFullPageCompact';
import { PortalCliente } from './components/Portal/PortalCliente';
import { PortalPDF } from './components/Portal/PortalPDF';

import { ClientesList } from './components/Clientes/ClientesList';
import { ProductosList } from './components/Productos/ProductosList';
import { AjustesForm } from './components/Ajustes/AjustesForm';
import { PlantillasList } from './components/Plantillas/PlantillasList';
import { EquipoManager } from './components/Equipo/EquipoManager';
import { Toaster } from './components/ui/sonner';
import { useSupabaseData } from './hooks/useSupabaseData';
import { toast } from "sonner";
import { supabase } from './utils/supabase/client';
import { Session } from '@supabase/supabase-js';
import { Login } from './components/Auth/Login';
import { Routes, Route, useNavigate, useLocation, Navigate, useParams } from 'react-router-dom';

export default function App() {
  const navigate = useNavigate();
  const location = useLocation();

  const [session, setSession] = useState<Session | null>(null);
  const [isInitializingAuth, setIsInitializingAuth] = useState(true);

  useEffect(() => {
    supabase.auth.getSession().then(({ data: { session } }) => {
      setSession(session);
      setIsInitializingAuth(false);
    });

    const {
      data: { subscription },
    } = supabase.auth.onAuthStateChange((_event, session) => {
      setSession(session);
    });

    return () => subscription.unsubscribe();
  }, []);


  // Verificar si se debe abrir vista PDF desde URL
  useEffect(() => {
    const urlParams = new URLSearchParams(window.location.search);
    const pdfId = urlParams.get('pdf');
    
    if (pdfId && location.pathname === '/') {
      navigate(`/cotizaciones/${pdfId}/pdf`);
    }
  }, [navigate, location.pathname]);

  const {
    clientes,
    productos,
    cotizaciones,
    pagos,
    ajustes,
    plantillas,
    loading,
    serverError,
    useLocalData,
    crearCliente,
    actualizarCliente,
    eliminarCliente,
    crearProducto,
    actualizarProducto,
    eliminarProducto,
    crearCotizacion,
    actualizarCotizacion,
    eliminarCotizacion,
    duplicarCotizacion,
    generarTokenPortal,
    crearPago,
    obtenerPagosPorCotizacion,
    calcularSaldoPendiente,
    actualizarAjustes,
    crearPlantilla,
    actualizarPlantilla,
    eliminarPlantilla,
    guardarComoPlantilla,
    onExportPDF,
  } = useSupabaseData(session?.access_token);

  // Mostrar error del servidor o notificación de modo local
  useEffect(() => {
    if (useLocalData) {
      toast.warning('Modo sin conexión', {
        description: serverError
          ? `No se pudieron cargar datos: ${serverError}`
          : 'El servidor no está disponible. Los datos se guardarán localmente en tu navegador. Recarga la página cuando el servidor esté listo.',
        duration: 8000,
      });
    }
  }, [useLocalData, serverError]);

  // Navegación
  const manejarNavegacion = (pagina: string) => {
    if (pagina === 'dashboard') navigate('/');
    else navigate(`/${pagina}`);
  };

  // Cotizaciones
  const manejarNuevaCotizacion = () => {
    navigate('/cotizaciones/nueva');
  };

  const manejarVerCotizacion = (id: string) => {
    navigate(`/cotizaciones/${id}`);
  };

  const manejarEditarCotizacion = (id: string) => {
    navigate(`/cotizaciones/${id}/editar`);
  };

  const manejarDuplicarCotizacion = async (id: string) => {
    try {
      const cotizacionDuplicada = await duplicarCotizacion(id);
      if (cotizacionDuplicada) {
        toast.success(`Cotización duplicada como ${cotizacionDuplicada.folio}`);
        navigate(`/cotizaciones/${cotizacionDuplicada.id}/editar`);
      }
    } catch (error) {
      toast.error('Error al duplicar cotización');
    }
  };

  const manejarEliminarCotizacion = async (id: string) => {
    try {
      await eliminarCotizacion(id);
      toast.success('Cotización eliminada');
      if (location.pathname.includes(id)) {
        navigate('/cotizaciones');
      }
    } catch (error) {
      toast.error('Error al eliminar cotización');
    }
  };

  const manejarGuardarCotizacion = async (data: any, isNew: boolean, currentId?: string) => {
    try {
      const esNuevaVersion = data.cotizacion_padre_id !== undefined;

      if (isNew || esNuevaVersion) {
        const nuevaCotizacion = await crearCotizacion(data);
        if (!nuevaCotizacion?.id || !nuevaCotizacion?.folio) {
          throw new Error('El servidor no devolvió una cotización válida.');
        }
        toast.success(
          esNuevaVersion 
            ? `Nueva versión (v${nuevaCotizacion.version}) creada exitosamente` 
            : `Cotización ${nuevaCotizacion.folio} creada`
        );
        navigate(`/cotizaciones/${nuevaCotizacion.id}`);
      } else if (currentId) {
        await actualizarCotizacion(currentId, data);
        toast.success('Cotización actualizada');
        navigate(`/cotizaciones/${currentId}`);
      }
    } catch (error) {
      toast.error('Error al guardar cotización', {
        description: error instanceof Error ? error.message : undefined,
        duration: 8000,
      });
    }
  };

  const manejarCambiarEstado = async (id: string, estado: any) => {
    try {
      await actualizarCotizacion(id, { estado });
      toast.success(`Estado cambiado a ${estado}`);
    } catch (error) {
      toast.error('Error al cambiar estado');
    }
  };

  const manejarVerPDF = (cotizacion: any) => {
    navigate(`/cotizaciones/${cotizacion.id}/pdf`);
  };

  const manejarGenerarTokenPortal = async (id: string) => {
    try {
      const result = await generarTokenPortal(id);
      const portalUrl = `${window.location.origin}/cotizacion/${result.token}`;
      toast.success('Link del portal generado');
      return { ...result, portalUrl };
    } catch (error) {
      toast.error('Error al generar link del portal');
      throw error;
    }
  };

  const manejarExportarPDF = (cotizacion: any) => {
    try {
      onExportPDF(cotizacion);
      toast.success(`Abriendo vista PDF de cotización ${cotizacion.folio}`);
    } catch (error) {
      toast.error('Error al abrir vista PDF');
    }
  };

  const manejarVolverACotizaciones = () => {
    navigate('/cotizaciones');
  };

  // CRUD handlers para clientes
  const manejarCrearCliente = async (clienteData: any) => {
    try {
      const clienteCreado = await crearCliente(clienteData);
      toast.success('Cliente creado exitosamente');
      return clienteCreado;
    } catch (error) {
      toast.error('Error al crear cliente');
      throw error;
    }
  };

  const manejarActualizarCliente = async (id: string, clienteData: any) => {
    try {
      await actualizarCliente(id, clienteData);
      toast.success('Cliente actualizado exitosamente');
    } catch (error) {
      toast.error('Error al actualizar cliente');
    }
  };

  const manejarEliminarCliente = async (id: string) => {
    try {
      await eliminarCliente(id);
      toast.success('Cliente eliminado');
    } catch (error) {
      toast.error('Error al eliminar cliente');
    }
  };

  // CRUD handlers para productos
  const manejarCrearProducto = async (productoData: any) => {
    try {
      await crearProducto(productoData);
      toast.success('Producto creado exitosamente');
    } catch (error) {
      toast.error('Error al crear producto');
    }
  };

  const manejarActualizarProducto = async (id: string, productoData: any) => {
    try {
      await actualizarProducto(id, productoData);
      toast.success('Producto actualizado exitosamente');
    } catch (error) {
      toast.error('Error al actualizar producto');
    }
  };

  const manejarEliminarProducto = async (id: string) => {
    try {
      await eliminarProducto(id);
      toast.success('Producto eliminado');
    } catch (error) {
      toast.error('Error al eliminar producto');
    }
  };

  // Handler para ajustes
  const manejarActualizarAjustes = async (nuevosAjustes: any) => {
    try {
      await actualizarAjustes(nuevosAjustes);
      toast.success('Ajustes guardados exitosamente');
    } catch (error) {
      toast.error('Error al guardar ajustes');
    }
  };

  // Handler para pagos
  const manejarCrearPago = async (pagoData: any) => {
    try {
      await crearPago(pagoData);
      toast.success('Pago registrado exitosamente');
    } catch (error) {
      toast.error('Error al registrar pago');
    }
  };



  // Plantillas handlers
  const manejarCrearPlantilla = async (data: any) => {
    try {
      const result = await crearPlantilla(data);
      toast.success('Plantilla creada');
      return result;
    } catch (error) {
      toast.error('Error al crear plantilla', {
        description: error instanceof Error ? error.message : undefined
      });
      throw error;
    }
  };

  const manejarActualizarPlantilla = async (id: string, data: any) => {
    try {
      await actualizarPlantilla(id, data);
      toast.success('Plantilla actualizada');
    } catch (error) {
      toast.error('Error al actualizar plantilla', {
        description: error instanceof Error ? error.message : undefined
      });
    }
  };

  const manejarEliminarPlantilla = async (id: string) => {
    try {
      await eliminarPlantilla(id);
      toast.success('Plantilla eliminada');
    } catch { toast.error('Error al eliminar plantilla'); }
  };

  const manejarGuardarComoPlantilla = async (nombre: string, descripcion: string, data: any) => {
    try {
      const result = await guardarComoPlantilla(nombre, descripcion, data);
      toast.success(`Plantilla "${nombre}" guardada`);
      return result;
    } catch (error) {
      toast.error('Error al guardar plantilla', {
        description: error instanceof Error ? error.message : undefined
      });
      throw error;
    }
  };

  // Helper para determinar la página actual del layout
  const getCurrentPage = () => {
    const path = location.pathname;
    if (path === '/') return 'dashboard';
    if (path.startsWith('/cotizaciones')) return 'cotizaciones';
    if (path.startsWith('/clientes')) return 'clientes';
    if (path.startsWith('/productos')) return 'productos';
    if (path.startsWith('/ajustes')) return 'ajustes';
    if (path.startsWith('/plantillas')) return 'plantillas';
    if (path.startsWith('/equipo')) return 'equipo';
    return 'dashboard';
  };

  const renderizarContenido = () => {
    return (
      <Routes>
        <Route path="/" element={
          <DashboardMain
            cotizaciones={cotizaciones}
            clientes={clientes}
            productos={productos}
            pagos={pagos}
            loading={loading}
            onNuevaCotizacion={manejarNuevaCotizacion}
            onVerCotizacion={manejarVerCotizacion}
            onNavigate={manejarNavegacion}
          />
        } />
        
        <Route path="/cotizaciones" element={
          <CotizacionesList
            cotizaciones={cotizaciones}
            loading={loading}
            onNuevaCotizacion={manejarNuevaCotizacion}
            onVerCotizacion={manejarVerCotizacion}
            onDuplicarCotizacion={manejarDuplicarCotizacion}
            onEliminarCotizacion={manejarEliminarCotizacion}
          />
        } />

        <Route path="/cotizaciones/nueva" element={
          <CotizacionEditor
            clientes={clientes}
            productos={productos}
            plantillas={plantillas}
            ajustes={ajustes}
            onGuardar={(data) => manejarGuardarCotizacion(data, true)}
            onVolver={manejarVolverACotizaciones}
            onExportPDF={manejarExportarPDF}
            onVerPDF={manejarVerPDF}
            onCrearCliente={manejarCrearCliente}
            onGuardarComoPlantilla={manejarGuardarComoPlantilla}
            esNueva={true}
          />
        } />

        <Route path="/cotizaciones/:id/editar" element={
          <CotizacionEditorWrapper
            cotizaciones={cotizaciones}
            clientes={clientes}
            productos={productos}
            plantillas={plantillas}
            ajustes={ajustes}
            onGuardar={manejarGuardarCotizacion}
            onVolver={manejarVolverACotizaciones}
            onExportPDF={manejarExportarPDF}
            onVerPDF={manejarVerPDF}
            onDuplicar={manejarDuplicarCotizacion}
            onCrearCliente={manejarCrearCliente}
            onGuardarComoPlantilla={manejarGuardarComoPlantilla}
          />
        } />

        <Route path="/plantillas" element={
          <PlantillasList
            plantillas={plantillas}
            loading={loading}
            onCrearPlantilla={manejarCrearPlantilla}
            onActualizarPlantilla={manejarActualizarPlantilla}
            onEliminarPlantilla={manejarEliminarPlantilla}
          />
        } />

        <Route path="/cotizaciones/:id" element={
          <CotizacionDetalleWrapper 
            cotizaciones={cotizaciones}
            clientes={clientes}
            productos={productos}
            ajustes={ajustes}
            obtenerPagosPorCotizacion={obtenerPagosPorCotizacion}
            calcularSaldoPendiente={calcularSaldoPendiente}
            onVolver={manejarVolverACotizaciones}
            onEditar={manejarEditarCotizacion}
            onExportPDF={manejarExportarPDF}
            onVerPDF={manejarVerPDF}
            onCambiarEstado={manejarCambiarEstado}
            onCrearPago={manejarCrearPago}
            onGenerarTokenPortal={manejarGenerarTokenPortal}
          />
        } />

        <Route path="/cotizaciones/:id/pdf" element={
          <PDFFullPageWrapper 
            cotizaciones={cotizaciones}
            clientes={clientes}
            productos={productos}
            ajustes={ajustes}
            onVolver={manejarVolverACotizaciones}
            onExportPDF={manejarExportarPDF}
          />
        } />

        <Route path="/clientes" element={
          <ClientesList
            clientes={clientes}
            loading={loading}
            onCrearCliente={manejarCrearCliente}
            onActualizarCliente={manejarActualizarCliente}
            onEliminarCliente={manejarEliminarCliente}
          />
        } />

        <Route path="/productos" element={
          <ProductosList
            productos={productos}
            loading={loading}
            onCrearProducto={manejarCrearProducto}
            onActualizarProducto={manejarActualizarProducto}
            onEliminarProducto={manejarEliminarProducto}
          />
        } />

        <Route path="/ajustes" element={
          <AjustesForm
            ajustes={ajustes}
            onActualizarAjustes={manejarActualizarAjustes}
          />
        } />

        <Route path="/equipo" element={
          <EquipoManager token={session?.access_token || ''} />
        } />
        
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    );
  };



  if (isInitializingAuth) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-gray-50">
        <div className="w-8 h-8 border-4 border-purple-600 border-t-transparent rounded-full animate-spin"></div>
      </div>
    );
  }

  if (location.pathname.startsWith('/cotizacion/')) {
    return (
      <>
        <Routes>
          <Route path="/cotizacion/:token" element={<PortalCliente />} />
          <Route path="/cotizacion/:token/pdf" element={<PortalPDF />} />
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
        <Toaster />
      </>
    );
  }

  if (!session) {
    return <Login />;
  }

  return (
    <>
      <ModernLayout
        currentPage={getCurrentPage()}
        onNavigate={manejarNavegacion}
      >
        {renderizarContenido()}
      </ModernLayout>
      <Toaster />
    </>
  );
}

function CotizacionEditorWrapper({ cotizaciones, onGuardar, ...props }: any) {
  const { id } = useParams();
  if (!id || id === 'undefined' || id === 'null') return <Navigate to="/cotizaciones" replace />;
  const cotizacion = cotizaciones.find((c: any) => c.id === id);
  if (!cotizacion && id) return <div className="p-8 text-gray-500">Cotización no encontrada</div>;
  const handleGuardar = (data: any) => onGuardar(data, false, id);
  return <CotizacionEditor cotizacion={cotizacion} onGuardar={handleGuardar} {...props} />;
}

function CotizacionDetalleWrapper({ cotizaciones, ...props }: any) {
  const { id } = useParams();
  const navigate = useNavigate();
  if (!id || id === 'undefined' || id === 'null') return <Navigate to="/cotizaciones" replace />;
  const cotizacion = cotizaciones.find((c: any) => c.id === id);
  if (!cotizacion) return <div className="p-8 text-gray-500">Cotización no encontrada</div>;
  const currentCliente = props.clientes.find((cl: any) => cl.id === cotizacion.cliente_id);
  const pagos = props.obtenerPagosPorCotizacion(id);
  const saldoPendiente = props.calcularSaldoPendiente(id);
  return (
    <CotizacionDetalle
      cotizacion={cotizacion}
      todasLasCotizaciones={cotizaciones}
      cliente={currentCliente}
      pagos={pagos}
      saldoPendiente={saldoPendiente}
      onVerCotizacion={(vid) => navigate(`/cotizaciones/${vid}`)}
      {...props}
    />
  );
}

function PDFFullPageWrapper({ cotizaciones, ...props }: any) {
  const { id } = useParams();
  if (!id || id === 'undefined' || id === 'null') return <Navigate to="/cotizaciones" replace />;
  const cotizacion = cotizaciones.find((c: any) => c.id === id);
  if (!cotizacion) return <div>Cotización no encontrada</div>;
  const cliente = props.clientes.find((c: any) => c.id === cotizacion.cliente_id);
  return <PDFFullPageCompact cotizacion={cotizacion} cliente={cliente} {...props} />;
}
