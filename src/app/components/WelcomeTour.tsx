import { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from './ui/dialog';
import { Button } from './ui/button';
import { LayoutDashboard, Package, FileText, Users, Calculator, ArrowRight, Check } from 'lucide-react';
import { supabase } from '../../utils/supabase/client';

interface WelcomeTourProps {
  session: any;
}

export function WelcomeTour({ session }: WelcomeTourProps) {
  const [open, setOpen] = useState(false);
  const [step, setStep] = useState(0);

  useEffect(() => {
    if (!session?.user?.id) return;
    
    const hasSeenTour = localStorage.getItem(`has_seen_tour_${session.user.id}`);
    
    // Only show if user hasn't seen it and it has a username (or maybe we force it anyway)
    if (!hasSeenTour) {
      // Small delay to ensure smooth transition after login
      const timer = setTimeout(() => {
        setOpen(true);
      }, 1000);
      return () => clearTimeout(timer);
    }
  }, [session]);

  const handleClose = () => {
    if (session?.user?.id) {
      localStorage.setItem(`has_seen_tour_${session.user.id}`, 'true');
    }
    setOpen(false);
  };

  const steps = [
    {
      title: '¡Bienvenido a Ideally Platform!',
      description: 'Tu nuevo sistema de gestión de cotizaciones y operaciones. Vamos a dar un rápido recorrido por los módulos principales.',
      icon: <LayoutDashboard className="w-12 h-12 text-accent-blue mb-4" />
    },
    {
      title: 'Productos y Servicios',
      description: 'Crea tu catálogo con precios, costos y agrúpalos por categorías usando sus propias pestañas. ¡Las tarjetas tienen colores identificadores!',
      icon: <Package className="w-12 h-12 text-accent-green mb-4" />
    },
    {
      title: 'Directorio de Clientes',
      description: 'Gestiona tu base de prospectos y clientes. Añádeles un giro empresarial, múltiples contactos y dales seguimiento.',
      icon: <Users className="w-12 h-12 text-purple-500 mb-4" />
    },
    {
      title: 'Calculadora de Material',
      description: 'Obtén el costo exacto de tus piezas a partir de planchas o rollos en la nueva Calculadora dedicada de la barra lateral.',
      icon: <Calculator className="w-12 h-12 text-orange-500 mb-4" />
    },
    {
      title: 'Gestión de Cotizaciones',
      description: 'Crea propuestas profesionales, expórtalas a PDF o envíalas por correo a tus clientes en segundos. ¡Estás listo para vender más!',
      icon: <FileText className="w-12 h-12 text-accent-blue mb-4" />
    }
  ];

  return (
    <Dialog open={open} onOpenChange={(o) => { if(!o) handleClose(); }}>
      <DialogContent className="sm:max-w-[500px] text-center p-8">
        <div className="flex flex-col items-center justify-center min-h-[250px]">
          {steps[step].icon}
          <DialogHeader>
            <DialogTitle className="text-2xl font-bold mb-2">{steps[step].title}</DialogTitle>
          </DialogHeader>
          <p className="text-muted-foreground mt-4">{steps[step].description}</p>
        </div>
        
        <DialogFooter className="flex w-full sm:justify-between items-center mt-8">
          <div className="flex gap-1">
            {steps.map((_, i) => (
              <div key={i} className={`h-2 w-2 rounded-full ${i === step ? 'bg-white' : 'bg-white/20'}`} />
            ))}
          </div>
          
          <div className="flex gap-2 mt-4 sm:mt-0">
            {step > 0 && (
              <Button variant="ghost" onClick={() => setStep(step - 1)}>Anterior</Button>
            )}
            {step < steps.length - 1 ? (
              <Button onClick={() => setStep(step + 1)}>
                Siguiente <ArrowRight className="w-4 h-4 ml-2" />
              </Button>
            ) : (
              <Button className="bg-accent-blue text-black hover:bg-accent-blue/90" onClick={handleClose}>
                ¡Comenzar! <Check className="w-4 h-4 ml-2" />
              </Button>
            )}
          </div>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
