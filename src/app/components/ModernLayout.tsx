import { ReactNode, useState } from 'react';
import {
  LayoutDashboard,
  FileText,
  Users,
  Package,
  Settings,
  BookTemplate,
  Calculator,
  Menu,
  X,
  ClipboardList,
  DollarSign
} from 'lucide-react';
import { LogoIdeally } from './Cotizaciones/LogoIdeally';
import { Sheet, SheetContent, SheetTrigger, SheetTitle, SheetDescription } from './ui/sheet';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from './ui/dialog';
import { Input } from './ui/input';
import { Label } from './ui/label';
import { toast } from 'sonner';
import { Button } from './ui/button';
import { supabase } from '../utils/supabase/client';

interface ModernLayoutProps {
  session?: any;
  children: ReactNode;
  currentPage: string;
  onNavigate: (page: string) => void;
  organizacion?: any;
  loading?: boolean;
}

function ModernSideNav({ currentPage, onNavigate, session, organizacion, loading }: { currentPage: string; onNavigate: (page: string) => void; session?: any; organizacion?: any; loading?: boolean }) {
  const [profileOpen, setProfileOpen] = useState(false);
  const [nombre, setNombre] = useState(session?.user?.user_metadata?.nombre || '');
  
  const handleUpdateProfile = async () => {
    try {
      const { error } = await supabase.auth.updateUser({
        data: { nombre }
      });
      if (error) throw error;
      toast.success('Perfil actualizado correctamente');
      setProfileOpen(false);
    } catch (err: any) {
      toast.error('Error al actualizar perfil', { description: err.message });
    }
  };

  const userName = session?.user?.user_metadata?.nombre || 'Usuario';
  const userInitial = userName.charAt(0).toUpperCase();
  const userEmail = session?.user?.email || '';

  const modulos = organizacion?.modulos || (loading ? {
    cotizaciones: false,
    clientes: false,
    productos: false,
    calculadora: false,
    inventario: false,
    notas: false
  } : {
    cotizaciones: true,
    clientes: true,
    productos: true,
    calculadora: true,
    inventario: true,
    notas: true
  });

  const navItems = [
    { id: 'dashboard',    label: 'Dashboard',     icon: LayoutDashboard, isActive: currentPage === 'dashboard' },
    { id: 'cotizaciones', label: 'Cotizaciones',  icon: FileText,        isActive: currentPage === 'cotizaciones', visible: modulos.cotizaciones !== false },
    { id: 'trazabilidad', label: 'Trazabilidad',  icon: ClipboardList,   isActive: currentPage === 'trazabilidad' },
    { id: 'plantillas',   label: 'Plantillas',    icon: BookTemplate,    isActive: currentPage === 'plantillas', visible: modulos.cotizaciones !== false },
    { id: 'clientes',     label: 'Clientes',      icon: Users,           isActive: currentPage === 'clientes', visible: modulos.clientes !== false },
    { id: 'productos',    label: 'Productos',     icon: Package,         isActive: currentPage === 'productos', visible: modulos.productos !== false },
    { id: 'proveedores',  label: 'Proveedores',   icon: Users,           isActive: currentPage === 'proveedores' },
    { id: 'compras',      label: 'Compras Prov.', icon: Package,         isActive: currentPage === 'compras' },
    { id: 'cxc',          label: 'Cuentas x Cobrar', icon: DollarSign,   isActive: currentPage === 'cxc' },
    { id: 'cxp',          label: 'Cuentas x Pagar',  icon: DollarSign,   isActive: currentPage === 'cxp' },
    { id: 'calculadora',  label: 'Calculadora',   icon: Calculator,      isActive: currentPage === 'calculadora', visible: modulos.calculadora !== false },
    { id: 'inventario',   label: 'Inventario',    icon: Package,         isActive: currentPage === 'inventario', visible: modulos.inventario !== false },
    { id: 'notas',        label: 'Notas Rápidas', icon: ClipboardList,   isActive: currentPage === 'notas', visible: modulos.notas !== false },
    { id: 'equipo',       label: 'Equipo',        icon: Users,           isActive: currentPage === 'equipo' },
    { id: 'ajustes',      label: 'Configuración', icon: Settings,        isActive: currentPage === 'ajustes' },
  ].filter(item => item.visible !== false);

  return (
    <div className="flex flex-col h-full bg-background border-r border-white/[0.06]">
      {/* Logo */}
      <div className="flex items-center px-6 py-6 border-b border-white/[0.06]">
        <div className="flex items-center gap-3">
          <LogoIdeally size={32} />
          <div>
            <h1 className="font-bold text-xl text-white">Cotizador</h1>
            <p className="text-xs text-muted-foreground">Sistema de Gestión</p>
          </div>
        </div>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 px-4 py-6 overflow-y-auto">
        <div className="space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                className={`
                  w-full flex items-center gap-3 px-3 py-2.5 text-left rounded-lg font-medium transition-colors
                  ${item.isActive 
                    ? 'bg-accent-blue/10 text-accent-blue border border-accent-blue/20' 
                    : 'text-white/70 hover:bg-white/[0.04] hover:text-white'
                  }
                `}
              >
                <Icon className={`w-5 h-5 ${item.isActive ? 'text-accent-blue' : 'text-muted-foreground'}`} />
                {item.label}
              </button>
            );
          })}
        </div>
      </nav>

      {/* User Section */}
      <div className="p-4 border-t border-white/[0.06]">
        <div className="flex items-center gap-3 px-3 py-2 cursor-pointer hover:bg-white/[0.04] rounded-lg transition-colors" onClick={() => setProfileOpen(true)}>
          <div className="w-8 h-8 bg-accent-blue/20 rounded-full flex items-center justify-center flex-shrink-0 border border-accent-blue/30">
            <span className="text-sm font-medium text-accent-blue">{userInitial}</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-white truncate">{userName}</p>
            <p className="text-xs text-muted-foreground truncate">{userEmail}</p>
          </div>
          <button 
            onClick={(e) => { e.stopPropagation(); supabase.auth.signOut(); }}
            className="p-1 text-muted-foreground hover:text-accent-red transition-colors"
            title="Cerrar sesión"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          </button>
        </div>
      </div>

      <Dialog open={profileOpen} onOpenChange={setProfileOpen}>
        <DialogContent className="sm:max-w-[400px]">
          <DialogHeader>
            <DialogTitle>Mi Perfil</DialogTitle>
          </DialogHeader>
          <div className="py-4 space-y-4">
            <div className="space-y-2">
              <Label>Nombre de Usuario</Label>
              <Input value={nombre} onChange={e => setNombre(e.target.value)} placeholder="Ej. Juan Pérez" />
            </div>
            <div className="space-y-2">
              <Label>Correo Electrónico (No editable)</Label>
              <Input value={userEmail} disabled className="bg-gray-50" />
            </div>
          </div>
          <DialogFooter>
            <Button variant="outline" onClick={() => setProfileOpen(false)}>Cancelar</Button>
            <Button onClick={handleUpdateProfile}>Guardar Cambios</Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </div>
  );
}
export function ModernLayout({ children, currentPage, onNavigate, session, organizacion, loading }: ModernLayoutProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleNavigate = (page: string) => {
    onNavigate(page);
    setMobileMenuOpen(false);
  };

  return (
    <div className="flex h-screen bg-background">
      {/* Desktop Sidebar */}
      <div className="hidden lg:block w-64 flex-shrink-0">
        <ModernSideNav currentPage={currentPage} onNavigate={onNavigate} session={session} organizacion={organizacion} loading={loading} />
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden w-full">
        {/* Mobile Header */}
        <div className="lg:hidden flex items-center justify-between px-4 py-3 bg-background border-b border-white/[0.06]">
          <div className="flex items-center gap-3">
            <LogoIdeally size={28} />
            <div>
              <h1 className="font-bold text-lg text-white">Cotizador</h1>
            </div>
          </div>
          
          <Sheet open={mobileMenuOpen} onOpenChange={setMobileMenuOpen}>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="lg:hidden">
                <Menu className="h-6 w-6" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left" className="w-64 p-0">
              <SheetTitle className="sr-only">Menú de navegación</SheetTitle>
              <SheetDescription className="sr-only">
                Navega entre las diferentes secciones de la aplicación
              </SheetDescription>
              <ModernSideNav currentPage={currentPage} onNavigate={handleNavigate} session={session} organizacion={organizacion} loading={loading} />
            </SheetContent>
          </Sheet>
        </div>

        {/* Main Content Area */}
        <div className="flex-1 overflow-y-auto">
          <div className="p-4 sm:p-6">
            {children}
          </div>
        </div>
      </div>
    </div>
  );
}