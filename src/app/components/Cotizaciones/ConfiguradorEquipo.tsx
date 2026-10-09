import React, { useState, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import { Button } from '../ui/button';
import { Check, AlertCircle, AlertTriangle, Loader2, RotateCcw } from 'lucide-react';
import { Producto, ItemCotizacion } from '../../types';
import { supabase } from '../../utils/supabase/client';
import { BASE_URL } from '../../utils/api';
import { ScrollArea } from '../ui/scroll-area';
import { Badge } from '../ui/badge';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { formatearMoneda } from '../../utils/calculations';

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
  onConfirm: (configuracion: any, texto: string, completado: boolean, costoParcial: number) => void;
}

export function ConfiguradorEquipo({ open, onOpenChange, producto, modeloId, itemInicial, onConfirm }: ConfiguradorEquipoProps) {
  const [loadingConfig, setLoadingConfig] = useState(true);
  const [errorConfig, setErrorConfig] = useState<string | null>(null);
  const [datosModelo, setDatosModelo] = useState<ConfiguracionModelo | null>(null);
  const [configuracion, setConfiguracion] = useState<any>({ grupos: {} });
  const [resolviendo, setResolviendo] = useState(false);
  const [resultado, setResultado] = useState<any>(null);
  const [grupoActivo, setGrupoActivo] = useState<string | null>(null);
  
  const debounceRef = useRef<NodeJS.Timeout>();
  const currentReqRef = useRef<number>(0);

  useEffect(() => {
    if (open && modeloId) {
      cargarConfiguracion();
    } else {
      setDatosModelo(null);
      setResultado(null);
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
        
        if (itemInicial?.configuracion && itemInicial.configuracion.grupos) {
          initialConfig = JSON.parse(JSON.stringify(itemInicial.configuracion));
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
        
        const primerGrupo = data.grupos?.[0];
        if (primerGrupo) setGrupoActivo(primerGrupo.clave);

        resolver(initialConfig);
      } else {
        setErrorConfig(`Error ${res.status}: ${res.statusText}`);
      }
    } catch (e: any) {
      setErrorConfig(e.message || "Error de red");
    } finally {
      setLoadingConfig(false);
    }
  };

  const resolver = async (config: any) => {
    setResolviendo(true);
    const reqId = ++currentReqRef.current;
    
    try {
      const { data: session } = await supabase.auth.getSession();
      const res = await fetch(`${BASE_URL}/configuracion/resolver`, {
        method: 'POST',
        headers: { 
          'Content-Type': 'application/json',
          Authorization: `Bearer ${session.session?.access_token}` 
        },
        body: JSON.stringify({ modelo_id: modeloId, configuracion: config })
      });
      
      if (reqId !== currentReqRef.current) return; // ignore stale response

      if (res.ok) {
        const data = await res.json();
        setResultado(data);
      }
    } catch (e) {
      console.error(e);
    } finally {
      if (reqId === currentReqRef.current) {
        setResolviendo(false);
      }
    }
  };

  const handleConfigChange = (newConfig: any) => {
    setConfiguracion(newConfig);
    if (debounceRef.current) clearTimeout(debounceRef.current);
    debounceRef.current = setTimeout(() => resolver(newConfig), 300);
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

  const isIncompleta = resultado && (!resultado.completo || resultado.secciones_pendientes?.length > 0 || resultado.sin_precio?.length > 0);
  const faltanObligatorios = gruposAplicables.some((g: any) => g.seleccion.startsWith('unica') && !configuracion.grupos[g.clave]);
  const disableConfirm = (resultado?.errores?.length > 0) || faltanObligatorios;

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
      <DialogContent className="max-w-5xl h-[85vh] flex flex-col p-0">
        <DialogHeader className="px-6 py-4 border-b">
          <DialogTitle>Configurar Equipo</DialogTitle>
          <DialogDescription>
            {producto?.nombre} - {datosModelo?.modelo?.tipo} {datosModelo?.modelo?.largo_ft}FT {datosModelo?.modelo?.num_ejes} EJES
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
          <div className="flex flex-1 overflow-hidden">
            <div className="w-64 border-r border-border bg-muted/20 flex flex-col">
              <ScrollArea className="flex-1">
                <div className="p-4 space-y-1">
                  {gruposAplicables.map((g: any) => {
                    const value = configuracion.grupos[g.clave];
                    const hasValue = Array.isArray(value) ? value.length > 0 : !!value;
                    const isMandatory = g.seleccion.startsWith('unica');
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

            <div className="flex-1 flex flex-col bg-background relative">
              <ScrollArea className="flex-1">
                <div className="p-6">
                  <h3 className="text-lg font-medium mb-4 text-foreground">{grupoActual?.nombre}</h3>
                  <div className="grid grid-cols-2 gap-4">
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

                          {isSelected && grupoActual?.seleccion === 'unica_con_medida' && o.medidas && o.medidas.length > 0 && (
                            <div className="mt-3 p-3 bg-background border rounded-md">
                              <label className="block text-xs font-medium text-muted-foreground mb-1">Medida</label>
                              <Select value={objVal?.medida || ''} onValueChange={(val) => handleObjProp(grupoActual!.clave, false, o.clave, 'medida', val)}>
                                <SelectTrigger className="h-8"><SelectValue placeholder="Elegir medida..." /></SelectTrigger>
                                <SelectContent>
                                  {o.medidas.map((m: string) => <SelectItem key={m} value={m}>{m}</SelectItem>)}
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
              </ScrollArea>

              <div className="border-t border-border bg-card p-4 min-h-[160px]">
                <div className="flex gap-4">
                  <div className="flex-1">
                    <h4 className="text-sm font-medium mb-2 text-foreground">Así queda tu equipo:</h4>
                    <p className="text-sm text-muted-foreground uppercase leading-relaxed">
                      {resultado?.texto_especificacion || <span className="opacity-50">Seleccionando configuración...</span>}
                    </p>
                  </div>
                  <div className="w-64 space-y-3">
                    <div className="p-3 bg-muted/50 rounded-md">
                      <div className="text-xs text-muted-foreground">Referencia de tarifario</div>
                      <div className="font-medium text-foreground">{formatearMoneda(getPrecioRef())}</div>
                    </div>
                    <div className="p-3 bg-muted/50 rounded-md">
                      <div className="text-xs text-muted-foreground">Costo parcial de materiales</div>
                      <div className="font-medium text-foreground">{formatearMoneda(resultado?.costo_parcial || 0)}</div>
                    </div>
                  </div>
                </div>

                <div aria-live="polite" className="mt-4 space-y-2">
                  {resultado?.errores?.map((err: string, i: number) => (
                    <div key={`err-${i}`} className="text-sm text-red-500 flex items-center gap-2">
                      <AlertCircle className="w-4 h-4" /> {err}
                    </div>
                  ))}
                  {resultado?.advertencias?.map((adv: string, i: number) => (
                    <div key={`adv-${i}`} className="text-sm text-yellow-600 flex items-center gap-2">
                      <AlertTriangle className="w-4 h-4" /> {adv}
                    </div>
                  ))}
                  {isIncompleta && (
                    <div className="text-sm text-orange-500 flex items-center gap-2">
                      <AlertCircle className="w-4 h-4" /> 
                      Receta incompleta: {resultado?.secciones_pendientes?.length ? 'faltan secciones de despiece' : 'opción sin receta o materiales sin precio'}
                    </div>
                  )}
                </div>
              </div>
            </div>
          </div>
        )}

        <DialogFooter className="px-6 py-4 border-t">
          <Button variant="outline" onClick={() => onOpenChange(false)}>Cancelar</Button>
          <Button 
            disabled={loadingConfig || resolviendo || disableConfirm || errorConfig !== null} 
            onClick={() => {
              const cfgToSave = {
                modelo_id: modeloId,
                grupos: configuracion.grupos,
                texto_especificacion: resultado?.texto_especificacion || '',
                resumen_lineas: resultado?.resumen_lineas || [],
                resuelta: !resultado?.errores?.length && !faltanObligatorios,
                completo: resultado?.completo || false,
                resuelto_en: new Date().toISOString()
              };
              onConfirm(
                cfgToSave, 
                resultado?.texto_especificacion || '', 
                !isIncompleta,
                resultado?.costo_parcial || 0
              );
              onOpenChange(false);
            }}
          >
            {resolviendo ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : null}
            {itemInicial ? 'Guardar Cambios' : 'Agregar a la cotización'}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
