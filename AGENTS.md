# Reglas y Checklist de Remolques (Antigravity Rules)

Este archivo contiene el contexto histórico y arquitectónico del proyecto "Remolques". Léelo SIEMPRE antes de planear, codificar o sugerir un despliegue.

## Arquitectura y Despliegue
- **Frontend (`remolques-web`)**: Aplicación en React/Vite.
- **Backend (`remolques-api`)**: Deno Edge Function empaquetada con Hono (`supabase/functions/make-server-feea4382/index.ts`). Corre en un servicio separado en EasyPanel.
- **Base de Datos**: Supabase Postgres.

## Checklist de Desarrollo y Prevención de Errores Comunes

### 1. Actualizaciones del Backend Deno
- El backend en EasyPanel **no se actualiza automáticamente**. Si modificas `supabase/functions/make-server-feea4382/index.ts`, debes pedirle explícitamente al usuario que vaya a EasyPanel y haga clic en **"Rebuild"** en el servicio del backend.
- **Error Común**: Olvidar instanciar el cliente de Supabase dentro de una nueva ruta Hono. Si inyectas un nuevo `app.get()` o `app.put()`, SIEMPRE incluye la línea `const supabase = c.get("supabase") as any;` al inicio del bloque `try`, de lo contrario el backend arrojará `400 Bad Request` por un `ReferenceError: supabase is not defined`.

### 2. Bases de Datos y Migraciones
- Las tablas y columnas **no se crean solas**. Si diseñas un módulo nuevo, asegúrate de proveer un script SQL (`.sql`) y pedirle al usuario que lo corra manualmente en su SQL Editor de Supabase. 
- No asumas que un script corrió completo si el usuario no te confirmó que todo salió en verde.

### 3. Parches de Archivos Grandes (Ej. `useSupabaseData.ts`)
- **NUNCA uses expresiones regulares codiciosas (`[\s\S]*?`)** al usar Node para modificar archivos. Esto ha causado que se borren funciones críticas del hook.
- En su lugar, usa `.replace('string exacto', 'nuevo string')`.

### 4. UI y Modo Claro/Oscuro
- **NUNCA uses colores fijos oscuros** como `bg-slate-900`, `bg-gray-800` o `text-gray-300`.
- Usa SIEMPRE variables semánticas de Tailwind:
  - Fondos: `bg-card`, `bg-background`, `bg-muted`
  - Textos: `text-foreground`, `text-muted-foreground`, `text-primary`
  - Bordes: `border-border`, `border-border/50`
- Esto garantiza que el sistema cambie correctamente entre Modo Claro y Oscuro.

### 5. Errores de Sintaxis en JSX (Vite)
- **NO escapes comillas invertidas (`\``) usando barras invertidas (`\` )** dentro de JSX. Vite lanzará un `SyntaxError: Invalid escape sequence`. Si necesitas un string literal dentro de props, usa las comillas simples o dobles cuando sea posible.
