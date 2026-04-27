import { Card, CardContent, CardHeader, CardTitle } from '../ui/card';
import { Button } from '../ui/button';
import { 
  Plus, 
  FileText, 
  Users, 
  Package, 
  Settings,
  Download,
  BarChart3
} from 'lucide-react';

interface QuickActionsProps {
  onNuevaCotizacion: () => void;
  onNavigate: (page: string) => void;
}

export function QuickActions({ onNuevaCotizacion, onNavigate }: QuickActionsProps) {
  const actions = [
    {
      id: 'nueva-cotizacion',
      title: 'Nueva Cotización',
      description: 'Crear una nueva cotización',
      icon: Plus,
      color: 'bg-blue-600 hover:bg-blue-700',
      onClick: onNuevaCotizacion
    },
    {
      id: 'ver-cotizaciones',
      title: 'Ver Cotizaciones',
      description: 'Gestionar cotizaciones existentes',
      icon: FileText,
      color: 'bg-gray-600 hover:bg-gray-700',
      onClick: () => onNavigate('cotizaciones')
    },
    {
      id: 'gestionar-clientes',
      title: 'Gestionar Clientes',
      description: 'Administrar base de clientes',
      icon: Users,
      color: 'bg-purple-600 hover:bg-purple-700',
      onClick: () => onNavigate('clientes')
    },
    {
      id: 'productos',
      title: 'Catálogo Productos',
      description: 'Administrar productos y servicios',
      icon: Package,
      color: 'bg-orange-600 hover:bg-orange-700',
      onClick: () => onNavigate('productos')
    }
  ];

  return (
    <Card>
      <CardHeader>
        <CardTitle className="flex items-center gap-2">
          <BarChart3 className="h-5 w-5 text-blue-600" />
          Acciones Rápidas
        </CardTitle>
      </CardHeader>
      <CardContent>
        <div className="grid gap-3 sm:grid-cols-2">
          {actions.map((action) => {
            const Icon = action.icon;
            return (
              <Button
                key={action.id}
                onClick={action.onClick}
                className={`${action.color} text-white p-4 h-auto flex-col items-center justify-center text-center space-y-2 min-h-[80px]`}
                variant="ghost"
              >
                <div className="flex items-center gap-2">
                  <Icon className="w-5 h-5" />
                  <span className="font-semibold">{action.title}</span>
                </div>
                <p className="text-xs text-white/95 text-center leading-tight">
                  {action.description}
                </p>
              </Button>
            );
          })}
        </div>
      </CardContent>
    </Card>
  );
}