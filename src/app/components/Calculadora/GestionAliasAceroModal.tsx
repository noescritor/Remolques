import React, { useEffect, useState } from 'react';
import {
  Dialog,
  DialogContent,
  DialogDescription,
  DialogFooter,
  DialogHeader,
  DialogTitle,
} from '../ui/dialog';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { Input } from '../ui/input';
import { Loader2, Trash2, AlertCircle, RefreshCw, BookmarkCheck, Search } from 'lucide-react';
import { toast } from 'sonner';
import {
  CatalogoAliasItem,
  eliminarCatalogoAliasApi,
  fetchCatalogoAliasApi,
} from '../../utils/aceroApi';

interface GestionAliasAceroModalProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  supabase: any;
}

export function GestionAliasAceroModal({
  open,
  onOpenChange,
  supabase,
}: GestionAliasAceroModalProps) {
  const [estado, setEstado] = useState<'cargando' | 'error' | 'ok'>('cargando');
  const [errorMsg, setErrorMsg] = useState<string | null>(null);
  const [alias, setAlias] = useState<CatalogoAliasItem[]>([]);
  const [filtro, setFiltro] = useState('');
  const [eliminandoId, setEliminandoId] = useState<string | null>(null);

  const cargar = async () => {
    setEstado('cargando');
    setErrorMsg(null);
    try {
      const lista = await fetchCatalogoAliasApi(supabase, 'acero_material');
      setAlias(lista);
      setEstado('ok');
    } catch (err: any) {
      setErrorMsg(err?.message || 'No se pudieron cargar los alias.');
      setEstado('error');
    }
  };

  useEffect(() => {
    if (open) {
      cargar();
    }
  }, [open]);

  const handleEliminar = async (item: CatalogoAliasItem) => {
    setEliminandoId(item.id);
    try {
      await eliminarCatalogoAliasApi(supabase, item.id);
      setAlias((prev) => prev.filter((a) => a.id !== item.id));
      toast.success('Alias eliminado');
    } catch (err: any) {
      toast.error(err?.message || 'Error al eliminar alias');
    } finally {
      setEliminandoId(null);
    }
  };

  const filtrados = alias.filter((a) => {
    const q = filtro.trim().toLowerCase();
    if (!q) return true;
    return (
      a.descripcion_original.toLowerCase().includes(q) ||
      (a.destino_nombre || '').toLowerCase().includes(q) ||
      (a.proveedor_rfc || '').toLowerCase().includes(q)
    );
  });

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-[780px] max-h-[85vh] flex flex-col bg-card border-border">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-foreground">
            <BookmarkCheck className="h-5 w-5 text-primary" />
            Alias recordados de facturas XML
          </DialogTitle>
          <DialogDescription>
            Coincidencias guardadas entre descripciones de facturas de proveedores y materiales del catálogo de acero. Si borras un alias, las próximas facturas volverán a sugerirlo por nombre.
          </DialogDescription>
        </DialogHeader>

        <div className="flex items-center gap-2 py-2">
          <div className="relative flex-1">
            <Search className="h-4 w-4 text-muted-foreground absolute left-2.5 top-2.5" />
            <Input
              value={filtro}
              onChange={(e) => setFiltro(e.target.value)}
              placeholder="Buscar por descripción XML, material o RFC..."
              className="pl-8 bg-background"
            />
          </div>
          <Button variant="outline" size="sm" onClick={cargar} disabled={estado === 'cargando'}>
            <RefreshCw className={`h-4 w-4 ${estado === 'cargando' ? 'animate-spin' : ''}`} />
          </Button>
        </div>

        <div className="flex-1 overflow-y-auto border border-border rounded-md min-h-[200px]">
          {estado === 'cargando' && (
            <div className="flex items-center justify-center py-12 text-muted-foreground gap-2 text-sm">
              <Loader2 className="h-4 w-4 animate-spin" />
              Cargando alias...
            </div>
          )}

          {estado === 'error' && (
            <div className="p-6 text-center space-y-3">
              <div className="inline-flex items-center gap-2 text-destructive text-sm font-medium">
                <AlertCircle className="h-4 w-4" />
                {errorMsg || 'Error al cargar alias'}
              </div>
              <div>
                <Button variant="outline" size="sm" onClick={cargar}>
                  Reintentar
                </Button>
              </div>
            </div>
          )}

          {estado === 'ok' && filtrados.length === 0 && (
            <div className="py-12 text-center text-sm text-muted-foreground">
              {alias.length === 0
                ? 'Todavía no hay alias recordados. Se guardan al aplicar precios desde una factura XML.'
                : 'Ningún alias coincide con el filtro.'}
            </div>
          )}

          {estado === 'ok' && filtrados.length > 0 && (
            <div className="divide-y divide-border/60">
              {filtrados.map((item) => (
                <div
                  key={item.id}
                  className="p-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2 hover:bg-muted/30"
                >
                  <div className="space-y-1 min-w-0">
                    <div className="text-xs font-medium text-foreground break-words">
                      {item.descripcion_original}
                    </div>
                    <div className="flex flex-wrap items-center gap-1.5 text-[11px] text-muted-foreground">
                      <span>→</span>
                      <span className="font-semibold text-foreground">
                        {item.destino_nombre || item.destino_id}
                      </span>
                      {item.proveedor_rfc && (
                        <Badge variant="outline" className="text-[10px] font-mono">
                          RFC {item.proveedor_rfc}
                        </Badge>
                      )}
                      {item.clave_unidad && (
                        <Badge variant="secondary" className="text-[10px] font-mono">
                          {item.clave_unidad}
                        </Badge>
                      )}
                      {item.factor_conversion !== null && (
                        <Badge variant="outline" className="text-[10px] font-mono">
                          Factor {item.factor_conversion}
                        </Badge>
                      )}
                      <span>· {item.usos} uso(s)</span>
                    </div>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => handleEliminar(item)}
                    disabled={eliminandoId === item.id}
                    className="text-destructive hover:text-destructive hover:bg-destructive/10 self-end sm:self-center shrink-0"
                    aria-label={`Eliminar alias ${item.descripcion_original}`}
                  >
                    {eliminandoId === item.id ? (
                      <Loader2 className="h-4 w-4 animate-spin" />
                    ) : (
                      <Trash2 className="h-4 w-4" />
                    )}
                  </Button>
                </div>
              ))}
            </div>
          )}
        </div>

        <DialogFooter>
          <Button variant="outline" onClick={() => onOpenChange(false)}>
            Cerrar
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
