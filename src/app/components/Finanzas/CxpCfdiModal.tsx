import React, { useState, useRef } from 'react';
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogFooter,
  DialogDescription,
} from '../ui/dialog';
import { Button } from '../ui/button';
import {
  UploadCloud,
  FileCode,
  CheckCircle2,
  AlertTriangle,
  XCircle,
  RefreshCw,
  Info,
  Building2,
  FileText,
} from 'lucide-react';
import { BASE_URL } from '../../utils/api';
import { formatearMonedaDe } from '../../utils/cuentasPorPagar';
import { toast } from 'sonner';

interface CxpCfdiModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  getAuthToken: () => Promise<string>;
  onImportExitoso: () => void;
}

export function CxpCfdiModal({
  open,
  onOpenChange,
  getAuthToken,
  onImportExitoso,
}: CxpCfdiModalProps) {
  const fileInputRef = useRef<HTMLInputElement>(null);
  const [archivosLeidos, setArchivosLeidos] = useState<Array<{ nombre: string; contenido: string }>>([]);
  const [previsualizacion, setPrevisualizacion] = useState<any | null>(null);
  const [cargando, setCargando] = useState(false);
  const [importando, setImportando] = useState(false);
  const [crearProveedoresNuevos, setCrearProveedoresNuevos] = useState(true);
  const [arrastrando, setArrastrando] = useState(false);

  const resetModal = () => {
    setArchivosLeidos([]);
    setPrevisualizacion(null);
    setCargando(false);
    setImportando(false);
    if (fileInputRef.current) {
      fileInputRef.current.value = '';
    }
  };

  const procesarArchivos = async (fileList: FileList | File[]) => {
    const files = Array.from(fileList).filter((f) => f.name.toLowerCase().endsWith('.xml'));
    if (files.length === 0) {
      toast.error('Seleccione al menos un archivo XML válido');
      return;
    }
    if (files.length > 100) {
      toast.error('Se permite un máximo de 100 archivos por lote');
      return;
    }

    setCargando(true);
    try {
      const leidos: Array<{ nombre: string; contenido: string }> = [];
      for (const file of files) {
        if (file.size > 2 * 1024 * 1024) {
          toast.warning(`El archivo ${file.name} excede los 2 MB y será omitido`);
          continue;
        }
        const text = await file.text();
        leidos.push({ nombre: file.name, contenido: text });
      }

      setArchivosLeidos(leidos);

      // Enviar al servidor para previsualización
      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/cxp/cfdi/previsualizar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ archivos: leidos }),
      });

      if (!res.ok) {
        const errorData = await res.json().catch(() => ({}));
        throw new Error(errorData.error || `Error ${res.status}: ${res.statusText}`);
      }

      const data = await res.json();
      setPrevisualizacion(data);
      toast.info(`${data.validos_count} comprobantes listos para importar`);
    } catch (err: any) {
      console.error('Error previsualizando CFDI:', err);
      toast.error('Error al procesar archivos XML', { description: err.message });
    } finally {
      setCargando(false);
    }
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setArrastrando(false);
    if (e.dataTransfer.files && e.dataTransfer.files.length > 0) {
      procesarArchivos(e.dataTransfer.files);
    }
  };

  const handleDragOver = (e: React.DragEvent) => {
    e.preventDefault();
    setArrastrando(true);
  };

  const handleDragLeave = () => {
    setArrastrando(false);
  };

  const handleEjecutarImportacion = async () => {
    if (!previsualizacion || !previsualizacion.resultados) return;

    const candidatos = previsualizacion.resultados.filter(
      (r: any) => r.estado === 'valido' || (r.estado === 'proveedor_nuevo' && crearProveedoresNuevos)
    );

    if (candidatos.length === 0) {
      toast.warning('No hay comprobantes válidos para importar');
      return;
    }

    setImportando(true);
    try {
      const lotes = candidatos.map((c: any) => ({
        cfdi: c.cfdi,
        xml_contenido: c.xml_contenido,
        crear_proveedor: c.estado === 'proveedor_nuevo' && crearProveedoresNuevos,
        proveedor_id: c.proveedor_id || undefined,
      }));

      const token = await getAuthToken();
      const res = await fetch(`${BASE_URL}/cxp/cfdi/importar`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${token}`,
        },
        body: JSON.stringify({ lotes }),
      });

      if (!res.ok) {
        const errJson = await res.json().catch(() => ({}));
        throw new Error(errJson.error || `Error ${res.status}`);
      }

      const data = await res.json();
      toast.success(`Se importaron ${data.importadas} facturas con éxito`, {
        description: data.proveedores_creados > 0 ? `Se crearon ${data.proveedores_creados} nuevos proveedores` : undefined,
      });

      onImportExitoso();
      onOpenChange(false);
      resetModal();
    } catch (err: any) {
      console.error('Error importando CFDI:', err);
      toast.error('Error al importar facturas', { description: err.message });
    } finally {
      setImportando(false);
    }
  };

  return (
    <Dialog
      open={open}
      onOpenChange={(v) => {
        if (!v) resetModal();
        onOpenChange(v);
      }}
    >
      <DialogContent className="max-w-4xl max-h-[90vh] flex flex-col bg-card text-foreground border-border">
        <DialogHeader>
          <div className="flex items-center gap-2">
            <FileCode className="h-6 w-6 text-primary" />
            <DialogTitle className="text-xl font-bold">Importar Facturas desde XML (CFDI 3.3 / 4.0)</DialogTitle>
          </div>
          <DialogDescription className="text-muted-foreground">
            Carga comprobantes fiscales digitales de proveedores. Se extraen automáticamente conceptos, impuestos y UUID.
          </DialogDescription>
        </DialogHeader>

        {/* Banner Legal Informativo Obligatorio */}
        <div className="flex items-center gap-2.5 p-3 rounded-lg bg-blue-500/10 border border-blue-500/20 text-xs text-blue-700 dark:text-blue-300">
          <Info className="h-4 w-4 shrink-0 text-blue-500" />
          <span>
            <strong>Aviso de importación:</strong> Los datos se extraen de la estructura del XML de acuerdo al estándar SAT. 
            <em> Importado desde XML; no validado con el SAT.</em>
          </span>
        </div>

        {/* Zona de Drop / Carga de archivos */}
        {!previsualizacion ? (
          <div
            onDrop={handleDrop}
            onDragOver={handleDragOver}
            onDragLeave={handleDragLeave}
            className={`border-2 border-dashed rounded-xl p-8 text-center flex flex-col items-center justify-center transition-colors cursor-pointer my-4 ${
              arrastrando
                ? 'border-primary bg-primary/5'
                : 'border-border/80 hover:border-primary/50 bg-muted/20'
            }`}
            onClick={() => fileInputRef.current?.click()}
          >
            <input
              type="file"
              ref={fileInputRef}
              multiple
              accept=".xml"
              className="hidden"
              onChange={(e) => {
                if (e.target.files && e.target.files.length > 0) {
                  procesarArchivos(e.target.files);
                }
              }}
            />
            <UploadCloud className="h-12 w-12 text-muted-foreground mb-3 animate-bounce" />
            <p className="text-base font-semibold text-foreground">
              Arrastra tus archivos XML aquí o haz clic para seleccionarlos
            </p>
            <p className="text-xs text-muted-foreground mt-1">
              Admite CFDI 3.3 y 4.0 · Hasta 100 archivos por lote · Máximo 2 MB por archivo
            </p>
            {cargando && (
              <div className="flex items-center gap-2 mt-4 text-xs font-medium text-primary">
                <RefreshCw className="h-4 w-4 animate-spin" /> Procesando y analizando XML...
              </div>
            )}
          </div>
        ) : (
          <div className="flex-1 overflow-y-auto space-y-4 my-2 pr-1">
            {/* Barra de Estadísticas */}
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
              <div className="p-3 rounded-lg border border-border bg-card">
                <div className="text-xs text-muted-foreground">Total archivos</div>
                <div className="text-lg font-bold">{previsualizacion.total_archivos}</div>
              </div>
              <div className="p-3 rounded-lg border border-border bg-green-500/5 text-green-700 dark:text-green-400">
                <div className="text-xs">Válidos para importar</div>
                <div className="text-lg font-bold">{previsualizacion.validos_count}</div>
              </div>
              <div className="p-3 rounded-lg border border-border bg-amber-500/5 text-amber-700 dark:text-amber-400">
                <div className="text-xs">Proveedores nuevos</div>
                <div className="text-lg font-bold">{previsualizacion.nuevos_proveedores_count}</div>
              </div>
              <div className="p-3 rounded-lg border border-border bg-muted/40">
                <div className="text-xs text-muted-foreground">Duplicados / Omitidos</div>
                <div className="text-lg font-bold">
                  {previsualizacion.duplicados_count + (previsualizacion.total_archivos - previsualizacion.validos_count - previsualizacion.duplicados_count)}
                </div>
              </div>
            </div>

            {/* Opción para crear proveedores faltantes */}
            {previsualizacion.nuevos_proveedores_count > 0 && (
              <label className="flex items-center gap-2 p-2.5 rounded-lg border border-border bg-muted/30 cursor-pointer text-xs">
                <input
                  type="checkbox"
                  checked={crearProveedoresNuevos}
                  onChange={(e) => setCrearProveedoresNuevos(e.target.checked)}
                  className="rounded border-border text-primary focus:ring-primary"
                />
                <span className="font-medium">
                  Crear automáticamente los {previsualizacion.nuevos_proveedores_count} proveedores que no están en el catálogo con los datos fiscales de su CFDI.
                </span>
              </label>
            )}

            {/* Tabla de Previsualización */}
            <div className="border border-border rounded-lg overflow-hidden text-xs">
              <table className="w-full text-left border-collapse">
                <thead className="bg-muted text-muted-foreground uppercase tracking-wider font-semibold">
                  <tr>
                    <th className="p-2.5">Estado</th>
                    <th className="p-2.5">Proveedor</th>
                    <th className="p-2.5">Folio / Serie</th>
                    <th className="p-2.5">Fecha</th>
                    <th className="p-2.5">Partidas</th>
                    <th className="p-2.5 text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-border">
                  {previsualizacion.resultados.map((r: any, idx: number) => {
                    const esValido = r.estado === 'valido';
                    const esNuevo = r.estado === 'proveedor_nuevo';
                    const esDup = r.estado === 'duplicado';
                    const esNota = r.estado === 'nota_credito';
                    const esError = r.estado === 'error' || r.estado === 'rechazado';

                    return (
                      <tr key={idx} className="hover:bg-muted/40 transition-colors">
                        <td className="p-2.5 whitespace-nowrap">
                          {esValido && (
                            <span className="inline-flex items-center gap-1 text-green-700 dark:text-green-400 font-medium">
                              <CheckCircle2 className="h-3.5 w-3.5" /> Listo
                            </span>
                          )}
                          {esNuevo && (
                            <span className="inline-flex items-center gap-1 text-amber-700 dark:text-amber-400 font-medium">
                              <Building2 className="h-3.5 w-3.5" /> Nuevo Prov.
                            </span>
                          )}
                          {esDup && (
                            <span className="inline-flex items-center gap-1 text-muted-foreground font-medium">
                              <AlertTriangle className="h-3.5 w-3.5" /> Ya importada
                            </span>
                          )}
                          {esNota && (
                            <span className="inline-flex items-center gap-1 text-purple-600 dark:text-purple-400 font-medium">
                              <FileText className="h-3.5 w-3.5" /> Nota crédito (omitida)
                            </span>
                          )}
                          {esError && (
                            <span className="inline-flex items-center gap-1 text-red-600 dark:text-red-400 font-medium">
                              <XCircle className="h-3.5 w-3.5" /> Rechazado
                            </span>
                          )}
                        </td>
                        <td className="p-2.5">
                          <div className="font-medium truncate max-w-[200px]">
                            {r.cfdi?.emisor?.nombre || r.nombre}
                          </div>
                          <div className="text-[11px] font-mono text-muted-foreground">
                            {r.cfdi?.emisor?.rfc || ''}
                          </div>
                        </td>
                        <td className="p-2.5 font-mono">
                          {r.cfdi ? `${r.cfdi.serie || ''} ${r.cfdi.folio || r.cfdi.uuid_fiscal?.slice(0, 8)}` : '-'}
                        </td>
                        <td className="p-2.5 whitespace-nowrap">
                          {r.cfdi?.fecha_emision ? r.cfdi.fecha_emision.slice(0, 10) : '-'}
                        </td>
                        <td className="p-2.5 font-mono">
                          {r.partidas ? `${r.partidas.length} partidas` : '-'}
                        </td>
                        <td className="p-2.5 text-right font-mono font-medium whitespace-nowrap">
                          {r.cfdi ? formatearMonedaDe(r.cfdi.total, r.cfdi.moneda) : '-'}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          </div>
        )}

        <DialogFooter className="mt-4 flex flex-col sm:flex-row items-center justify-between gap-2 border-t border-border pt-3">
          {previsualizacion && (
            <Button
              variant="outline"
              size="sm"
              onClick={resetModal}
              disabled={importando}
              className="w-full sm:w-auto"
            >
              Cargar otros archivos
            </Button>
          )}
          <div className="flex items-center gap-2 w-full sm:w-auto justify-end">
            <Button
              variant="ghost"
              size="sm"
              onClick={() => onOpenChange(false)}
              disabled={importando}
            >
              Cerrar
            </Button>
            {previsualizacion && (
              <Button
                onClick={handleEjecutarImportacion}
                disabled={importando || previsualizacion.validos_count === 0}
                className="w-full sm:w-auto bg-primary text-primary-foreground hover:bg-primary/90"
              >
                {importando ? (
                  <>
                    <RefreshCw className="mr-2 h-4 w-4 animate-spin" /> Importando...
                  </>
                ) : (
                  `Importar ${previsualizacion.validos_count} Comprobantes`
                )}
              </Button>
            )}
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
