import { useState, useMemo } from 'react';
import { useNavigate } from 'react-router-dom';
import { Button } from '../ui/button';
import { Input } from '../ui/input';
import { Label } from '../ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '../ui/select';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter, DialogDescription } from '../ui/dialog';
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '../ui/alert-dialog';
import {
  Plus,
  Edit,
  Trash2,
  Building2,
  AlertTriangle,
  CreditCard,
  ExternalLink,
  Search,
} from 'lucide-react';
import { Proveedor, Producto } from '../../types';
import { formatearMonedaDe } from '../../utils/cuentasPorPagar';

interface ProveedoresListProps {
  proveedores: Proveedor[];
  productos: Producto[];
  loading: boolean;
  onCrearProveedor: (proveedor: Omit<Proveedor, 'id' | 'organizacion_id'>) => void;
  onActualizarProveedor: (id: string, proveedor: Partial<Proveedor>) => void;
  onEliminarProveedor: (id: string) => void;
}

export function ProveedoresList({
  proveedores,
  productos,
  loading,
  onCrearProveedor,
  onActualizarProveedor,
  onEliminarProveedor,
}: ProveedoresListProps) {
  const navigate = useNavigate();
  const [modalOpen, setModalOpen] = useState(false);
  const [proveedorEditando, setProveedorEditando] = useState<Proveedor | null>(null);
  const [proveedorAEliminar, setProveedorAEliminar] = useState<string | null>(null);
  const [busqueda, setBusqueda] = useState('');

  const [formData, setFormData] = useState({
    nombre: '',
    razon_social: '',
    rfc: '',
    moneda_default: 'MXN' as 'MXN' | 'USD',
    dias_credito: 30,
    limite_credito: 0,
    limite_credito_moneda: 'MXN' as 'MXN' | 'USD',
    contacto: '',
    telefono: '',
    tiempo_entrega_dias: 0,
    condiciones_pago: '',
  });

  const materialesLookup = useMemo(() => {
    return productos.reduce((acc, p) => {
      acc[p.id] = p.nombre;
      return acc;
    }, {} as Record<string, string>);
  }, [productos]);

  // Detector de RFCs duplicados (advertencia visual)
  const rfcCounts = useMemo(() => {
    const counts: Record<string, number> = {};
    for (const p of proveedores) {
      if (p.rfc && p.rfc.trim()) {
        const clean = p.rfc.trim().toUpperCase();
        counts[clean] = (counts[clean] || 0) + 1;
      }
    }
    return counts;
  }, [proveedores]);

  // Filtrado por búsqueda
  const proveedoresFiltrados = useMemo(() => {
    if (!busqueda.trim()) return proveedores;
    const q = busqueda.toLowerCase();
    return proveedores.filter((p) => {
      const nom = (p.nombre || '').toLowerCase();
      const rz = (p.razon_social || '').toLowerCase();
      const rfc = (p.rfc || '').toLowerCase();
      const cont = (p.contacto || '').toLowerCase();
      return nom.includes(q) || rz.includes(q) || rfc.includes(q) || cont.includes(q);
    });
  }, [proveedores, busqueda]);

  const handleAbrirNuevo = () => {
    setProveedorEditando(null);
    setFormData({
      nombre: '',
      razon_social: '',
      rfc: '',
      moneda_default: 'MXN',
      dias_credito: 30,
      limite_credito: 0,
      limite_credito_moneda: 'MXN',
      contacto: '',
      telefono: '',
      tiempo_entrega_dias: 0,
      condiciones_pago: 'Crédito 30 días',
    });
    setModalOpen(true);
  };

  const handleEditar = (proveedor: Proveedor) => {
    setProveedorEditando(proveedor);
    setFormData({
      nombre: proveedor.nombre || '',
      razon_social: proveedor.razon_social || '',
      rfc: proveedor.rfc || '',
      moneda_default: (proveedor.moneda_default as any) || 'MXN',
      dias_credito: proveedor.dias_credito ?? 30,
      limite_credito: proveedor.limite_credito ? Number(proveedor.limite_credito) : 0,
      limite_credito_moneda: (proveedor.limite_credito_moneda as any) || 'MXN',
      contacto: proveedor.contacto || '',
      telefono: proveedor.telefono || '',
      tiempo_entrega_dias: proveedor.tiempo_entrega_dias || 0,
      condiciones_pago: proveedor.condiciones_pago || '',
    });
    setModalOpen(true);
  };

  const handleGuardar = () => {
    if (!formData.nombre.trim()) return;

    const payload: any = {
      ...formData,
      nombre: formData.nombre.trim(),
      razon_social: formData.razon_social.trim() || null,
      rfc: formData.rfc.trim().toUpperCase() || null,
      dias_credito: Number(formData.dias_credito) || 0,
      limite_credito: Number(formData.limite_credito) > 0 ? Number(formData.limite_credito) : null,
      tiempo_entrega_dias: Number(formData.tiempo_entrega_dias) || 0,
    };

    if (proveedorEditando) {
      onActualizarProveedor(proveedorEditando.id, payload);
    } else {
      onCrearProveedor(payload);
    }
    setModalOpen(false);
  };

  if (loading) {
    return <div className="animate-pulse h-64 bg-card/50 rounded-xl border border-border"></div>;
  }

  return (
    <div className="space-y-6 text-foreground bg-background min-h-screen pb-20">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h1 className="text-3xl font-bold font-sans">Proveedores</h1>
          <p className="text-muted-foreground mt-1">
            Catálogo oficial de proveedores, condiciones comerciales, crédito y RFC fiscal.
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button
            onClick={() => navigate('/cuentas-por-pagar?tab=facturas')}
            variant="outline"
            className="text-xs"
          >
            <CreditCard className="mr-2 h-4 w-4 text-primary" /> Cuentas por Pagar
          </Button>
          <Button
            onClick={handleAbrirNuevo}
            className="bg-primary text-primary-foreground hover:bg-primary/90 text-xs"
          >
            <Plus className="mr-2 h-4 w-4" /> Nuevo Proveedor
          </Button>
        </div>
      </div>

      {/* Buscador */}
      <div className="relative max-w-md">
        <Search className="w-4 h-4 absolute left-3 top-1/2 -translate-y-1/2 text-muted-foreground" />
        <Input
          type="text"
          placeholder="Buscar por nombre, razón social o RFC..."
          value={busqueda}
          onChange={(e) => setBusqueda(e.target.value)}
          className="pl-9 text-xs h-9 bg-background"
        />
      </div>

      {/* Lista de Proveedores */}
      {proveedores.length === 0 ? (
        <div className="text-center py-20 bg-card rounded-xl border border-border/50">
          <Building2 className="mx-auto h-12 w-12 text-muted-foreground mb-4" />
          <h3 className="text-lg font-medium text-foreground mb-2">No hay proveedores</h3>
          <p className="text-muted-foreground text-xs">Añade tu primer proveedor para comenzar o importa facturas XML.</p>
        </div>
      ) : (
        <div className="rounded-xl border border-border bg-card overflow-hidden divide-y divide-border">
          {proveedoresFiltrados.map((p) => {
            const rfcClean = p.rfc ? p.rfc.trim().toUpperCase() : '';
            const esDuplicado = rfcClean && (rfcCounts[rfcClean] || 0) > 1;

            return (
              <div key={p.id} className="p-4 flex flex-col group hover:bg-muted/20 transition-colors">
                <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                  <div className="flex items-center gap-2.5 flex-wrap">
                    <span className="text-sm font-semibold text-foreground">{p.nombre}</span>
                    {p.razon_social && p.razon_social !== p.nombre && (
                      <span className="text-xs text-muted-foreground">({p.razon_social})</span>
                    )}
                    {rfcClean ? (
                      <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-muted text-foreground border border-border">
                        RFC: {rfcClean}
                      </span>
                    ) : (
                      <span className="text-[10px] text-muted-foreground italic">Sin RFC</span>
                    )}
                    {esDuplicado && (
                      <span
                        className="inline-flex items-center gap-1 text-[10px] px-2 py-0.5 rounded-full bg-amber-500/10 text-amber-700 dark:text-amber-400 border border-amber-500/30 font-medium"
                        title="Hay otros proveedores con el mismo RFC registrado"
                      >
                        <AlertTriangle className="h-3 w-3" /> RFC Duplicado ({rfcCounts[rfcClean]})
                      </span>
                    )}
                  </div>

                  {/* Acciones */}
                  <div className="flex items-center gap-2">
                    <Button
                      variant="ghost"
                      size="sm"
                      onClick={() => navigate(`/cuentas-por-pagar?tab=facturas&proveedor=${p.id}`)}
                      className="h-7 text-xs text-primary hover:bg-primary/10 gap-1"
                    >
                      <ExternalLink className="h-3 w-3" /> Ver CxP
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-muted-foreground hover:text-foreground"
                      onClick={() => handleEditar(p)}
                      title="Editar proveedor"
                    >
                      <Edit className="h-3.5 w-3.5" />
                    </Button>
                    <Button
                      variant="ghost"
                      size="icon"
                      className="h-7 w-7 text-muted-foreground hover:text-destructive"
                      onClick={() => setProveedorAEliminar(p.id)}
                      title="Eliminar proveedor"
                    >
                      <Trash2 className="h-3.5 w-3.5" />
                    </Button>
                  </div>
                </div>

                {/* Datos de crédito y entrega */}
                <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 mt-2 pt-2 border-t border-border/40 text-xs text-muted-foreground">
                  <div>
                    <span className="font-medium text-foreground">Crédito:</span>{' '}
                    {p.dias_credito !== undefined && p.dias_credito !== null ? `${p.dias_credito} días` : 'No asignado'}
                  </div>
                  <div>
                    <span className="font-medium text-foreground">Moneda:</span>{' '}
                    <span className="font-mono">{p.moneda_default || 'MXN'}</span>
                  </div>
                  <div>
                    <span className="font-medium text-foreground">Límite crédito:</span>{' '}
                    <span className="font-mono">
                      {p.limite_credito ? formatearMonedaDe(p.limite_credito, (p.limite_credito_moneda as any) || 'MXN') : 'Sin límite'}
                    </span>
                  </div>
                  <div>
                    <span className="font-medium text-foreground">Entrega:</span>{' '}
                    {p.tiempo_entrega_dias ? `${p.tiempo_entrega_dias} días` : 'Inmediata'}
                  </div>
                </div>

                {/* Contacto y materiales */}
                {(p.contacto || p.telefono || (p.materiales && p.materiales.length > 0)) && (
                  <div className="text-xs text-muted-foreground mt-1.5 flex flex-wrap gap-x-4">
                    {(p.contacto || p.telefono) && (
                      <span>Contacto: {p.contacto || '--'} · {p.telefono || '--'}</span>
                    )}
                    {p.materiales && p.materiales.length > 0 && (
                      <span>
                        Surte: {p.materiales.map((m) => materialesLookup[m.material_id] || 'Material').join(', ')}
                      </span>
                    )}
                  </div>
                )}
              </div>
            );
          })}
        </div>
      )}

      {/* Modal Editar/Crear Proveedor */}
      <Dialog open={modalOpen} onOpenChange={setModalOpen}>
        <DialogContent className="sm:max-w-lg bg-card text-foreground border-border max-h-[90vh] overflow-y-auto">
          <DialogHeader>
            <DialogTitle className="text-base font-semibold">
              {proveedorEditando ? 'Editar Proveedor' : 'Nuevo Proveedor'}
            </DialogTitle>
            <DialogDescription className="text-xs text-muted-foreground">
              Configure la razón social, datos de facturación, condiciones de pago y límites de crédito.
            </DialogDescription>
          </DialogHeader>

          <div className="grid grid-cols-2 gap-3 py-2 text-xs">
            <div className="space-y-1 col-span-2">
              <Label className="text-xs">Nombre comercial *</Label>
              <Input
                required
                value={formData.nombre}
                onChange={(e) => setFormData({ ...formData, nombre: e.target.value })}
                placeholder="Ej. ACEROS DE CORDOBA"
                className="text-xs h-9 bg-background"
              />
            </div>

            <div className="space-y-1 col-span-2">
              <Label className="text-xs">Razón social (opcional)</Label>
              <Input
                value={formData.razon_social}
                onChange={(e) => setFormData({ ...formData, razon_social: e.target.value })}
                placeholder="Ej. PROVEEDOR ACEROS DE CORDOBA SA DE CV"
                className="text-xs h-9 bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">RFC fiscal</Label>
              <Input
                value={formData.rfc}
                onChange={(e) => setFormData({ ...formData, rfc: e.target.value })}
                placeholder="Ej. PAC010203XYZ"
                className="text-xs h-9 font-mono uppercase bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Moneda habitual</Label>
              <Select
                value={formData.moneda_default}
                onValueChange={(val: 'MXN' | 'USD') => setFormData({ ...formData, moneda_default: val })}
              >
                <SelectTrigger className="text-xs h-9 bg-background font-mono">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="MXN">MXN (Pesos)</SelectItem>
                  <SelectItem value="USD">USD (Dólares)</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Días de crédito</Label>
              <Input
                type="number"
                min="0"
                value={formData.dias_credito}
                onChange={(e) => setFormData({ ...formData, dias_credito: Number(e.target.value) })}
                className="text-xs h-9 font-mono bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Límite de crédito autorizado</Label>
              <Input
                type="number"
                step="0.01"
                min="0"
                value={formData.limite_credito}
                onChange={(e) => setFormData({ ...formData, limite_credito: Number(e.target.value) })}
                className="text-xs h-9 font-mono bg-background"
                placeholder="0.00 (sin límite)"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Contacto</Label>
              <Input
                value={formData.contacto}
                onChange={(e) => setFormData({ ...formData, contacto: e.target.value })}
                placeholder="Nombre del vendedor / asesor"
                className="text-xs h-9 bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Teléfono</Label>
              <Input
                value={formData.telefono}
                onChange={(e) => setFormData({ ...formData, telefono: e.target.value })}
                placeholder="Ej. (271) 712 3456"
                className="text-xs h-9 font-mono bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Tiempo de entrega (días)</Label>
              <Input
                type="number"
                min="0"
                value={formData.tiempo_entrega_dias}
                onChange={(e) => setFormData({ ...formData, tiempo_entrega_dias: Number(e.target.value) })}
                className="text-xs h-9 font-mono bg-background"
              />
            </div>

            <div className="space-y-1">
              <Label className="text-xs">Condiciones comerciales</Label>
              <Input
                value={formData.condiciones_pago}
                onChange={(e) => setFormData({ ...formData, condiciones_pago: e.target.value })}
                placeholder="Ej. Transferencia 30 días"
                className="text-xs h-9 bg-background"
              />
            </div>
          </div>

          <DialogFooter className="border-t border-border pt-3">
            <Button variant="outline" size="sm" onClick={() => setModalOpen(false)}>
              Cancelar
            </Button>
            <Button
              size="sm"
              onClick={handleGuardar}
              className="bg-primary text-primary-foreground hover:bg-primary/90"
            >
              Guardar Proveedor
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>

      {/* Modal Confirmar Eliminar */}
      <AlertDialog open={!!proveedorAEliminar} onOpenChange={(o) => !o && setProveedorAEliminar(null)}>
        <AlertDialogContent className="bg-card text-foreground border-border">
          <AlertDialogHeader>
            <AlertDialogTitle>¿Eliminar proveedor?</AlertDialogTitle>
            <AlertDialogDescription className="text-muted-foreground">
              Esta acción eliminará el proveedor del catálogo. Las facturas históricas no se verán afectadas si están protegidas por integridad referencial.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertDialogFooter>
            <AlertDialogCancel>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              onClick={() => {
                if (proveedorAEliminar) {
                  onEliminarProveedor(proveedorAEliminar);
                  setProveedorAEliminar(null);
                }
              }}
              className="bg-destructive text-destructive-foreground hover:bg-destructive/90"
            >
              Sí, eliminar
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  );
}
