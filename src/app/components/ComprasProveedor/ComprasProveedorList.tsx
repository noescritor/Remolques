import { useState, useRef, useEffect } from 'react';
import { Button } from '../ui/button';
import { Badge } from '../ui/badge';
import { ShoppingCart, Check, FileText } from 'lucide-react';
import { CompraProveedor, Proveedor, Producto } from '../../types';
import { formatearMoneda } from '../../utils/calculations';
import { Dialog, DialogContent } from '../ui/dialog';
import { CompraPDFTemplate } from './CompraPDFTemplate';

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
  
  const [compraParaPDF, setCompraParaPDF] = useState<CompraProveedor | null>(null);

  const handlePrint = () => {
    window.print();
  };

  // Add print styles dynamically when modal is open
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
        <p className="text-muted-foreground mt-1">Órdenes de compra y requisiciones de material.</p>
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
                      return `${matName} x ${m.cantidad}`;
                    }).join(" • ")}
                  </span>
                </div>
                <div className="flex items-center gap-2 sm:gap-4">
                  {getStatusBadge(c.estado)}
                  <Button size="sm" variant="outline" onClick={() => setCompraParaPDF(c)} className="h-8">
                    <FileText className="h-4 w-4 sm:mr-1" /> <span className="hidden sm:inline">Ver PDF</span>
                  </Button>
                  {c.estado === "Pendiente" && (rolActual === 'Almacén' || rolActual === 'Gerencia' || rolActual === 'propietario' || rolActual === 'admin') && (
                    <Button size="sm" onClick={() => onRecibirCompra(c.id)} className="bg-accent-blue text-white hover:bg-accent-blue/90 h-8">
                      <Check className="h-4 w-4 sm:mr-1" /> <span className="hidden sm:inline">Recibir</span>
                    </Button>
                  )}
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Modal para ver e imprimir PDF */}
      <Dialog open={!!compraParaPDF} onOpenChange={(open) => !open && setCompraParaPDF(null)}>
        <DialogContent className="w-full sm:max-w-[1000px] max-h-[90vh] overflow-y-auto bg-slate-900 border-white/10 p-6">
          <div className="flex justify-between items-center mb-4">
            <h2 className="text-lg font-bold text-white">Vista Previa de Orden de Compra</h2>
            <Button onClick={handlePrint} className="bg-white text-black hover:bg-slate-200">
              <FileText className="h-4 w-4 mr-2" /> Imprimir / Descargar PDF
            </Button>
          </div>
          
          <div className="flex justify-center bg-slate-800 p-8 rounded-lg overflow-x-auto">
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
