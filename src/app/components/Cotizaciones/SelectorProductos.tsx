import React, { useState, useMemo, useEffect, useRef } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogDescription } from '../ui/dialog';
import { Input } from '../ui/input';
import { Button } from '../ui/button';
import { Search, Plus, Check } from 'lucide-react';
import { formatearMoneda } from '../../utils/calculations';

interface SelectorProductosProps {
  open: boolean;
  onOpenChange: (open: boolean) => void;
  productos: any[];
  modelos: any[];
  categorias: any[];
  onAddConfigurable: (producto: any, modelo: any) => void;
  onAddMultiples: (items: { producto: any, cantidad: number }[]) => void;
}

export function SelectorProductos({ open, onOpenChange, productos, modelos, categorias, onAddConfigurable, onAddMultiples }: SelectorProductosProps) {
  const [busqueda, setBusqueda] = useState('');
  const [mostrarMateriales, setMostrarMateriales] = useState(false);
  const [cantidades, setCantidades] = useState<Record<string, number>>({});
  const [grupoSeleccionado, setGrupoSeleccionado] = useState<string>('todos');

  const searchRef = useRef<HTMLInputElement>(null);

  useEffect(() => {
    if (open) {
      setBusqueda('');
      setCantidades({});
      setGrupoSeleccionado('todos');
      setTimeout(() => {
        searchRef.current?.focus();
      }, 100);
    }
  }, [open]);

  // Clean categories: deduplicate by name
  const categoriasMap = useMemo(() => {
    const map = new Map<string, string>(); // name -> first id
    const idToName = new Map<string, string>();
    categorias.forEach(c => {
      const name = (c.nombre || '').trim();
      if (!name) return;
      if (!map.has(name)) {
        map.set(name, c.id);
      }
      idToName.set(c.id, name);
    });
    return idToName;
  }, [categorias]);

  const { gruposList, itemsByGroup } = useMemo(() => {
    const groups = new Map<string, any[]>();
    
    // Initial empty groups to maintain order if empty
    const addGroup = (name: string, p: any) => {
      if (!groups.has(name)) groups.set(name, []);
      groups.get(name)!.push(p);
    };

    productos.forEach(p => {
      // 1. Equipos configurables
      const mod = modelos.find(m => m.producto_id === p.id);
      if (mod) {
        const tipoName = mod.tipo ? (mod.tipo.charAt(0).toUpperCase() + mod.tipo.slice(1)) : 'Otros modelos';
        addGroup(`Configurable: ${tipoName}`, { ...p, _modelo: mod, _clase: 'configurable' });
        return;
      }

      // 2. Otros equipos
      if (p.tipo_item === 'producto_terminado') {
        let catName = 'Sin categoría';
        if (p.categoria_id && categoriasMap.has(p.categoria_id)) {
          catName = categoriasMap.get(p.categoria_id)!;
        }
        addGroup(`Equipos: ${catName}`, { ...p, _clase: 'equipo' });
        return;
      }

      // 4. Materiales y piezas
      if (p.tipo_item === 'materia_prima') {
        addGroup('Materiales y piezas', { ...p, _clase: 'material' });
        return;
      }

      // 3. Refacciones (lo que quede)
      let catName = 'Sin categoría';
      if (p.categoria_id && categoriasMap.has(p.categoria_id)) {
        catName = categoriasMap.get(p.categoria_id)!;
      }
      addGroup(`Refacciones: ${catName}`, { ...p, _clase: 'refaccion' });
    });

    const resultList: string[] = [];
    const orderedKeys = Array.from(groups.keys()).sort((a, b) => {
      const orderA = a.startsWith('Configurable:') ? 1 : a.startsWith('Equipos:') ? 2 : a.startsWith('Refacciones:') ? 3 : 4;
      const orderB = b.startsWith('Configurable:') ? 1 : b.startsWith('Equipos:') ? 2 : b.startsWith('Refacciones:') ? 3 : 4;
      if (orderA !== orderB) return orderA - orderB;
      return a.localeCompare(b);
    });

    return { gruposList: orderedKeys, itemsByGroup: groups };
  }, [productos, modelos, categoriasMap]);

  const filtrados = useMemo(() => {
    const q = busqueda.toLowerCase().trim();
    let res = Array.from(itemsByGroup.entries()).map(([gName, items]) => {
      // Filter out materials if not showing, UNLESS there's an exact search match
      let filteredItems = items;
      if (gName === 'Materiales y piezas' && !mostrarMateriales && q === '') {
        filteredItems = [];
      } else if (gName === 'Materiales y piezas' && !mostrarMateriales && q !== '') {
         // Show only if there's a strong match
         filteredItems = items.filter(p => p.nombre.toLowerCase().includes(q) || p.id.toLowerCase() === q);
      }

      if (q) {
        filteredItems = filteredItems.filter(p => 
          p.nombre.toLowerCase().includes(q) || 
          (p.descripcion && p.descripcion.toLowerCase().includes(q)) ||
          p.id.toLowerCase().includes(q)
        );
      }
      return { groupName: gName, items: filteredItems };
    }).filter(g => g.items.length > 0);

    if (grupoSeleccionado !== 'todos') {
      res = res.filter(g => g.groupName === grupoSeleccionado);
    }

    return res;
  }, [itemsByGroup, busqueda, grupoSeleccionado, mostrarMateriales]);

  const totalSeleccionados = Object.values(cantidades).reduce((sum, val) => sum + (val || 0), 0);

  const handleAgregarSeleccion = () => {
    const seleccion: { producto: any, cantidad: number }[] = [];
    Object.entries(cantidades).forEach(([id, cant]) => {
      if (cant > 0) {
        const prod = productos.find(p => p.id === id);
        if (prod) seleccion.push({ producto: prod, cantidad: cant });
      }
    });
    if (seleccion.length > 0) {
      onAddMultiples(seleccion);
      setCantidades({});
      onOpenChange(false);
    }
  };

  const setCant = (id: string, val: number) => {
    setCantidades(prev => {
      const n = { ...prev };
      if (val <= 0 || isNaN(val)) {
        delete n[id];
      } else {
        n[id] = val;
      }
      return n;
    });
  };

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-w-5xl w-[95vw] h-[85vh] flex flex-col p-0 overflow-hidden">
        <DialogHeader className="px-6 py-4 border-b">
          <DialogTitle>Catálogo de Productos</DialogTitle>
          <DialogDescription>
            Busca y selecciona los productos a incluir en la cotización.
          </DialogDescription>
        </DialogHeader>
        
        <div className="flex flex-1 overflow-hidden">
          {/* Sidebar Grupos */}
          <div className="w-64 border-r bg-muted/20 overflow-y-auto flex flex-col">
            <div className="p-3">
              <button 
                className={`w-full text-left px-3 py-2 rounded-md text-sm transition-colors ${grupoSeleccionado === 'todos' ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-accent'}`}
                onClick={() => setGrupoSeleccionado('todos')}
              >
                Todos los productos
              </button>
              {gruposList.map(g => (
                <button 
                  key={g}
                  className={`w-full text-left px-3 py-2 rounded-md text-sm mt-1 transition-colors ${grupoSeleccionado === g ? 'bg-primary/10 text-primary font-medium' : 'hover:bg-accent'}`}
                  onClick={() => setGrupoSeleccionado(g)}
                >
                  <span className="truncate block">{g.replace('Configurable:', '').replace('Equipos:', '').replace('Refacciones:', '')}</span>
                  <span className="text-[10px] text-muted-foreground uppercase">{g.split(':')[0]}</span>
                </button>
              ))}
            </div>
            
            <div className="mt-auto p-4 border-t">
              <label className="flex items-center gap-2 text-sm cursor-pointer select-none">
                <input 
                  type="checkbox" 
                  checked={mostrarMateriales} 
                  onChange={(e) => setMostrarMateriales(e.target.checked)} 
                  className="rounded border-gray-300"
                />
                Mostrar materiales
              </label>
            </div>
          </div>

          {/* Main Area */}
          <div className="flex-1 flex flex-col min-w-0">
            <div className="p-4 border-b">
              <div className="relative">
                <Search className="absolute left-3 top-2.5 h-4 w-4 text-muted-foreground" />
                <Input
                  ref={searchRef}
                  placeholder="Buscar por nombre, código..."
                  className="pl-9"
                  value={busqueda}
                  onChange={e => setBusqueda(e.target.value)}
                />
              </div>
            </div>
            
            <div className="flex-1 overflow-y-auto p-4 bg-gray-50/50">
              {filtrados.length === 0 ? (
                <div className="text-center py-10 text-muted-foreground">
                  No se encontraron productos.
                </div>
              ) : (
                filtrados.map(g => (
                  <div key={g.groupName} className="mb-6">
                    <h3 className="text-sm font-semibold text-muted-foreground mb-3 sticky top-0 bg-gray-50/90 py-1 z-10">{g.groupName}</h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
                      {g.items.map((p: any) => (
                        <div key={p.id} className="bg-background border rounded-lg p-3 hover:border-primary/50 transition-colors flex flex-col">
                          <div className="flex justify-between items-start mb-2">
                            <div>
                              <div className="font-medium text-sm text-foreground leading-tight">{p.nombre}</div>
                              <div className="text-xs text-muted-foreground mt-0.5">{p.id}</div>
                            </div>
                            <div className="text-right">
                              <div className="font-semibold text-sm text-foreground">{formatearMoneda(p.precio_unitario || 0)}</div>
                              <div className="text-[10px] text-muted-foreground uppercase">{p.unidad}</div>
                            </div>
                          </div>
                          
                          <div className="mt-auto pt-2 flex items-center justify-end">
                            {p._clase === 'configurable' ? (
                              <Button size="sm" onClick={() => {
                                onAddConfigurable(p, p._modelo);
                                onOpenChange(false);
                              }}>
                                <Plus className="h-4 w-4 mr-1" />
                                Configurar
                              </Button>
                            ) : (
                              <div className="flex items-center gap-2">
                                <Input 
                                  type="number" 
                                  min="0"
                                  className="w-16 h-8 text-center text-sm"
                                  value={cantidades[p.id] || ''}
                                  placeholder="0"
                                  onChange={(e) => setCant(p.id, parseFloat(e.target.value))}
                                />
                                <Button 
                                  size="sm" 
                                  variant={cantidades[p.id] > 0 ? "default" : "outline"}
                                  onClick={() => setCant(p.id, (cantidades[p.id] || 0) + 1)}
                                >
                                  {cantidades[p.id] > 0 ? <Check className="h-4 w-4" /> : <Plus className="h-4 w-4" />}
                                </Button>
                              </div>
                            )}
                          </div>
                        </div>
                      ))}
                    </div>
                  </div>
                ))
              )}
            </div>

            <div className="p-4 border-t flex justify-between items-center bg-background">
              <div className="text-sm text-muted-foreground">
                {totalSeleccionados} concepto(s) listos para agregar
              </div>
              <Button 
                onClick={handleAgregarSeleccion} 
                disabled={totalSeleccionados === 0}
              >
                Agregar a la cotización
              </Button>
            </div>
          </div>
        </div>
      </DialogContent>
    </Dialog>
  );
}
