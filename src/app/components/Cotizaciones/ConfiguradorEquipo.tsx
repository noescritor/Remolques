import React, { useState, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Check, AlertCircle, AlertTriangle, Loader2, RotateCcw, ChevronDown, ChevronUp, ChevronRight, Plus, Trash2 } from 'lucide-react';
import { Producto, ItemCotizacion } from '../../types';
import { supabase } from '../../utils/supabase/client';
import { BASE_URL } from '../../utils/api';
import { ScrollArea } from '../ui/scroll-area';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { formatearMoneda } from '../../utils/calculations';
import { obtenerConfiguracion } from '../../utils/configuracionEquipo';
import { 
  ResultadoCosteo, 
  AjusteManual, 
  validarAjusteIndividual, 
  textoConfianza, 
  traducirTipoPendiente 
} from '../../utils/costeo';
import {
  FilaSeleccionMixta,
  normalizarFilas,
  calcularSumaPiezas,
  calcularFaltantes,
  calcularMaxPiezasGrupo,
  siguienteCantidad,
  completarConEstaOpcion
} from '../../utils/seleccionMixta';

export interface ConfiguracionModelo {
  modelo: any;
  grupos: any[];
  opciones: any[];
}

interface ConfiguradorEquipoProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  producto: Producto | null;
  modeloId: string;
  itemInicial?: ItemCotizacion | null;
  onConfirm: (
    configuracion: any, 
    texto: string, 
    completado: boolean, 
    costoParcial: number,
    costeo: ResultadoCosteo | null
  ) => void;
}

interface AjusteFilaUI {
  id: string;
  concepto: string;
  cantidad: string;
  costo_unitario: string;
}

