# Handoff - Cotizacion App Admin

Fecha: 2026-04-27  
Repo GitHub: https://github.com/noescritor/cotizacion-app-admin  
Deploy app: https://cotizador-cotizacion-app.gehkp3.easypanel.host/  
Supabase project ref: `kntbzloxbfrklzgjnvzi`  
Edge Function: `make-server-feea4382`

## Estado actual

La app ya esta desplegada en Easypanel/Hostinger usando GitHub y Docker. El frontend carga correctamente desde el dominio temporal y ya conecta con Supabase.

El problema de "Modo sin conexion" fue corregido. La causa era doble:

1. El frontend hacia health check contra rutas protegidas usando `anon key`, lo que provocaba falso modo local.
2. La Edge Function en Supabase recibia rutas con prefijo `/make-server-feea4382/...` en algunos casos; al estar autenticado llegaba a 404 porque Hono esperaba `/clientes`, `/productos`, etc.

Tambien se corrigio el problema de plantillas:

- La tabla `plantillas_cotizacion` no tenia columna `con_factura`.
- Se agrego fallback en servidor para esquemas legacy.
- El usuario ejecuto SQL para agregar `con_factura`, `updated_at` y default de `items`.

## Cambios importantes realizados

### Deploy / Hosting

Archivos agregados:

- `Dockerfile`
- `nginx.conf`
- `.dockerignore`
- `.env.production`
- `public/.htaccess`

El `Dockerfile` hace build con Node y sirve `dist` con Nginx.  
`nginx.conf` tiene fallback SPA con `try_files $uri $uri/ /index.html`.

`.env.production` contiene solo variables publicas Vite:

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY`

No contiene `SUPABASE_SERVICE_ROLE_KEY`.

### GitHub

Se inicializo repo Git local y se creo repo privado con GitHub CLI:

```bash
gh repo create cotizacion-app-admin --private --source . --remote origin --push
```

Branch principal actual: `master`

Commits relevantes:

- `Prepare cotizacion app for Easypanel deploy`
- `Fix Supabase health endpoint`
- `Show data loading errors`
- `Improve data endpoint diagnostics`
- `Normalize Supabase function route prefix`
- `Fallback plantillas for legacy schema`
- `Fix cotizacion save error handling and item payload`
- `Harden frontend API responses and undefined routes`

### Easypanel

Servicio: `cotizador / cotizacion_app`

Configuracion usada:

- Fuente: GitHub
- Propietario: `noescritor`
- Repositorio: `cotizacion-app-admin`
- Rama: `master`
- Ruta de compilacion: `/`
- Compilacion: Dockerfile
- Archivo Dockerfile: `Dockerfile`
- Puerto interno: `80` cuando aplique

Dominio temporal:

```text
https://cotizador-cotizacion-app.gehkp3.easypanel.host/
```

### Supabase Edge Function

Archivo principal:

```text
supabase/functions/make-server-feea4382/index.ts
```

Cambios:

- Se agrego endpoint publico:

```ts
app.get("/health", (c) => c.json({ ok: true }));
app.get("/make-server-feea4382/health", (c) => c.json({ ok: true }));
```

- Se normalizo prefijo al final:

```ts
Deno.serve((req) => {
  const url = new URL(req.url);
  const prefix = "/make-server-feea4382";

  if (url.pathname.startsWith(`${prefix}/`)) {
    url.pathname = url.pathname.slice(prefix.length);
    return app.fetch(new Request(url.toString(), req));
  }

  return app.fetch(req);
});
```

- Se hizo ruta de generar portal autenticada aunque estaba declarada antes del middleware:

```text
POST /cotizaciones/:id/generar-token-portal
```

- Se agrego fallback para crear/editar plantillas si falta `con_factura` en DB.
- Se corrigio guardado de cotizaciones para no insertar campos de item inexistentes como columnas. Los campos extendidos de item se guardan en `metadata`.
- Si falla el insert de items al crear cotizacion, se elimina la cotizacion recien creada para evitar registros huerfanos sin conceptos.

Comando usado para desplegar:

```bash
npx.cmd supabase functions deploy make-server-feea4382 --project-ref kntbzloxbfrklzgjnvzi --no-verify-jwt
```

Verificacion:

```bash
curl.exe -i https://kntbzloxbfrklzgjnvzi.supabase.co/functions/v1/make-server-feea4382/health
```

Respuesta esperada:

```json
{"ok":true}
```

### Frontend data loading

Archivo:

```text
src/app/hooks/useSupabaseData.ts
```

Cambios:

- `getHeaders` ya no usa anon key como fallback para rutas protegidas.
- `loadData` espera a tener `session.access_token`.
- Health check usa `/health`.
- Se agrego `fetchJson(label, url, token)` para mostrar errores especificos por endpoint.
- Si falla `plantillas`, se atrapa por separado para no tirar toda la carga inicial.
- Se agrego `sendJson` para validar respuestas de mutaciones. Esto evita que errores del backend se agreguen como clientes/productos/cotizaciones validas.
- `crearCotizacion` valida que la respuesta tenga `id` y `folio` antes de agregarla al estado.

Archivo:

```text
src/app/App.tsx
```

Cambios:

- Se agrego `serverError` al toast de modo local.
- Se agrego ruta publica `/cotizacion/:token` antes del login y tambien con sesion activa.
- Se agrego handler `manejarGenerarTokenPortal`.
- Se agrego validacion antes de navegar a una cotizacion creada.
- Se agrego redireccion para URLs invalidas como `/cotizaciones/undefined`, `/cotizaciones/null`, y rutas equivalentes de editar/PDF.

### Portal de cliente

Archivo:

```text
src/app/components/Portal/PortalCliente.tsx
```

Estado:

- Existe componente publico.
- Ruta frontend: `/cotizacion/:token`
- Usa endpoints publicos:
  - `GET /portal/:token`
  - `POST /portal/:token/aprobar`
  - `POST /portal/:token/rechazar`
  - `POST /portal/:token/solicitar-cambios`

Archivo:

```text
src/app/components/Cotizaciones/CotizacionDetalle.tsx
```

Cambios:

- Boton `Generar Portal` / `Copiar Portal`.
- Copia link al portapapeles.
- Usa `onGenerarTokenPortal`.

### Tipos

Archivo:

```text
src/app/types/index.ts
```

Campos agregados a `Cotizacion`:

- `token_publico`
- `token_expira_en`
- `firma_imagen`
- `firma_nombre`
- `firma_fecha`
- `firma_ip`
- `comentario_cliente`

### Migraciones

Archivo agregado:

```text
supabase/migrations/20260427_05_fix_plantillas_schema.sql
```

Contenido principal:

```sql
ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS con_factura BOOLEAN DEFAULT true;
ALTER TABLE plantillas_cotizacion ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT now();
ALTER TABLE plantillas_cotizacion ALTER COLUMN items SET DEFAULT '[]';

