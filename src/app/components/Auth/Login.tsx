import { Auth } from '@supabase/auth-ui-react';
import { ThemeSupa } from '@supabase/auth-ui-shared';
import { supabase } from '../../utils/supabase/client';

export function Login() {
  return (
    <div className="flex items-center justify-center min-h-screen bg-gray-50">
      <div className="w-full max-w-md p-8 space-y-8 bg-white rounded-xl shadow-lg">
        <div className="text-center">
          <h2 className="text-3xl font-bold tracking-tight text-gray-900">Bienvenido</h2>
          <p className="mt-2 text-sm text-gray-600">
            Ingresa a la plataforma de administración de cotizaciones
          </p>
        </div>
        <div className="mt-8">
          <Auth
            supabaseClient={supabase}
            appearance={{
              theme: ThemeSupa,
              variables: {
                default: {
                  colors: {
                    brand: '#7c3aed',
                    brandAccent: '#6d28d9',
                  },
                },
              },
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
                  email_input_placeholder: 'Tu correo',
                  password_input_placeholder: 'Tu contraseña',
                },
                sign_up: {
                  email_label: 'Correo electrónico',
                  password_label: 'Contraseña',
                  button_label: 'Registrarse',
                  loading_button_label: 'Registrando...',
                  social_provider_text: 'Registrarse con {{provider}}',
                  link_text: '¿No tienes cuenta? Regístrate',
                  email_input_placeholder: 'Tu correo',
                  password_input_placeholder: 'Tu contraseña',
                },
                forgotten_password: {
                  link_text: '¿Olvidaste tu contraseña?',
                  button_label: 'Recuperar contraseña',
                  loading_button_label: 'Enviando instrucciones...',
                  confirmation_text: 'Revisa tu correo para recuperar tu contraseña',
                  email_label: 'Correo electrónico',
                  email_input_placeholder: 'Tu correo',
                }
              },
            }}
          />
        </div>
      </div>
    </div>
  );
}