export function ConfiguradorEquipo({ open, onOpenChange, producto, modeloId, itemInicial, onConfirm }: ConfiguradorEquipoProps) {
  const [loadingConfig, setLoadingConfig] = useState(true);
  const [errorConfig, setErrorConfig] = useState<string | null>(null);
  const [datosModelo, setDatosModelo] = useState<ConfiguracionModelo | null>(null);
  const [configuracion, setConfiguracion] = useState<any>({ grupos: {} });
  const [resolviendo, setResolviendo] = useState(false);
  const [resultado, setResultado] = useState<any>(null);
  const [costeo, setCosteo] = useState<ResultadoCosteo | null>(null);
  const [costeando, setCosteando] = useState(false);
  const [calculoPendiente, setCalculoPendiente] = useState(false);
  const [errorCosteo, setErrorCosteo] = useState<string | null>(null);
  const [ajustesUI, setAjustesUI] = useState<AjusteFilaUI[]>([]);
  const [mostrarDesglose, setMostrarDesglose] = useState(false);
  const [seccionesExpandidas, setSeccionesExpandidas] = useState<Record<string, boolean>>({});
  const [mostrarAjustes, setMostrarAjustes] = useState(false);
  const [grupoActivo, setGrupoActivo] = useState<string | null>(null);
  
  const debounceRef = useRef<NodeJS.Timeout>();
  const currentReqRef = useRef<number>(0);

  useEffect(() => {
    if (open && modeloId) {
      cargarConfiguracion();
    } else {
      setDatosModelo(null);
      setResultado(null);
      setCosteo(null);
      setCosteando(false);
      setCalculoPendiente(false);
      setErrorCosteo(null);
      setAjustesUI([]);
      setMostrarDesglose(false);
      setSeccionesExpandidas({});
      setMostrarAjustes(false);
      setConfiguracion({ grupos: {} });
      setGrupoActivo(null);
      setErrorConfig(null);
    }
    return () => {
      if (debounceRef.current) clearTimeout(debounceRef.current);
    };
  }, [open, modeloId]);

  const cargarConfiguracion = async () => {
    setLoadingConfig(true);
    setErrorConfig(null);
    try {
      const { data: session } = await supabase.auth.getSession();
      const res = await fetch(`${BASE_URL}/modelos/${modeloId}/configuracion`, {
        headers: { Authorization: `Bearer ${session.session?.access_token}` }
      });
      if (res.ok) {
        const data: ConfiguracionModelo = await res.json();
        setDatosModelo(data);
        
        let initialConfig = { grupos: {} } as any;
        let initialAjustesUI: AjusteFilaUI[] = [];

        const cfgInicial = obtenerConfiguracion(itemInicial);
        if (cfgInicial && cfgInicial.grupos) {
          initialConfig = JSON.parse(JSON.stringify(cfgInicial));
          if (Array.isArray(initialConfig.ajustes)) {
            initialAjustesUI = initialConfig.ajustes.map((a: any, idx: number) => ({
              id: `ajuste_${Date.now()}_${idx}`,
              concepto: a.concepto || '',
              cantidad: a.cantidad != null ? String(a.cantidad) : '1',
              costo_unitario: a.costo_unitario != null ? String(a.costo_unitario) : '0'
            }));
          }
        } else {
          // Pre-llenar valores sugeridos solo si 40ft 2 ejes
          if (data.modelo.largo_ft === 40 && data.modelo.num_ejes === 2) {
            const sugeridos: Record<string, string> = {};
            if (data.opciones?.some((o: any) => o.grupo_id === data.grupos?.find((g: any) => g.clave === 'suspension')?.id && o.clave === 'fleet_master')) {
              sugeridos['suspension'] = 'fleet_master';
            }
            if (data.opciones?.some((o: any) => o.grupo_id === data.grupos?.find((g: any) => g.clave === 'eje')?.id && o.clave === 'fleet_master')) {
              sugeridos['eje'] = 'fleet_master';
            }
            if (data.opciones?.some((o: any) => o.grupo_id === data.grupos?.find((g: any) => g.clave === 'patin')?.id && o.clave === 'hj')) {
              sugeridos['patin'] = 'hj';
            }
            initialConfig.grupos = sugeridos;
          }
        }
        
        setConfiguracion(initialConfig);
        setAjustesUI(initialAjustesUI);
        
        const primerGrupo = data.grupos?.[0];
        if (primerGrupo) setGrupoActivo(primerGrupo.clave);

        const listaAjustesNumericos: AjusteManual[] = initialAjustesUI.map(a => ({
          concepto: a.concepto,
          cantidad: parseFloat(a.cantidad),
          costo_unitario: parseFloat(a.costo_unitario)
        }));
        ejecutarCalculos(initialConfig, listaAjustesNumericos);
      } else {
        setErrorConfig(`Error ${res.status}: ${res.statusText}`);
      }
    } catch (e: any) {
      setErrorConfig(e.message || "Error de red");
    } finally {
      setLoadingConfig(false);
    }
  };

  const ejecutarCalculos = async (config: any, listaAjustes: AjusteManual[]) => {
    setResolviendo(true);
    setCosteando(true);
    setErrorCosteo(null);
    const reqId = ++currentReqRef.current;
    
    try {
      const { data: session } = await supabase.auth.getSession();
      const token = session.session?.access_token;
      const headers = { 
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}` 
      };

      const pResolver = fetch(`${BASE_URL}/configuracion/resolver`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ modelo_id: modeloId, configuracion: config })
      }).then(async (res) => {
        if (reqId !== currentReqRef.current) return;
        if (res.ok) {
          const data = await res.json();
          setResultado(data);
        }
      }).catch(err => {
        console.error("Error al resolver:", err);
      }).finally(() => {
        if (reqId === currentReqRef.current) {
          setResolviendo(false);
        }
      });

      const ajustesValidos = (listaAjustes || []).filter(validarAjusteIndividual);
      const pCostear = fetch(`${BASE_URL}/configuracion/costear`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ modelo_id: modeloId, configuracion: config, ajustes: ajustesValidos })
      }).then(async (res) => {
        if (reqId !== currentReqRef.current) return;
        if (res.ok) {
          const data: ResultadoCosteo = await res.json();
          setCosteo(data);
          setErrorCosteo(null);
        } else {
          setCosteo(null);
          setErrorCosteo(`Costeo no disponible (${res.status})`);
        }
      }).catch(err => {
        if (reqId !== currentReqRef.current) return;
        console.error("Error al costear:", err);
        setCosteo(null);
        setErrorCosteo("Costeo no disponible");
      }).finally(() => {
        if (reqId === currentReqRef.current) {
          setCosteando(false);
        }
      });

      await Promise.allSettled([pResolver, pCostear]);
      if (reqId === currentReqRef.current) {
        setCalculoPendiente(false);
      }
    } catch (e) {
      console.error(e);
      if (reqId === currentReqRef.current) {
        setCosteo(null);
        setResolviendo(false);
        setCosteando(false);
        setCalculoPendiente(false);
      }
    }
  };

  const handleConfigChange = (newConfig: any, nuevosAjustesUI = ajustesUI) => {
    setConfiguracion(newConfig);
    setCalculoPendiente(true);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    const listaNumerica: AjusteManual[] = nuevosAjustesUI.map(a => ({
      concepto: a.concepto,
      cantidad: parseFloat(a.cantidad),
      costo_unitario: parseFloat(a.costo_unitario)
    }));
    debounceRef.current = setTimeout(() => ejecutarCalculos(newConfig, listaNumerica), 300);
  };

  const handleAjustesUIChange = (nuevosUI: AjusteFilaUI[]) => {
    setAjustesUI(nuevosUI);
    setCalculoPendiente(true);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    const listaNumerica: AjusteManual[] = nuevosUI.map(a => ({
      concepto: a.concepto,
      cantidad: parseFloat(a.cantidad),
      costo_unitario: parseFloat(a.costo_unitario)
    }));
    debounceRef.current = setTimeout(() => ejecutarCalculos(configuracion, listaNumerica), 300);
  };

  const agregarAjuste = () => {
    const nuevo: AjusteFilaUI = {
      id: `ajuste_${Date.now()}_${Math.random()}`,
      concepto: '',
      cantidad: '1',
      costo_unitario: '0'
    };
    handleAjustesUIChange([...ajustesUI, nuevo]);
  };

  const actualizarAjuste = (index: number, campo: keyof AjusteFilaUI, valor: string) => {
    const nuevos = [...ajustesUI];
    nuevos[index] = { ...nuevos[index], [campo]: valor };
    handleAjustesUIChange(nuevos);
  };

  const eliminarAjuste = (index: number) => {
    const nuevos = ajustesUI.filter((_, i) => i !== index);
    handleAjustesUIChange(nuevos);
  };

  const isMultipleLike = (g: any) => g.seleccion === 'multiple' || g.seleccion === 'multiple_con_cantidad' || g.seleccion === 'cantidad';

  const handleOptionSelect = (grupo: any, o: any, checked?: boolean) => {
    const newConfig = { ...configuracion };
    newConfig.grupos = { ...newConfig.grupos };
    
    if (isMultipleLike(grupo)) {
      const arr = Array.isArray(newConfig.grupos[grupo.clave]) ? [...newConfig.grupos[grupo.clave]] : [];
      if (!checked) {
        newConfig.grupos[grupo.clave] = arr.filter((x: any) => x.opcion !== o.clave);
      } else {
        arr.push({ opcion: o.clave, cantidad: 1 });
        newConfig.grupos[grupo.clave] = arr;
      }
    } else {
      if (grupo.seleccion === 'unica_con_cantidad' || grupo.seleccion === 'unica_con_medida') {
        const prev = newConfig.grupos[grupo.clave];
        newConfig.grupos[grupo.clave] = { 
          opcion: o.clave, 
          cantidad: typeof prev === 'object' ? prev.cantidad : undefined,
          marca: typeof prev === 'object' ? prev.marca : undefined,
          medida: typeof prev === 'object' ? prev.medida : undefined
        };
      } else {
        newConfig.grupos[grupo.clave] = o.clave;
      }
    }
    handleConfigChange(newConfig);
  };

  const handleObjProp = (grupoClave: string, isArray: boolean, opcionClave: string, field: string, value: any) => {
    const newConfig = { ...configuracion };
    newConfig.grupos = { ...newConfig.grupos };
    
    if (isArray) {
      let arr = Array.isArray(newConfig.grupos[grupoClave]) ? [...newConfig.grupos[grupoClave]] : [];
      const idx = arr.findIndex((x: any) => x.opcion === opcionClave);
      if (idx >= 0) {
        arr[idx] = { ...arr[idx], [field]: value };
        newConfig.grupos[grupoClave] = arr;
      }
    } else {
      const prev = newConfig.grupos[grupoClave];
      if (typeof prev === 'object') {
        newConfig.grupos[grupoClave] = { ...prev, [field]: value };
      } else {
        newConfig.grupos[grupoClave] = { opcion: prev, [field]: value };
      }
    }
    handleConfigChange(newConfig);
  };

  if (!open) return null;

  const gruposAplicables = datosModelo?.grupos || [];
  const grupoActual = gruposAplicables.find((g: any) => g.clave === grupoActivo);
  const opcionesActuales = datosModelo?.opciones?.filter((o: any) => o.grupo_id === grupoActual?.id) || [];

  const maxPiezas = grupoActual ? (grupoActual.max_piezas ?? calcularMaxPiezasGrupo(grupoActual, datosModelo?.modelo)) : undefined;
  const esGrupoConMaxPiezas = typeof maxPiezas === 'number' && maxPiezas > 0;

  const filasActuales = (esGrupoConMaxPiezas && grupoActual)
    ? normalizarFilas(configuracion.grupos[grupoActual.clave], maxPiezas)
    : [];
  const sumaPiezasActual = calcularSumaPiezas(filasActuales);
  const faltantesActual = esGrupoConMaxPiezas ? Math.max(0, maxPiezas - sumaPiezasActual) : 0;
  const excesoActual = esGrupoConMaxPiezas ? sumaPiezasActual > maxPiezas : false;

  const hayExcesoPiezas = gruposAplicables.some((g: any) => {
    const max = g.max_piezas ?? calcularMaxPiezasGrupo(g, datosModelo?.modelo);
    if (typeof max === 'number' && max > 0) {
      const sum = calcularSumaPiezas(normalizarFilas(configuracion.grupos[g.clave], max));
      return sum > max;
    }
    return false;
  });

  const isIncompleta = resultado && (!resultado.completo || resultado.secciones_pendientes?.length > 0 || resultado.sin_precio?.length > 0);
  const faltanObligatorios = gruposAplicables.some((g: any) => {
    const esObligatorio = g.seleccion?.startsWith('unica') || ['suspension', 'eje', 'patin', 'rines', 'llantas'].includes(g.clave);
    if (!esObligatorio) return false;
    const val = configuracion.grupos[g.clave];
    if (val === undefined || val === null) return true;
    if (Array.isArray(val)) return val.length === 0;
    if (typeof val === 'string') return val.trim() === '';
    if (typeof val === 'object') return !val.opcion;
    return false;
  });
  const disableConfirm = (resultado?.errores?.length > 0) || faltanObligatorios || hayExcesoPiezas;

  const handleActualizarFilasGrupo = (nuevasFilas: FilaSeleccionMixta[]) => {
    if (!grupoActual) return;
    const newConfig = {
      ...configuracion,
      grupos: {
        ...configuracion.grupos,
        [grupoActual.clave]: nuevasFilas
      }
    };
    handleConfigChange(newConfig);
  };

  const handleSeleccionarPrimeraOpcion = (opt: any) => {
    if (!grupoActual) return;
    const max = maxPiezas ?? 1;
    const defaultMarca = opt.marcas && opt.marcas.length > 0 ? opt.marcas[0] : undefined;
    const defaultMedida = opt.medidas && Object.keys(opt.medidas).length > 0 ? Object.keys(opt.medidas)[0] : undefined;
    const nuevaFila: FilaSeleccionMixta = {
      opcion: opt.clave,
      ...(defaultMarca ? { marca: defaultMarca } : {}),
      ...(defaultMedida ? { medida: defaultMedida } : {}),
      cantidad: opt.clave.startsWith('sin_') ? 1 : max
    };
    handleActualizarFilasGrupo([nuevaFila]);
  };

  const handleCambiarOpcionFila = (index: number, nuevaOpcionClave: string) => {
    if (!grupoActual) return;
    const optNueva = opcionesActuales.find((o: any) => o.clave === nuevaOpcionClave);
    const defaultMarca = optNueva?.marcas && optNueva.marcas.length > 0 ? optNueva.marcas[0] : undefined;
    const defaultMedida = optNueva?.medidas && Object.keys(optNueva.medidas).length > 0 ? Object.keys(optNueva.medidas)[0] : undefined;

    const nuevas = filasActuales.map((f, i) => {
      if (i !== index) return f;
      return {
        ...f,
        opcion: nuevaOpcionClave,
        marca: defaultMarca,
        medida: defaultMedida,
        cantidad: nuevaOpcionClave.startsWith('sin_') ? 1 : f.cantidad
      };
    });
    handleActualizarFilasGrupo(nuevas);
  };

  const handleCambiarMarcaFila = (index: number, marca: string) => {
    const nuevas = filasActuales.map((f, i) => (i === index ? { ...f, marca } : f));
    handleActualizarFilasGrupo(nuevas);
  };

  const handleCambiarMedidaFila = (index: number, medida: string) => {
    const nuevas = filasActuales.map((f, i) => (i === index ? { ...f, medida } : f));
    handleActualizarFilasGrupo(nuevas);
  };

  const handleActualizarCantidadFila = (index: number, cantidad: number) => {
    const cantValida = Math.max(1, Math.floor(cantidad));
    const nuevas = filasActuales.map((f, i) => (i === index ? { ...f, cantidad: cantValida } : f));
    handleActualizarFilasGrupo(nuevas);
  };

  const handleCompletarFila = (index: number) => {
    if (!maxPiezas) return;
    const nuevas = completarConEstaOpcion(filasActuales, index, maxPiezas);
    handleActualizarFilasGrupo(nuevas);
  };

  const handleEliminarFila = (index: number) => {
    const nuevas = filasActuales.filter((_, i) => i !== index);
    handleActualizarFilasGrupo(nuevas);
  };

  const handleAgregarCombinacion = () => {
    if (!grupoActual || !maxPiezas) return;
    const { cantidadSugerida, yaLlegoAlMaximo } = siguienteCantidad(maxPiezas, filasActuales);
    if (yaLlegoAlMaximo) return;

    const opcionesUsadas = new Set(filasActuales.map(f => f.opcion));
    const candidata = opcionesActuales.find((o: any) => !o.clave.startsWith('sin_') && !opcionesUsadas.has(o.clave))
      || opcionesActuales.find((o: any) => !o.clave.startsWith('sin_'))
      || opcionesActuales[0];

    if (!candidata) return;

    const defaultMarca = candidata.marcas && candidata.marcas.length > 0 ? candidata.marcas[0] : undefined;
    const defaultMedida = candidata.medidas && Object.keys(candidata.medidas).length > 0 ? Object.keys(candidata.medidas)[0] : undefined;

    const nuevaFila: FilaSeleccionMixta = {
      opcion: candidata.clave,
      ...(defaultMarca ? { marca: defaultMarca } : {}),
      ...(defaultMedida ? { medida: defaultMedida } : {}),
      cantidad: cantidadSugerida
    };

    handleActualizarFilasGrupo([...filasActuales, nuevaFila]);
  };

  const getPrecioRef = () => {
    if (!datosModelo) return 0;
    let sum = 0;
    Object.entries(configuracion.grupos).forEach(([gClave, val]: [string, any]) => {
      const grupo = datosModelo.grupos.find((g: any) => g.clave === gClave);
      if (!grupo) return;
      
      const procesarVal = (v: any) => {
        const optClave = typeof v === 'object' ? v.opcion : v;
        if (!optClave) return;
        const opt = datosModelo.opciones.find((o: any) => o.grupo_id === grupo.id && o.clave === optClave);
        if (opt) sum += (opt.precio_venta || 0) * (typeof v === 'object' && v.cantidad ? v.cantidad : 1);
      };
      
      if (Array.isArray(val)) val.forEach(procesarVal);
      else procesarVal(val);
    });
    return sum;
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[1100px] w-[95vw] h-[90vh] flex flex-col p-0">
        <DialogHeader className="px-6 py-4 border-b">
          <DialogTitle>Configurar Equipo</DialogTitle>
          <DialogDescription>
            {producto?.nombre} - {datosModelo?.modelo?.tipo} {datosModelo?.modelo?.largo_ft ? `${datosModelo.modelo.largo_ft}FT ` : ''}{datosModelo?.modelo?.num_ejes} EJES
          </DialogDescription>
        </DialogHeader>

        {loadingConfig ? (
          <div className="flex-1 flex items-center justify-center">
            <Loader2 className="w-8 h-8 animate-spin text-muted-foreground" />
          </div>
        ) : errorConfig ? (
          <div className="flex-1 flex flex-col items-center justify-center gap-4">
            <AlertCircle className="w-8 h-8 text-red-500" />
            <p className="text-red-500">{errorConfig}</p>
            <Button variant="outline" onClick={cargarConfiguracion}><RotateCcw className="w-4 h-4 mr-2" /> Reintentar</Button>
          </div>
        ) : (
          <div className="flex flex-1 flex-col md:flex-row overflow-y-auto md:overflow-hidden min-h-0">
            <div className="w-full md:w-64 shrink-0 max-h-36 md:max-h-none border-b md:border-b-0 md:border-r border-border bg-muted/20 flex flex-col">
              <ScrollArea className="flex-1">
                <div className="p-4 space-y-1">
                  {gruposAplicables.map((g: any) => {
                    const value = configuracion.grupos[g.clave];
                    const isMandatory = g.seleccion?.startsWith('unica') || ['suspension', 'eje', 'patin', 'rines', 'llantas'].includes(g.clave);
                    const hasValue = (() => {
                      if (value === undefined || value === null) return false;
                      if (Array.isArray(value)) {
                        return value.length > 0 && value.some((x: any) => x && (typeof x === 'string' ? x.trim() : x.opcion));
                      }
                      if (typeof value === 'object') return !!value.opcion;
                      if (typeof value === 'string') return value.trim() !== '';
                      return false;
                    })();
                    return (
                      <button
                        key={g.id}
                        onClick={() => setGrupoActivo(g.clave)}
                        className={`w-full text-left px-3 py-2 rounded-md text-sm transition-colors flex items-center justify-between
                          ${grupoActivo === g.clave ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-muted text-foreground'}
                        `}
                      >
                        <span>{g.nombre}</span>
                        {hasValue ? <Check className="w-4 h-4 text-green-500" /> : isMandatory ? <span className="w-2 h-2 rounded-full bg-red-500" /> : null}
                      </button>
                    );
                  })}
                </div>
              </ScrollArea>
            </div>

            <div className="md:flex-1 flex flex-col bg-background relative min-w-0 md:min-h-0">
              <ScrollArea className="h-[260px] shrink-0 md:h-auto md:shrink md:flex-1 md:min-h-0">
                <div className="p-6">
                  {esGrupoConMaxPiezas ? (
                    <div className="space-y-4">
                      {/* Encabezado del grupo con contador de piezas */}
                      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3 border-b border-border">
                        <div>
                          <h3 className="text-lg font-medium text-foreground">{grupoActual?.nombre}</h3>
                          <p className="text-xs text-muted-foreground">
                            {grupoActual?.descripcion || `Selección de piezas (máximo ${maxPiezas} para este modelo)`}
                          </p>
                        </div>
                        <div className="flex items-center gap-2">
                          <span
                            className={`inline-flex items-center px-3 py-1 rounded-full text-xs font-semibold border ${
                              sumaPiezasActual === maxPiezas
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-300 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800'
                                : excesoActual
                                ? 'bg-red-50 text-red-700 border-red-300 dark:bg-red-950/40 dark:text-red-300 dark:border-red-800'
                                : 'bg-amber-50 text-amber-700 border-amber-300 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800'
                            }`}
                          >
                            Piezas: {sumaPiezasActual} de {maxPiezas}
                          </span>
                        </div>
                      </div>

                      {/* Avisos contextuales */}
                      {excesoActual && (
                        <div className="p-2.5 rounded-md bg-red-50 dark:bg-red-950/30 border border-red-200 dark:border-red-900/50 text-red-700 dark:text-red-300 text-xs flex items-center gap-2">
                          <AlertCircle className="w-4 h-4 shrink-0" />
                          <span>
                            {grupoActual?.nombre.toLowerCase().startsWith('llanta') || grupoActual?.nombre.toLowerCase().startsWith('matraca') ? 'Las' : 'Los'}{' '}
                            {grupoActual?.nombre.toLowerCase()} suman {sumaPiezasActual} piezas y el máximo para este modelo es {maxPiezas}
                          </span>
                        </div>
                      )}
                      {!excesoActual && faltantesActual > 0 && sumaPiezasActual > 0 && (
                        <div className="p-2.5 rounded-md bg-amber-50 dark:bg-amber-950/30 border border-amber-200 dark:border-amber-900/50 text-amber-800 dark:text-amber-300 text-xs flex items-center gap-2">
                          <AlertTriangle className="w-4 h-4 shrink-0" />
                          <span>Faltan {faltantesActual} {grupoActual?.nombre.toLowerCase()} por definir</span>
                        </div>
                      )}

                      {/* Filas de combinaciones */}
                      {filasActuales.length === 0 ? (
                        <div className="p-6 text-center border border-dashed border-border rounded-lg bg-card/50 space-y-4">
                          <div className="space-y-1">
                            <h4 className="text-sm font-medium text-foreground">Sin opciones seleccionadas</h4>
                            <p className="text-xs text-muted-foreground">
                              Elige una opción para comenzar (se asignarán {maxPiezas} piezas automáticamente):
                            </p>
                          </div>
                          <div className="flex flex-wrap justify-center gap-2 max-w-lg mx-auto">
                            {opcionesActuales.map((opt: any) => (
                              <Button
                                key={opt.id}
                                type="button"
                                variant="outline"
                                size="sm"
                                className="text-xs"
                                onClick={() => handleSeleccionarPrimeraOpcion(opt)}
                              >
                                <Plus className="w-3.5 h-3.5 mr-1" />
                                {opt.nombre}
                              </Button>
                            ))}
                          </div>
                        </div>
                      ) : (
                        <div className="space-y-3">
                          {filasActuales.map((fila, idx) => {
                            const optActual = opcionesActuales.find((o: any) => o.clave === fila.opcion);
                            const tieneMarcas = optActual?.marcas && optActual.marcas.length > 0;
                            const tieneMedidas = optActual?.medidas && Object.keys(optActual.medidas).length > 0;

                            return (
                              <div
                                key={`${fila.opcion}_${idx}`}
                                className="p-3 sm:p-4 rounded-lg border border-border bg-card space-y-3 shadow-sm"
                              >
                                <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-3">
                                  {/* Opción */}
                                  <div className="flex-1 min-w-0">
                                    <label className="block text-xs font-medium text-muted-foreground mb-1">
                                      Opción
                                    </label>
                                    <Select
                                      value={fila.opcion}
                                      onValueChange={(val) => handleCambiarOpcionFila(idx, val)}
                                    >
                                      <SelectTrigger className="h-9">
                                        <SelectValue placeholder="Seleccionar opción..." />
                                      </SelectTrigger>
                                      <SelectContent>
                                        {opcionesActuales.map((opt: any) => (
                                          <SelectItem key={opt.id} value={opt.clave}>
                                            {opt.nombre}
                                          </SelectItem>
                                        ))}
                                      </SelectContent>
                                    </Select>
                                  </div>

                                  {/* Marca (si aplica) */}
                                  {tieneMarcas && (
                                    <div className="w-full sm:w-44">
                                      <label className="block text-xs font-medium text-muted-foreground mb-1">
                                        Marca <span className="text-destructive">*</span>
                                      </label>
                                      <Select
                                        value={fila.marca || ''}
                                        onValueChange={(val) => handleCambiarMarcaFila(idx, val)}
                                      >
                                        <SelectTrigger className="h-9 uppercase">
                                          <SelectValue placeholder="Elegir marca..." />
                                        </SelectTrigger>
                                        <SelectContent>
                                          {optActual.marcas.map((m: string) => (
                                            <SelectItem key={m} value={m} className="uppercase">
                                              {m}
                                            </SelectItem>
                                          ))}
                                        </SelectContent>
                                      </Select>
                                    </div>
                                  )}

                                  {/* Medida (si aplica) */}
                                  {tieneMedidas && (
                                    <div className="w-full sm:w-40">
                                      <label className="block text-xs font-medium text-muted-foreground mb-1">
                                        Medida
                                      </label>
                                      <Select
                                        value={fila.medida || ''}
                                        onValueChange={(val) => handleCambiarMedidaFila(idx, val)}
                                      >
                                        <SelectTrigger className="h-9">
                                          <SelectValue placeholder="Elegir medida..." />
                                        </SelectTrigger>
                                        <SelectContent>
                                          {Object.keys(optActual.medidas).map((m: string) => (
                                            <SelectItem key={m} value={m}>
                                              {m}
                                            </SelectItem>
                                          ))}
                                        </SelectContent>
                                      </Select>
                                    </div>
                                  )}

                                  {/* Cantidad con stepper */}
                                  <div className="w-full sm:w-36">
                                    <label className="block text-xs font-medium text-muted-foreground mb-1">
                                      Cantidad
                                    </label>
                                    <div className="flex items-center">
                                      <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        className="h-9 w-9 p-0 rounded-r-none border-r-0 shrink-0"
                                        onClick={() => handleActualizarCantidadFila(idx, Math.max(1, (fila.cantidad || 1) - 1))}
                                        disabled={fila.cantidad <= 1}
                                      >
                                        -
                                      </Button>
                                      <input
                                        type="number"
                                        min="1"
                                        className="h-9 w-16 text-center text-sm font-medium border border-input bg-background text-foreground focus:outline-none focus:ring-1 focus:ring-primary font-mono"
                                        value={fila.cantidad || ''}
                                        onChange={(e) => {
                                          const v = parseInt(e.target.value, 10);
                                          handleActualizarCantidadFila(idx, isNaN(v) ? 1 : v);
                                        }}
                                      />
                                      <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        className="h-9 w-9 p-0 rounded-l-none border-l-0 shrink-0"
                                        onClick={() => handleActualizarCantidadFila(idx, (fila.cantidad || 0) + 1)}
                                      >
                                        +
                                      </Button>
                                    </div>
                                  </div>

                                  {/* Acciones de la fila */}
                                  <div className="flex items-center gap-2 pt-1 sm:pt-0">
                                    {faltantesActual > 0 && !fila.opcion.startsWith('sin_') && (
                                      <Button
                                        type="button"
                                        variant="outline"
                                        size="sm"
                                        className="h-9 text-xs whitespace-nowrap"
                                        onClick={() => handleCompletarFila(idx)}
                                        title={`Asignar ${fila.cantidad + faltantesActual} piezas a esta opción`}
                                      >
                                        Completar con esta opción
                                      </Button>
                                    )}
                                    <Button
                                      type="button"
                                      variant="ghost"
                                      size="sm"
                                      className="h-9 w-9 p-0 text-muted-foreground hover:text-destructive shrink-0"
                                      onClick={() => handleEliminarFila(idx)}
                                      title="Quitar combinación"
                                    >
                                      <Trash2 className="w-4 h-4" />
                                    </Button>
                                  </div>
                                </div>
                              </div>
                            );
                          })}

                          {/* Botón agregar otra combinación */}
                          <div className="pt-2 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3">
                            <Button
                              type="button"
                              variant="outline"
                              size="sm"
                              className="h-9 text-xs flex items-center gap-1.5"
                              disabled={faltantesActual <= 0}
                              onClick={handleAgregarCombinacion}
                            >
                              <Plus className="w-4 h-4" /> Agregar otra combinación
                            </Button>

                            {faltantesActual <= 0 && sumaPiezasActual >= maxPiezas && (
                              <span className="text-xs text-muted-foreground">
                                Ya llegaste al máximo de {maxPiezas} piezas; reduce otra fila para agregar.
                              </span>
                            )}
                          </div>
                        </div>
                      )}
                    </div>
                  ) : (
                    <div>
                      <h3 className="text-lg font-medium mb-4 text-foreground">{grupoActual?.nombre}</h3>
                      <div className="grid gap-4 grid-cols-[repeat(auto-fill,minmax(min(100%,240px),1fr))]">
                        {opcionesActuales.map((o: any) => {
                          const value = configuracion.grupos[grupoActual?.clave || ''];
                          const isMultiple = isMultipleLike(grupoActual);
                          
                          let isSelected = false;
                          let objVal: any = null;
                          
                          if (isMultiple) {
                            const arr = Array.isArray(value) ? value : [];
                            objVal = arr.find((x: any) => x.opcion === o.clave);
                            isSelected = !!objVal;
                          } else {
                            isSelected = typeof value === 'object' ? value?.opcion === o.clave : value === o.clave;
                            objVal = typeof value === 'object' ? value : null;
                          }
                          
                          const isSugerida = datosModelo?.modelo.largo_ft === 40 && datosModelo?.modelo.num_ejes === 2 && 
                            ['fleet_master', 'hj'].includes(o.clave) && ['eje','suspension','patin'].includes(grupoActual?.clave || '');
                          
                          return (
                            <div key={o.id} className={`p-4 border rounded-md transition-colors relative ${isSelected ? 'border-primary bg-primary/5' : 'border-border bg-card'}`}>
                              <div 
                                className={`flex justify-between items-start mb-2 cursor-pointer ${!o.activo ? 'opacity-50 pointer-events-none' : ''}`}
                                onClick={() => handleOptionSelect(grupoActual, o, !isSelected)}
                              >
                                <span className="font-medium text-foreground flex items-center gap-2">
                                  {isMultiple && <input type="checkbox" checked={isSelected} readOnly />}
                                  {o.nombre}
                                </span>
                                {isSelected && !isMultiple && <Check className="w-4 h-4 text-primary" />}
                              </div>
                              
                              <div className="flex gap-2 flex-wrap mb-2">
                                {isSugerida && <Badge variant="secondary" className="text-[10px]">Sugerida</Badge>}
                                {!o.tiene_receta && <Badge variant="outline" className="text-[10px] text-muted-foreground">Sin receta</Badge>}
                              </div>
                              
                              {isSelected && (grupoActual?.seleccion.includes('con_cantidad') || grupoActual?.seleccion === 'cantidad') && (
                                <div className="mt-3 p-3 bg-background border rounded-md">
                                  <label className="block text-xs font-medium text-muted-foreground mb-1">Cantidad</label>
                                  <input 
                                    type="number" 
                                    className="w-full px-2 py-1 text-sm rounded-md border"
                                    value={objVal?.cantidad || ''}
                                    placeholder={(datosModelo?.modelo?.num_ejes * 4).toString()}
                                    onChange={(e) => handleObjProp(grupoActual!.clave, isMultiple, o.clave, 'cantidad', parseInt(e.target.value))}
                                  />
                                </div>
                              )}

                              {isSelected && grupoActual?.seleccion === 'unica_con_medida' && o.medidas && Object.keys(o.medidas).length > 0 && (
                                <div className="mt-3 p-3 bg-background border rounded-md">
                                  <label className="block text-xs font-medium text-muted-foreground mb-1">Medida</label>
                                  <Select value={objVal?.medida || ''} onValueChange={(val) => handleObjProp(grupoActual!.clave, false, o.clave, 'medida', val)}>
                                    <SelectTrigger className="h-8"><SelectValue placeholder="Elegir medida..." /></SelectTrigger>
                                    <SelectContent>
                                      {Object.keys(o.medidas).map((m: string) => <SelectItem key={m} value={m}>{m}</SelectItem>)}
                                    </SelectContent>
                                  </Select>
                                </div>
                              )}

                              {isSelected && grupoActual?.clave === 'rines' && o.marcas && o.marcas.length > 0 && (
                                <div className="mt-3 p-3 bg-background border rounded-md">
                                  <label className="block text-xs font-medium text-muted-foreground mb-1">Marca (Obligatoria)</label>
                                  <Select value={objVal?.marca || ''} onValueChange={(val) => handleObjProp(grupoActual!.clave, false, o.clave, 'marca', val)}>
                                    <SelectTrigger className="h-8 uppercase"><SelectValue placeholder="Elegir marca..." /></SelectTrigger>
                                    <SelectContent>
                                      {o.marcas.map((m: string) => <SelectItem key={m} value={m} className="uppercase">{m}</SelectItem>)}
                                    </SelectContent>
                                  </Select>
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    </div>
                  )}
                </div>
              </ScrollArea>

              <div className="border-t border-border bg-card p-3 sm:p-4 max-h-[50vh] overflow-y-auto shrink-0">
                <div className="flex flex-col lg:flex-row gap-4">
                  <div className="flex-1 min-w-0 space-y-3">
                    <div>
                      <h4 className="text-sm font-medium mb-1 text-foreground">Así queda tu equipo:</h4>
                      <p className="text-sm text-muted-foreground uppercase leading-relaxed">
                        {resultado?.texto_especificacion || <span className="opacity-50">Seleccionando configuración...</span>}
                      </p>
                    </div>

                    <div className="text-xs text-muted-foreground flex items-center gap-1.5 pt-1">
                      <span>Referencia de tarifario:</span>
                      <span className="font-medium text-foreground">{formatearMoneda(getPrecioRef())}</span>
                    </div>

                    <div aria-live="polite" className="space-y-1.5 pt-1">
                      {(() => {
                        const faltantesRegex = /^Falta elegir una opci[oó]n para el grupo obligatorio:\s*(.+)$/i;
                        const errFaltantes = (resultado?.errores || []).map((e: string) => e.match(faltantesRegex)?.[1]).filter(Boolean);
                        const otrosErrores = (resultado?.errores || []).filter((e: string) => !faltantesRegex.test(e));
                        return (
                          <>
                            {errFaltantes.length > 0 && (
                              <div className="text-xs text-muted-foreground flex items-center gap-1.5">
                                <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                                <span>Faltan {errFaltantes.length} grupos por elegir: {errFaltantes.join(', ')}</span>
                              </div>
                            )}
                            {otrosErrores.map((err: string, i: number) => (
                              <div key={`err-${i}`} className="text-xs text-destructive flex items-center gap-1.5">
                                <AlertCircle className="w-3.5 h-3.5 shrink-0" />
                                <span>{err}</span>
                              </div>
                            ))}
                          </>
                        );
                      })()}
                      {resultado?.advertencias?.map((adv: string, i: number) => (
                        <div key={`adv-${i}`} className="text-xs text-amber-600 dark:text-amber-400 flex items-center gap-1.5">
                          <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
                          <span>{adv}</span>
                        </div>
                      ))}
                      {isIncompleta && (
                        <div className="text-xs text-orange-500 dark:text-orange-400 flex items-center gap-1.5">
                          <AlertCircle className="w-3.5 h-3.5 shrink-0" /> 
                          <span>Receta incompleta: {resultado?.secciones_pendientes?.length ? 'faltan secciones de despiece' : 'opción sin receta o materiales sin precio'}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  <div className="w-full lg:w-[380px] shrink-0 p-3 sm:p-4 bg-muted/40 border border-border rounded-lg space-y-3">
                    <div>
                      <div className="flex items-center justify-between gap-2 mb-1">
                        <span className="text-xs font-semibold uppercase tracking-wider text-muted-foreground">Precio Sugerido</span>
                        <div className="flex items-center gap-2">
                          {(costeando || calculoPendiente) && (
                            <span className="text-[11px] text-muted-foreground flex items-center gap-1 animate-pulse">
                              <Loader2 className="w-3 h-3 animate-spin" /> calculando...
                            </span>
                          )}
                          {costeo && (
                            <span className={`inline-flex items-center px-2 py-0.5 rounded-full text-[11px] font-medium border ${
                              costeo.confianza === 'completa'
                                ? 'bg-emerald-50 text-emerald-700 border-emerald-300 dark:bg-emerald-950/40 dark:text-emerald-300 dark:border-emerald-800'
                                : costeo.confianza === 'estimada'
                                ? 'bg-amber-50 text-amber-700 border-amber-300 dark:bg-amber-950/40 dark:text-amber-300 dark:border-amber-800'
                                : 'bg-muted text-muted-foreground border-border'
                            }`}>
                              {textoConfianza(costeo.confianza)}
                            </span>
                          )}
                        </div>
                      </div>

                      <div className="min-h-[2rem] flex items-center">
                        {costeo?.precio_sugerido !== null && costeo?.precio_sugerido !== undefined ? (
                          <span className="text-2xl font-bold tracking-tight text-foreground">
                            {formatearMoneda(costeo.precio_sugerido)}
                          </span>
                        ) : (
                          <span className="text-sm font-medium text-muted-foreground italic">
                            {costeo?.costo === null || costeo?.costo === undefined
                              ? (errorCosteo || 'Este modelo todavía no tiene costos cargados')
                              : (costeo?.ganancia === null ? 'Falta definir la ganancia' : 'Sin costeo para este modelo')}
                          </span>
                        )}
                      </div>

                      {costeo?.costo !== null && costeo?.costo !== undefined && (
                        <div className="mt-2 pt-2 border-t border-border/50 flex flex-wrap items-center justify-between text-xs gap-x-3 gap-y-1 text-muted-foreground">
                          <div>
                            <span>Costo: </span>
                            <span className="font-semibold text-foreground">{formatearMoneda(costeo.costo)}</span>
                          </div>
                          {costeo.ganancia !== null && costeo.ganancia !== undefined && costeo.precio_sugerido !== null && (
                            <div>
                              <span>Margen: </span>
                              <span className="font-semibold text-foreground">
                                {costeo.margen_sobre_precio !== null
                                  ? `${costeo.margen_sobre_precio.toFixed(1)}%`
                                  : `${((costeo.ganancia / costeo.precio_sugerido) * 100).toFixed(1)}%`} ({formatearMoneda(costeo.ganancia)})
                              </span>
                            </div>
                          )}
                        </div>
                      )}
                    </div>

                    {costeo?.pendientes && costeo.pendientes.length > 0 && (
                      <div className="text-xs bg-amber-50 dark:bg-amber-950/30 text-amber-800 dark:text-amber-200 border border-amber-200 dark:border-amber-900/50 rounded p-2 space-y-1">
                        <div className="font-medium flex items-center gap-1.5">
                          <AlertTriangle className="w-3.5 h-3.5 shrink-0 text-amber-600 dark:text-amber-400" />
                          <span>Datos pendientes ({costeo.pendientes.length}):</span>
                        </div>
                        <ul className="list-disc list-inside space-y-0.5 text-[11px] pl-1">
                          {costeo.pendientes.map((p, idx) => (
                            <li key={idx}>
                              <span className="font-semibold">{traducirTipoPendiente(p.tipo)}:</span> {p.detalle}
                            </li>
                          ))}
                        </ul>
                      </div>
                    )}

                    <div className="flex items-center gap-2 pt-1 border-t border-border/50">
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="h-7 px-2 text-xs text-foreground flex items-center gap-1"
                        onClick={() => setMostrarDesglose(!mostrarDesglose)}
                      >
                        {mostrarDesglose ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                        {mostrarDesglose ? 'Ocultar desglose' : 'Ver desglose'}
                      </Button>
                      <Button
                        type="button"
                        variant="ghost"
                        size="sm"
                        className="h-7 px-2 text-xs text-foreground flex items-center gap-1"
                        onClick={() => setMostrarAjustes(!mostrarAjustes)}
                      >
                        {mostrarAjustes ? <ChevronUp className="w-3.5 h-3.5" /> : <ChevronDown className="w-3.5 h-3.5" />}
                        Ajustes al costo {ajustesUI.length > 0 && `(${ajustesUI.length})`}
                      </Button>
                    </div>
                  </div>
                </div>

                {mostrarDesglose && (
                  <div className="mt-4 p-3 bg-muted/20 border border-border rounded-lg space-y-3">
                    <div className="flex items-center justify-between border-b border-border pb-2">
                      <h5 className="text-xs font-semibold uppercase tracking-wider text-foreground">
                        Desglose de Costos
                      </h5>
                      <span className="text-xs text-muted-foreground font-mono">
                        Total: {formatearMoneda(costeo?.costo || 0)}
                      </span>
                    </div>

                    <div className="space-y-2">
                      {([
                        { key: 'acero', titulo: 'Acero', total: costeo?.secciones?.acero?.total || 0, lineas: costeo?.secciones?.acero?.lineas || [] },
                        { key: 'kits_fijos', titulo: 'Kits y consumibles', total: costeo?.secciones?.kits_fijos?.total || 0, lineas: costeo?.secciones?.kits_fijos?.lineas || [] },
                        { key: 'opciones', titulo: 'Opciones elegidas', total: costeo?.secciones?.opciones?.total || 0, lineas: costeo?.secciones?.opciones?.lineas || [] },
                        { key: 'mano_obra', titulo: 'Mano de obra', total: costeo?.secciones?.mano_obra?.total || 0, lineas: costeo?.secciones?.mano_obra?.lineas || [] },
                        { key: 'ajustes', titulo: 'Ajustes', total: costeo?.secciones?.ajustes?.total || 0, lineas: costeo?.secciones?.ajustes?.lineas || [] },
                      ] as const).map(sec => {
                        const expandida = !!seccionesExpandidas[sec.key];
                        return (
                          <div key={sec.key} className="border border-border rounded-md bg-card overflow-hidden">
                            <button
                              type="button"
                              onClick={() => setSeccionesExpandidas(prev => ({ ...prev, [sec.key]: !prev[sec.key] }))}
                              className="w-full px-3 py-2 flex items-center justify-between text-xs font-medium hover:bg-muted/50 transition-colors text-left"
                            >
                              <div className="flex items-center gap-1.5 text-foreground">
                                {expandida ? <ChevronDown className="w-3.5 h-3.5 text-muted-foreground" /> : <ChevronRight className="w-3.5 h-3.5 text-muted-foreground" />}
                                <span>{sec.titulo}</span>
                                <span className="text-[11px] text-muted-foreground font-normal">({sec.lineas.length} {sec.lineas.length === 1 ? 'línea' : 'líneas'})</span>
                              </div>
                              <span className="font-semibold text-foreground font-mono">{formatearMoneda(sec.total)}</span>
                            </button>
                            {expandida && (
                              <div className="border-t border-border bg-background/50 p-2">
                                {sec.lineas.length === 0 ? (
                                  <p className="text-xs text-muted-foreground italic px-2 py-1">Sin conceptos registrados</p>
                                ) : (
                                  <div className="max-h-44 overflow-y-auto pr-1">
                                    <table className="w-full text-[11px] text-left">
                                      <thead>
                                        <tr className="border-b border-border/60 text-muted-foreground">
                                          <th className="pb-1 font-medium">Concepto</th>
                                          <th className="pb-1 font-medium text-right pr-2">Cant.</th>
                                          <th className="pb-1 font-medium text-right pr-2">Costo U.</th>
                                          <th className="pb-1 font-medium text-right">Total</th>
                                        </tr>
                                      </thead>
                                      <tbody className="divide-y divide-border/30">
                                        {sec.lineas.map((linea, lIdx) => (
                                          <tr key={lIdx} className="hover:bg-muted/40">
                                            <td className="py-1 text-foreground pr-2 leading-tight">{linea.concepto}</td>
                                            <td className="py-1 text-muted-foreground text-right pr-2 font-mono">{linea.cantidad}</td>
                                            <td className="py-1 text-muted-foreground text-right pr-2 font-mono">{formatearMoneda(linea.costo_unitario)}</td>
                                            <td className="py-1 text-foreground text-right font-medium font-mono">{formatearMoneda(linea.importe ?? (linea.cantidad * linea.costo_unitario))}</td>
                                          </tr>
                                        ))}
                                      </tbody>
                                    </table>
                                  </div>
                                )}
                              </div>
                            )}
                          </div>
                        );
                      })}
                    </div>
                  </div>
                )}

                {mostrarAjustes && (
                  <div className="mt-4 p-3 bg-muted/20 border border-border rounded-lg space-y-3">
                    <div className="flex items-center justify-between border-b border-border pb-2">
                      <div>
                        <h5 className="text-xs font-semibold uppercase tracking-wider text-foreground">
                          Ajustes al Costo
                        </h5>
                        <p className="text-[11px] text-muted-foreground">
                          Agrega conceptos adicionales o deducciones al costo del equipo.
                        </p>
                      </div>
                      <Button
                        type="button"
                        variant="outline"
                        size="sm"
                        className="h-7 text-xs flex items-center gap-1"
                        onClick={agregarAjuste}
                      >
                        <Plus className="w-3.5 h-3.5" /> Agregar ajuste
                      </Button>
                    </div>

                    {ajustesUI.length === 0 ? (
                      <div className="text-xs text-muted-foreground italic py-2 text-center bg-card rounded border border-dashed border-border">
                        No hay ajustes manuales. Haz clic en "Agregar ajuste" para añadir costos o deducciones.
                      </div>
                    ) : (
                      <div className="space-y-2">
                        {ajustesUI.map((ajuste, index) => {
                          const cantNum = parseFloat(ajuste.cantidad);
                          const costoNum = parseFloat(ajuste.costo_unitario);
                          const esValido = validarAjusteIndividual({
                            concepto: ajuste.concepto,
                            cantidad: cantNum,
                            costo_unitario: costoNum
                          });
                          const rowTotal = (!isNaN(cantNum) && !isNaN(costoNum)) ? cantNum * costoNum : 0;

                          return (
                            <div
                              key={ajuste.id || index}
                              className={`p-2 rounded-md bg-card border flex flex-col sm:flex-row items-stretch sm:items-center gap-2 ${
                                !esValido ? 'border-destructive dark:border-red-500' : 'border-border'
                              }`}
                            >
                              <div className="flex-1 min-w-0">
                                <input
                                  type="text"
                                  placeholder="Concepto (ej. Pintura especial)"
                                  value={ajuste.concepto}
                                  onChange={(e) => actualizarAjuste(index, 'concepto', e.target.value)}
                                  className={`w-full text-xs px-2.5 py-1.5 rounded bg-background border ${
                                    !ajuste.concepto?.trim() ? 'border-destructive focus:ring-destructive' : 'border-input'
                                  } focus:outline-none focus:ring-1`}
                                />
                              </div>
                              <div className="flex items-center gap-2">
                                <div className="w-20">
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    placeholder="Cant."
                                    value={ajuste.cantidad}
                                    onChange={(e) => actualizarAjuste(index, 'cantidad', e.target.value)}
                                    className={`w-full text-xs px-2 py-1.5 rounded bg-background border text-right font-mono ${
                                      isNaN(cantNum) || cantNum <= 0 ? 'border-destructive focus:ring-destructive' : 'border-input'
                                    } focus:outline-none focus:ring-1`}
                                  />
                                </div>
                                <div className="w-28">
                                  <input
                                    type="text"
                                    inputMode="decimal"
                                    placeholder="Costo U. ($)"
                                    value={ajuste.costo_unitario}
                                    onChange={(e) => actualizarAjuste(index, 'costo_unitario', e.target.value)}
                                    className={`w-full text-xs px-2 py-1.5 rounded bg-background border text-right font-mono ${
                                      isNaN(costoNum) && ajuste.costo_unitario !== '-' ? 'border-destructive focus:ring-destructive' : 'border-input'
                                    } focus:outline-none focus:ring-1`}
                                  />
                                </div>
                                <div className="w-24 text-right font-mono text-xs font-medium text-foreground pr-1">
                                  {formatearMoneda(rowTotal)}
                                </div>
                                <Button
                                  type="button"
                                  variant="ghost"
                                  size="sm"
                                  className="h-7 w-7 p-0 text-muted-foreground hover:text-destructive shrink-0"
                                  onClick={() => eliminarAjuste(index)}
                                  title="Eliminar ajuste"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </Button>
                              </div>
                              {!esValido && (
                                <div className="text-[11px] text-destructive flex items-center gap-1 sm:hidden">
                                  <AlertCircle className="w-3 h-3" /> Requiere concepto, cantidad &gt; 0 y costo numérico
                                </div>
                              )}
                            </div>
                          );
                        })}
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}

        <DialogFooter className="px-4 sm:px-6 py-3 sm:py-4 border-t gap-2 flex-col-reverse sm:flex-row">
          <Button variant="outline" onClick={() => onOpenChange(false)}>Cancelar</Button>
          <Button 
            disabled={loadingConfig || resolviendo || costeando || calculoPendiente || disableConfirm || errorConfig !== null} 
            onClick={() => {
              const ajustesValidos: AjusteManual[] = ajustesUI
                .map(a => ({
                  concepto: a.concepto.trim(),
                  cantidad: parseFloat(a.cantidad),
                  costo_unitario: parseFloat(a.costo_unitario)
                }))
                .filter(validarAjusteIndividual);

              const cfgToSave = {
                modelo_id: modeloId,
                grupos: configuracion.grupos,
                ajustes: ajustesValidos,
                texto_especificacion: resultado?.texto_especificacion || '',
                resumen_lineas: resultado?.resumen_lineas || [],
                resuelta: !resultado?.errores?.length && !faltanObligatorios && !hayExcesoPiezas,
                completo: resultado?.completo || false,
                resuelto_en: new Date().toISOString()
              };
              onConfirm(
                cfgToSave, 
                resultado?.texto_especificacion || '', 
                !isIncompleta,
                resultado?.costo_parcial || 0,
                costeo
              );
              onOpenChange(false);
            }}
          >
            {(resolviendo || costeando || calculoPendiente) ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : null}
            {itemInicial ? 'Guardar Cambios' : 'Agregar a la cotización'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
