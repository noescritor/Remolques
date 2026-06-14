import { ReactNode, useState } from 'react';
import {
  LayoutDashboard,
  FileText,
  Users,
  Package,
  Settings,
  BookTemplate,
  Menu,
  X
} from 'lucide-react';
import { LogoIdeally } from './Cotizaciones/LogoIdeally';
import { Sheet, SheetContent, SheetTrigger, SheetTitle, SheetDescription } from './ui/sheet';
import { Button } from './ui/button';
import { supabase } from '../utils/supabase/client';

interface ModernLayoutProps {
  children: ReactNode;
  currentPage: string;
  onNavigate: (page: string) => void;
}

function ModernSideNav({ currentPage, onNavigate }: { currentPage: string; onNavigate: (page: string) => void }) {
  const navItems = [
    { id: 'dashboard',    label: 'Dashboard',     icon: LayoutDashboard, isActive: currentPage === 'dashboard' },
    { id: 'cotizaciones', label: 'Cotizaciones',   icon: FileText,        isActive: currentPage === 'cotizaciones' },
    { id: 'plantillas',   label: 'Plantillas',     icon: BookTemplate,    isActive: currentPage === 'plantillas' },
    { id: 'clientes',     label: 'Clientes',       icon: Users,           isActive: currentPage === 'clientes' },
    { id: 'productos',    label: 'Productos',      icon: Package,         isActive: currentPage === 'productos' },
    { id: 'inventario',   label: 'Inventario',     icon: Package,         isActive: currentPage === 'inventario' },
    { id: 'equipo',       label: 'Equipo',         icon: Users,           isActive: currentPage === 'equipo' },
    { id: 'ajustes',      label: 'Configuración',  icon: Settings,        isActive: currentPage === 'ajustes' },
  ];

  return (
    <div className="flex flex-col h-full bg-white border-r border-gray-200">
      {/* Logo */}
      <div className="flex items-center px-6 py-6 border-b border-gray-200">
        <div className="flex items-center gap-3">
          <LogoIdeally size={32} />
          <div>
            <h1 className="font-bold text-xl text-gray-900">Cotizador</h1>
            <p className="text-xs text-gray-500">Sistema de Gestión</p>
          </div>
        </div>
      </div>

      {/* Navigation Items */}
      <nav className="flex-1 px-4 py-6">
        <div className="space-y-2">
          {navItems.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => onNavigate(item.id)}
                className={`
                  w-full flex items-center gap-3 px-3 py-2.5 text-left rounded-lg font-medium transition-colors
                  ${item.isActive 
                    ? 'bg-blue-50 text-blue-700 border border-blue-200' 
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                  }
                `}
              >
                <Icon className={`w-5 h-5 ${item.isActive ? 'text-blue-600' : 'text-gray-400'}`} />
                {item.label}
              </button>
            );
          })}
        </div>
      </nav>

      {/* User Section */}
      <div className="p-4 border-t border-gray-200">
        <div className="flex items-center gap-3 px-3 py-2">
          <div className="w-8 h-8 bg-purple-100 rounded-full flex items-center justify-center">
            <span className="text-sm font-medium text-purple-700">U</span>
          </div>
          <div className="flex-1 min-w-0">
            <p className="text-sm font-medium text-gray-900 truncate">Usuario</p>
          </div>
          <button 
            onClick={() => supabase.auth.signOut()}
            className="p-1 text-gray-400 hover:text-red-600 transition-colors"
            title="Cerrar sesión"
          >
            <svg xmlns="http://www.w3.org/2000/svg" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round"><path d="M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4"></path><polyline points="16 17 21 12 16 7"></polyline><line x1="21" y1="12" x2="9" y2="12"></line></svg>
          </button>
        </div>
      </div>
    </div>
  );
}

export function ModernLayout({ children, currentPage, onNavigate }: ModernLayoutProps) {
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  const handleNavigate = (page: string) => {
    onNavigate(page);
    setMobileMenuOpen(false);
  };

  return (
    <div className="flex h-screen bg-gray-50">
      {/* Desktop Sidebar */}
      <div className="hidden lg:block w-64 flex-shrink-0">
        <ModernSideNav currentPage={currentPage} onNavigate={onNavigate} />
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden w-full">
        {/* Mobile Header */}
        <div className="lg:hidden flex items-center justify-between px-4 py-3 bg-white border-b border-gray-200">
          <div className="flex items-center gap-3">
            <LogoIdeally size={28} />
            <div>
              <h1 className="font-bold text-lg text-gray-900">Cotizador</h1>
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
              <ModernSideNav currentPage={currentPage} onNavigate={handleNavigate} />
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