DROP POLICY IF EXISTS "plantillas_auth_all" ON plantillas_cotizacion;
CREATE POLICY "plantillas_auth_all"
  ON plantillas_cotizacion FOR ALL
  USING (auth.uid() IS NOT NULL)
  WITH CHECK (auth.uid() IS NOT NULL);
```

El usuario ya indico que ejecuto el SQL para agregar columnas de plantillas.

Archivo agregado:

```text
supabase/migrations/20260427_06_items_metadata_columns.sql
```

Agrega columnas extendidas opcionales a `items_cotizacion`:

```sql
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS numero_proyecto TEXT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS incluir_setup BOOLEAN;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS meses_cobrados INT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS asientos_extra INT;
ALTER TABLE items_cotizacion ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;
```

El backend ya no depende de estas columnas para guardar: usa `metadata` para compatibilidad.

## Cosas pendientes / revisar

1. Confirmar que guardar plantilla ya funciona despues del SQL.
2. Probar flujo completo:
   - Crear cliente
   - Crear producto
   - Crear cotizacion
   - Guardar como plantilla
   - Usar plantilla en nueva cotizacion
   - Generar portal
   - Abrir link publico
   - Aprobar con firma
3. Configurar URL de Supabase Auth si aun no se hizo:

Supabase Dashboard -> Authentication -> URL Configuration

Site URL:

```text
https://cotizador-cotizacion-app.gehkp3.easypanel.host
```

Redirect URLs:

```text
https://cotizador-cotizacion-app.gehkp3.easypanel.host
https://cotizador-cotizacion-app.gehkp3.easypanel.host/**
```

4. Configurar secretos opcionales en Supabase:

- `RESEND_API_KEY` para email
- `ANTHROPIC_API_KEY` para IA Claude
- `OPENAI_API_KEY` si se implementa fallback real a OpenAI

5. El contexto dice "Claude & OpenAI", pero el codigo actual solo usa Anthropic.
6. Hay texto con encoding roto en varios archivos (`CotizaciÃ³n`, `DiseÃ±o`, etc.). No bloquea, pero conviene limpiar.
7. La CLI de migraciones fallo por falta de permisos/password:

```text
SUPABASE_DB_PASSWORD
```

Por ahora las migraciones se aplican manualmente desde SQL Editor.

## Comandos utiles

Build local:

```bash
npm.cmd run build
```

Deploy Edge Function:

```bash
npx.cmd supabase functions deploy make-server-feea4382 --project-ref kntbzloxbfrklzgjnvzi --no-verify-jwt
```

Probar health:

```bash
curl.exe -i https://kntbzloxbfrklzgjnvzi.supabase.co/functions/v1/make-server-feea4382/health
```

Push a GitHub:

```bash
git add .
git commit -m "mensaje"
git push
```

Deploy frontend:

- Easypanel -> servicio `cotizacion_app` -> boton verde `Implementar`.

## Advertencias

- No subir `.env` a GitHub.
- No poner `SUPABASE_SERVICE_ROLE_KEY` en Easypanel ni en frontend.
- Las variables secretas de la Edge Function van en Supabase -> Edge Functions -> Secrets.
- El anon key en `.env.production` es publico por diseno de Supabase y Vite.
