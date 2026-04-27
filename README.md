
  # Cotización App Admin

  This is a code bundle for Cotización App Admin. The original project is available at https://www.figma.com/design/5eQwPMYbkO1jb73yqB0Rz4/Cotizaci%C3%B3n-App-Admin.

  ## Running the code

  Run `npm i` to install the dependencies.

  Run `npm run dev` to start the development server.

  ## Variables de Entorno

  Para ejecutar este proyecto, es necesario crear un archivo `.env` en la raíz basándose en el archivo `.env.example`. 
  Las variables requeridas son:

  - `VITE_SUPABASE_URL`: URL del proyecto de Supabase.
  - `VITE_SUPABASE_ANON_KEY`: Clave pública (anon) del proyecto de Supabase.

  Otras variables para fases posteriores (documentadas en `.env.example`):
  - `RESEND_API_KEY`
  - `ANTHROPIC_API_KEY`
  - `FACTURAPI_API_KEY`
  - `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_WHATSAPP_FROM`
  - `WEBHOOK_SECRET`