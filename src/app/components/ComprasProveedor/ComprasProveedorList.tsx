import { useState } from 'react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { ShoppingCart, Check } from 'lucide-react';
import { CompraProveedor, Proveedor, Producto } from '../../types';
import { formatearMoneda } from '../../utils/calculations';

interface ComprasProveedorListProps {
  compras: CompraProveedor[];
  proveedores: Proveedor[];
  productos: Producto[];
  loading: boolean;
  onRecibirCompra: (id: string) => void;
  rolActual: string;
}

export function ComprasProveedorList({
  compras,
  proveedores,
  productos,
  loading,
  onRecibirCompra,
  rolActual
}: ComprasProveedorListProps) {

  const proveedoresLookup = proveedores.reduce((acc, p) => {
    acc[p.id] = p;
    return acc;
  }, {} as Record<string, Proveedor>);

  const productosLookup = productos.reduce((acc, p) => {
    acc[p.id] = p;
    return acc;
  }, {} as Record<string, Producto>);

  if (loading) {
    return <div className="animate-pulse h-64 bg-white/[0.02] rounded-xl"></div>;
  }

  const getStatusBadge = (estado: string) => {
    switch (estado) {
      case 'Pendiente': return <Badge variant="outline" className="bg-yellow-500/10 text-yellow-500 border-yellow-500/20">Pendiente</Badge>;
      case 'Recibida': return <Badge variant="outline" className="bg-green-500/10 text-green-500 border-green-500/20">Recibida</Badge>;
      case 'Cancelada': return <Badge variant="outline" className="bg-red-500/10 text-red-500 border-red-500/20">Cancelada</Badge>;
      default: return <Badge variant="outline">{estado}</Badge>;
    }
  };

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      <div>
        <h1 className="text-3xl font-bold font-sans">Compra a proveedor</h1>
        <p className="text-muted-foreground mt-1">Se genera cuando la requisición detecta material faltante.</p>
      </div>

      {compras.length === 0 ? (
        <div className="text-center py-20 bg-white/[0.02] rounded-xl border border-white/[0.06]">
          <ShoppingCart className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-white mb-2">No hay compras</h3>
          <p className="text-muted-foreground">Las compras a proveedores aparecerán aquí automáticamente.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-white/[0.06] bg-white/[0.02] overflow-hidden">
          {compras.map((c, i) => {
            const prov = c.proveedor_id ? proveedoresLookup[c.proveedor_id] : null;
            return (
              <div key={c.id} className="p-4 flex items-center justify-between group" style={{ borderTop: i ? '1px solid rgba(255,255,255,0.06)' : 'none' }}>
                <div className="flex flex-col gap-1">
                  <div className="flex items-center gap-2">
                    <span className="font-mono text-sm bg-white/10 px-2 py-0.5 rounded text-white">{c.folio}</span>
                    <span className="text-xs text-muted-foreground">creada el {new Date(c.fecha).toLocaleDateString()}</span>
                  </div>
                  <span className="text-sm text-white">{prov ? prov.nombre : "Sin proveedor asignado"}</span>
                  <span className="text-xs text-muted-foreground">
                    {c.items?.map((m) => {
                      const matName = productosLookup[m.material_id]?.nombre || 'Desconocido';
                      return `${matName} × ${m.cantidad} — ${formatearMoneda(m.costo_unitario)} c/u`;
                    }).join(" · ")}
                    {prov && prov.tiempo_entrega_dias ? ` · entrega en ${prov.tiempo_entrega_dias} días` : ""}
                  </span>
                </div>
                <div className="flex items-center gap-4">
                  {getStatusBadge(c.estado)}
                  {c.estado === "Pendiente" && (rolActual === 'Almacén' || rolActual === 'Gerencia' || rolActual === 'propietario' || rolActual === 'admin') && (
                    <Button size="sm" onClick={() => onRecibirCompra(c.id)} className="bg-accent-blue text-white hover:bg-accent-blue/90 h-8">
                      <Check className="h-4 w-4 mr-1" /> Recibir
                    </Button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
