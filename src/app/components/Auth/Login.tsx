import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';
import { supabase } from '../../utils/supabase/client';
import { LogoIdeally } from '../Cotizaciones/LogoIdeally';

export function Login() {
  return (
    <div className="flex min-h-screen bg-background text-foreground selection:bg-accent-blue/30">
      {/* Left panel - Branding */}
      <div className="hidden lg:flex flex-col justify-between w-1/2 p-12 bg-black/40 border-r border-white/5 relative overflow-hidden">
        <div className="absolute inset-0 bg-gradient-to-br from-accent-blue/10 via-transparent to-accent-green/10 z-0"></div>
        <div className="absolute top-[-20%] left-[-10%] w-[70%] h-[70%] rounded-full bg-accent-blue/5 blur-[120px] pointer-events-none"></div>
        
        <div className="relative z-10 flex items-center gap-3">
          <LogoIdeally size={40} className="text-white" />
          <h1 className="font-bold text-2xl tracking-tight text-white">Ideally</h1>
        </div>
        
        <div className="relative z-10 max-w-md">
          <h2 className="text-4xl font-bold font-sans text-white mb-6 leading-tight">
            El sistema de <span className="text-transparent bg-clip-text bg-gradient-to-r from-accent-blue to-accent-green">cotizaciones</span> que tu negocio necesita.
          </h2>
          <p className="text-lg text-white/60 font-medium">
            Agiliza tus procesos, gestiona tus clientes y cierra más ventas desde una sola plataforma.
          </p>
        </div>
        
        <div className="relative z-10 text-sm text-white/40 font-mono">
          &copy; {new Date().getFullYear()} Ideally Platform. Todos los derechos reservados.
        </div>
      </div>

      {/* Right panel - Auth Form */}
      <div className="w-full lg:w-1/2 flex items-center justify-center p-8 relative">
        <div className="absolute top-0 right-0 w-full h-full bg-[radial-gradient(ellipse_at_top_right,_var(--tw-gradient-stops))] from-accent-blue/5 via-background to-background pointer-events-none"></div>
        
        <div className="w-full max-w-md space-y-8 relative z-10">
          <div className="text-center lg:text-left">
            <div className="flex lg:hidden justify-center mb-8">
              <LogoIdeally size={48} className="text-white" />
            </div>
            <h2 className="text-3xl font-bold tracking-tight text-white">Bienvenido de vuelta</h2>
            <p className="mt-2 text-sm text-muted-foreground">
              Ingresa a tu cuenta para continuar
            </p>
          </div>
          
          <div className="mt-8 bg-white/[0.02] border border-white/[0.06] p-8 rounded-2xl shadow-2xl backdrop-blur-sm">
            <Auth
              supabaseClient={supabase}
              appearance={{
                theme: ThemeSupa,
                variables: {
                  default: {
                    colors: {
                      brand: '#3b82f6', // accent-blue
                      brandAccent: '#2563eb',
                      inputText: 'white',
                      inputBackground: 'rgba(255,255,255,0.03)',
                      inputBorder: 'rgba(255,255,255,0.1)',
                      inputBorderHover: 'rgba(255,255,255,0.2)',
                      inputBorderFocus: '#3b82f6',
                      inputLabelText: 'rgba(255,255,255,0.7)',
                      defaultButtonBackground: 'rgba(255,255,255,0.05)',
                      defaultButtonBackgroundHover: 'rgba(255,255,255,0.1)',
                      defaultButtonBorder: 'rgba(255,255,255,0.1)',
                      defaultButtonText: 'white',
                      dividerBackground: 'rgba(255,255,255,0.1)',
                      anchorTextColor: 'rgba(255,255,255,0.6)',
                      anchorTextHoverColor: 'white',
                    },
                    radii: {
                      borderRadiusButton: '0.5rem',
                      buttonBorderRadius: '0.5rem',
                      inputBorderRadius: '0.5rem',
                    },
                    space: {
                      inputPadding: '0.75rem 1rem',
                      buttonPadding: '0.75rem 1rem',
                    },
                    fonts: {
                      bodyFontFamily: 'Inter, sans-serif',
                      buttonFontFamily: 'Inter, sans-serif',
                      inputFontFamily: 'Inter, sans-serif',
                      labelFontFamily: 'Inter, sans-serif',
                    }
                  },
                },
                className: {
                  button: 'font-medium transition-colors',
                  input: 'transition-colors',
                  label: 'font-medium text-xs uppercase tracking-wider',
                  anchor: 'text-sm font-medium transition-colors',
                }
              }}
              providers={[]}
              localization={{
                variables: {
                  sign_in: {
                    email_label: 'Correo electrónico',
                    password_label: 'Contraseña',
                    button_label: 'Ingresar',
                    loading_button_label: 'Ingresando...',
                    social_provider_text: 'Ingresar con {{provider}}',
                    link_text: '¿Ya tienes una cuenta? Ingresa',
                    email_input_placeholder: 'ejemplo@correo.com',
                    password_input_placeholder: 'Tu contraseña',
                  },
                  sign_up: {
                    email_label: 'Correo electrónico',
                    password_label: 'Contraseña',
                    button_label: 'Registrarse',
                    loading_button_label: 'Registrando...',
                    social_provider_text: 'Registrarse con {{provider}}',
                    link_text: '¿No tienes cuenta? Regístrate',
                    email_input_placeholder: 'ejemplo@correo.com',
                    password_input_placeholder: 'Tu contraseña',
                  },
                  forgotten_password: {
                    link_text: '¿Olvidaste tu contraseña?',
                    button_label: 'Recuperar contraseña',
                    loading_button_label: 'Enviando...',
                    confirmation_text: 'Revisa tu correo para recuperar tu contraseña',
                    email_label: 'Correo electrónico',
                    email_input_placeholder: 'ejemplo@correo.com',
                  }
                },
              }}
            />
          </div>
        </div>
      </div>
    </div>
  );
}
