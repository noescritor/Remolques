import { useState, useEffect } from 'react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Checkbox } from '../ui/checkbox';
import {
  ShoppingCart,
  Check,
  FileText,
  AlertTriangle,
  Loader2,
  RefreshCw,
} from 'lucide-react';
import { CompraProveedor, Proveedor, Producto } from '../../types';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { CompraPDFTemplate } from './CompraPDFTemplate';
import { toast } from 'sonner';

interface ComprasProveedorListProps {
  compras: CompraProveedor[];
  proveedores: Proveedor[];
  productos: Producto[];
  loading: boolean;
  onRecibirCompra: (id: string, opts?: { confirmo_doble?: boolean }) => Promise<any>;
  rolActual: string;
}

export function ComprasProveedorList({
  compras,
  proveedores,
  productos,
  loading,
  onRecibirCompra,
  rolActual,
}: ComprasProveedorListProps) {
  const [compraParaPDF, setCompraParaPDF] = useState<CompraProveedor | null>(null);
  const [compraAConfirmar, setCompraAConfirmar] = useState<CompraProveedor | null>(null);
  const [recibiendoId, setRecibiendoId] = useState<string | null>(null);
  const [errorRecepcion, setErrorRecepcion] = useState<{
    compraId: string;
    folio: string;
    mensaje: string;
    esDobleConteo?: boolean;
  } | null>(null);
  const [confirmoDoble, setConfirmoDoble] = useState(false);

  const handlePrint = () => {
    window.print();
  };

  useEffect(() => {
    if (compraParaPDF) {
      document.body.classList.add('printing-modal');
    } else {
      document.body.classList.remove('printing-modal');
    }
    return () => document.body.classList.remove('printing-modal');
  }, [compraParaPDF]);

  const proveedoresLookup = proveedores.reduce((acc, p) => {
    acc[p.id] = p;
    return acc;
  }, {} as Record<string, Proveedor>);

  const productosLookup = productos.reduce((acc, p) => {
    acc[p.id] = p;
    return acc;
  }, {} as Record<string, Producto>);

  const ejecutarRecepcion = async (compra: CompraProveedor, forzarDoble = false) => {
    if (recibiendoId) return;
    setRecibiendoId(compra.id);
    setErrorRecepcion(null);
    try {
      const res = await onRecibirCompra(compra.id, forzarDoble ? { confirmo_doble: true } : undefined);
      if (res?.aviso) {
        toast.warning(res.aviso);
      } else if (res?.recepcion?.ya_recibida) {
        toast.info(`La compra ${compra.folio} ya había sido recibida.`);
      } else {
        toast.success(`Compra ${compra.folio} recibida en inventario.`);
      }
      setCompraAConfirmar(null);
      setConfirmoDoble(false);
    } catch (err: any) {
      const esDoble =
        err?.codigo === 'factura_ya_recibida' ||
        (err?.status === 409 && /factura en almac/i.test(String(err?.message || '')));
      const msg = err?.detalle || err?.message || 'No se pudo recibir la compra. Inténtalo de nuevo.';
      setErrorRecepcion({ compraId: compra.id, folio: compra.folio, mensaje: msg, esDobleConteo: esDoble });
      if (esDoble) {
        setConfirmoDoble(false);
      }
      toast.error(msg);
    } finally {
      setRecibiendoId(null);
    }
  };

  if (loading) {
    return <div className="animate-pulse h-64 bg-card rounded-xl border border-border" />;
  }

  const getStatusBadge = (estado: string) => {
    switch (estado) {
      case 'Pendiente':
        return (
          <Badge variant="outline" className="bg-amber-500/10 text-amber-600 dark:text-amber-400 border-amber-500/30 uppercase text-[0.7rem] tracking-wider">
            Pendiente
          </Badge>
        );
      case 'Recibida':
        return (
          <Badge variant="outline" className="bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border-emerald-500/30 uppercase text-[0.7rem] tracking-wider">
            Recibida
          </Badge>
        );
      case 'Cancelada':
        return (
          <Badge variant="outline" className="bg-destructive/10 text-destructive border-destructive/30 uppercase text-[0.7rem] tracking-wider">
            Cancelada
          </Badge>
        );
      default:
        return <Badge variant="outline">{estado}</Badge>;
    }
  };

  const puedeRecibir =
    rolActual === 'Almacén' ||
    rolActual === 'Gerencia' ||
    rolActual === 'propietario' ||
    rolActual === 'admin';

  const compraEnError = errorRecepcion
    ? compras.find((x) => x.id === errorRecepcion.compraId) || null
    : null;

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div>
        <h1 className="text-2xl sm:text-3xl font-bold font-sans text-foreground">Compra a proveedor</h1>
        <p className="text-sm text-muted-foreground mt-1">Órdenes de compra y requisiciones de material.</p>
      </div>

      {errorRecepcion && !compraAConfirmar && (
        <div
          role="alert"
          className="rounded-lg border border-destructive/40 bg-destructive/10 p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
        >
          <div className="flex items-start gap-2.5 text-sm text-destructive">
            <AlertTriangle className="h-5 w-5 shrink-0 mt-0.5" />
            <div>
              <div className="font-semibold uppercase text-xs tracking-wider">
                Error al recibir {errorRecepcion.folio}
              </div>
              <div className="text-foreground mt-0.5">{errorRecepcion.mensaje}</div>
            </div>
          </div>
          {compraEnError && compraEnError.estado === 'Pendiente' && (
            <Button
              size="sm"
              variant="outline"
              disabled={Boolean(recibiendoId)}
              onClick={() => ejecutarRecepcion(compraEnError)}
              className="gap-1.5 self-start sm:self-auto"
            >
              <RefreshCw className={`h-3.5 w-3.5 ${recibiendoId === compraEnError.id ? 'animate-spin' : ''}`} />
              Reintentar
            </Button>
          )}
        </div>
      )}

      {compras.length === 0 ? (
        <div className="text-center py-20 bg-card rounded-xl border border-border">
          <ShoppingCart className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-foreground mb-2">No hay compras</h3>
          <p className="text-muted-foreground">Las compras a proveedores aparecerán aquí automáticamente.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-border bg-card overflow-hidden divide-y divide-border">
          {compras.map((c) => {
            const prov = c.proveedor_id ? proveedoresLookup[c.proveedor_id] : null;
            const estaRecibiendo = recibiendoId === c.id;
            return (
              <div
                key={c.id}
                className="p-4 flex flex-col sm:flex-row sm:items-center justify-between gap-3"
              >
                <div className="flex flex-col gap-1 min-w-0">
                  <div className="flex flex-wrap items-center gap-2">
                    <span className="font-mono text-sm bg-muted px-2 py-0.5 rounded text-foreground border border-border">
                      {c.folio}
                    </span>
                    <span className="text-xs text-muted-foreground">
                      creada el {new Date(c.fecha).toLocaleDateString()}
                    </span>
                  </div>
                  <span className="text-sm font-medium text-foreground truncate">
                    {prov ? prov.nombre : 'Sin proveedor asignado'}
                  </span>
                  <span className="text-xs text-muted-foreground break-words">
                    {c.items && c.items.length > 0
                      ? c.items
                          .map((m) => {
                            const matName = productosLookup[m.material_id]?.nombre || 'Desconocido';
                            return `${matName} × ${m.cantidad}`;
                          })
                          .join(' · ')
                      : 'Sin partidas registradas'}
                  </span>
                </div>
                <div className="flex flex-wrap items-center gap-2 shrink-0">
                  {getStatusBadge(c.estado)}
                  <Button
                    size="sm"
                    variant="outline"
                    onClick={() => setCompraParaPDF(c)}
                    className="h-8"
                  >
                    <FileText className="h-4 w-4 mr-1" />
                    <span>Ver PDF</span>
                  </Button>
                  {c.estado === 'Pendiente' && puedeRecibir && (
                    <Button
                      size="sm"
                      disabled={Boolean(recibiendoId)}
                      onClick={() => {
                        setErrorRecepcion(null);
                        setConfirmoDoble(false);
                        setCompraAConfirmar(c);
                      }}
                      className="bg-primary text-primary-foreground hover:bg-primary/90 h-8"
                    >
                      {estaRecibiendo ? (
                        <>
                          <Loader2 className="h-4 w-4 mr-1 animate-spin" />
                          <span>Recibiendo...</span>
                        </>
                      ) : (
                        <>
                          <Check className="h-4 w-4 mr-1" />
                          <span>Recibir</span>
                        </>
                      )}
                    </Button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal de confirmación antes de recibir compra */}
      <Dialog
        open={Boolean(compraAConfirmar)}
        onOpenChange={(open) => {
          if (!open && !recibiendoId) {
            setCompraAConfirmar(null);
            setErrorRecepcion(null);
            setConfirmoDoble(false);
          }
        }}
      >
        <DialogContent className="bg-card text-foreground border-border sm:max-w-md">
          <DialogHeader>
            <DialogTitle className="text-foreground">
              Confirmar recepción · <span className="font-mono">{compraAConfirmar?.folio}</span>
            </DialogTitle>
            <DialogDescription className="text-muted-foreground">
              Se sumará al inventario: {compraAConfirmar?.items?.length || 0} partidas. Esta acción no se puede deshacer desde aquí.
            </DialogDescription>
          </DialogHeader>

          {compraAConfirmar?.items && compraAConfirmar.items.length > 0 && (
            <div className="rounded-md border border-border bg-muted/40 p-3 space-y-1 text-xs max-h-48 overflow-y-auto">
              <div className="uppercase tracking-wider text-[0.65rem] font-semibold text-muted-foreground mb-1">
                Partidas a ingresar
              </div>
              {compraAConfirmar.items.map((m, idx) => (
                <div key={idx} className="flex items-center justify-between gap-2 text-foreground">
                  <span className="truncate">{productosLookup[m.material_id]?.nombre || m.material_id}</span>
                  <span className="font-mono font-semibold shrink-0">+{m.cantidad}</span>
                </div>
              ))}
            </div>
          )}

          {errorRecepcion && compraAConfirmar && errorRecepcion.compraId === compraAConfirmar.id && (
            <div
              role="alert"
              className="rounded-md border border-destructive/40 bg-destructive/10 p-3 space-y-2.5 text-xs text-destructive"
            >
              <div className="flex items-start gap-2">
                <AlertTriangle className="h-4 w-4 shrink-0 mt-0.5" />
                <div className="space-y-1">
                  <div className="font-semibold">
                    {errorRecepcion.esDobleConteo
                      ? 'Posible doble conteo de inventario'
                      : 'No se pudo completar la recepción'}
                  </div>
                  <div className="text-foreground">{errorRecepcion.mensaje}</div>
                </div>
              </div>
              {errorRecepcion.esDobleConteo && (
                <label className="flex items-center gap-2 cursor-pointer text-foreground pt-1 border-t border-destructive/20">
                  <Checkbox
                    checked={confirmoDoble}
                    onCheckedChange={(v) => setConfirmoDoble(Boolean(v))}
                    disabled={Boolean(recibiendoId)}
                  />
                  <span>Confirmo que no es la misma mercancía</span>
                </label>
              )}
            </div>
          )}

          <DialogFooter className="gap-2">
            <Button
              variant="outline"
              disabled={Boolean(recibiendoId)}
              onClick={() => {
                setCompraAConfirmar(null);
                setErrorRecepcion(null);
                setConfirmoDoble(false);
              }}
            >
              Cancelar
            </Button>
            {compraAConfirmar && (() => {
              const requiereDoble = Boolean(
                errorRecepcion &&
                  errorRecepcion.compraId === compraAConfirmar.id &&
                  errorRecepcion.esDobleConteo,
              );
              const esReintento = Boolean(
                errorRecepcion &&
                  errorRecepcion.compraId === compraAConfirmar.id &&
                  !errorRecepcion.esDobleConteo,
              );
              return (
                <Button
                  disabled={Boolean(recibiendoId) || (requiereDoble && !confirmoDoble)}
                  onClick={() => ejecutarRecepcion(compraAConfirmar, requiereDoble && confirmoDoble)}
                  className="bg-primary text-primary-foreground hover:bg-primary/90 gap-1.5"
                >
                  {recibiendoId === compraAConfirmar.id ? (
                    <>
                      <Loader2 className="h-4 w-4 animate-spin" />
                      Recibiendo...
                    </>
                  ) : esReintento ? (
                    <>
                      <RefreshCw className="h-4 w-4" />
                      Reintentar
                    </>
                  ) : (
                    <>
                      <Check className="h-4 w-4" />
                      Confirmar recepción
                    </>
                  )}
                </Button>
              );
            })()}
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal para ver e imprimir PDF */}
      <Dialog open={!!compraParaPDF} onOpenChange={(open) => !open && setCompraParaPDF(null)}>
        <DialogContent className="w-full sm:max-w-[1000px] max-h-[90vh] overflow-y-auto bg-card border-border p-6">
          <div className="flex flex-wrap justify-between items-center gap-2 mb-4">
            <h2 className="text-lg font-bold text-foreground">Vista Previa de Orden de Compra</h2>
            <Button onClick={handlePrint} className="bg-primary text-primary-foreground hover:bg-primary/90">
              <FileText className="h-4 w-4 mr-2" /> Imprimir / Descargar PDF
            </Button>
          </div>

          <div className="flex justify-center bg-muted/50 p-4 sm:p-8 rounded-lg overflow-x-auto">
            {compraParaPDF && (
              <div className="bg-white shadow-xl">
                <CompraPDFTemplate
                  compra={compraParaPDF}
                  proveedor={compraParaPDF.proveedor_id ? proveedoresLookup[compraParaPDF.proveedor_id] : undefined}
                  productosLookup={productosLookup}
                />
              </div>
            )}
          </div>
        </DialogContent>
      </Dialog>
    </div>
  );
}
