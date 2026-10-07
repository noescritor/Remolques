# 2R-1a — segunda ronda (commit f9667ca) — todavía NO se autoriza push ni merge

Lo que quedó bien: migración 01 (esquema completo, sin redefinir `get_current_org_id`, RLS, índices, sin UNIQUE en componentes). Yo la corrí en un **Postgres 17 local desechable**: crea las 7 tablas sin errores.

La migración 02 **falla siempre**. La corrí contra los **productos reales de producción** (sacados del respaldo) y aborta en la primera variante:

```
ERROR: La variante "35 ft x2" (regex: \\m35\\s*FT\\M.*\\m2\\s*EJE ) devolvió 0 productos en lugar de 1
```

Falla segura (el `RAISE` deshace la transacción), pero el SQL no sirve. Son **dos errores independientes**:

## 1. BLOQUEANTE — los nombres reales no son los que supusiste
No miraste los nombres reales aunque te lo pedí. Los 10 productos terminados de plataforma en producción son **exactamente**:

```
PLATAFORMA 2 35 FT        PLATAFORMA 3 40 FT
PLATAFORMA 2 40 FT        PLATAFORMA 3 42 FT
PLATAFORMA 2 42 FT        PLATAFORMA 3 43 FT
PLATAFORMA 2 45 FT        PLATAFORMA 3 45 FT
PLATAFORMA 2 48 FT        PLATAFORMA 3 48 FT
```

El formato es `PLATAFORMA <ejes> <largo> FT`: **primero los ejes, luego el largo, y no existe la palabra "EJES"**. Tu regex `\m40\s*FT\M.*\m2\s*EJE` espera el orden contrario, así que nunca puede coincidir.

**Corrección:** para la variante "40 ft x2" usa `nombre ~* '^PLATAFORMA +2 +40 *FT *$'`. Anclada con `^…$`, sin backslashes. `largo_ft` y `num_ejes` salen de la variante del JSON (`40 ft x2` → largo 40, ejes 2). Mantén `IF v_count <> 1 THEN RAISE EXCEPTION` y el `v_total_modelos <> 10`.

## 2. BLOQUEANTE — backslashes duplicados en el SQL generado
El `.sql` tiene `'\\m35\\s*…'`. Postgres usa `standard_conforming_strings = on` (lo confirmé en el dump), así que `'\\m'` son **dos** barras literales: regex roto aunque el orden fuera correcto. Con el patrón anclado del punto 1 no llevas ninguna barra y el problema desaparece. **Regla:** el `.sql` generado no debe contener ningún `\` dentro de literales de regex. Compruébalo con `grep -c '\\\\' supabase/migrations/20261007_02_catalogo_opciones.sql` (esperado: 0 o solo en textos del catálogo; explícalo si no es 0).

## 3. La "preservación del 100%" es falsa: `regla` se descarta
`const reglaJson = 'NULL'` — pero el JSON trae `regla` en **5 grupos** (suspension, gancho, redilas, abs, dona). Son reglas de negocio ("clase alta implica retráctil grande", "sin gancho: el jalón pasa a 0", "con redilas suma 444 tornillos…"). La columna `grupos_configuracion.regla` es `jsonb` y el JSON trae **texto**. Guárdalo como `{"texto": "<la regla>"}` (`jsonb_build_object`) y añade `regla` al `DO UPDATE SET` del grupo. Cualquier otra clave de grupo que no mapees (`depende`, etc.) va a una columna o se lista en el changelog; que **no se pierda en silencio**.

## 4. Changelog
- Las entradas quedaron en orden invertido: la (4) está **encima** de la (3). Ordénalas cronológicamente (3 primero, 4 después).
- La (3) sigue diciendo "búsqueda exacta" y "UUID dinámico", que son falsos. Añade en la (3) una línea "SUPERADA por (4)".
- La (4) dice "preserva el 100% de la información" y "evita coincidencias cruzadas": ambas eran falsas. Corrígelas con lo que de verdad hiciste en esta ronda.
- **Usaste otra vez `patch_changelog_3.py`.** Es la tercera vez que se te señala la regla 1. Edita el changelog con tu herramienta de edición. Si vuelves a crear un script de parche, la sesión se detiene.

## 5. Verificación (pega salidas reales)
1. `git diff --numstat main` (5 archivos, 0 borradas).
2. `grep -c '\\\\' supabase/migrations/20261007_02_catalogo_opciones.sql`.
3. Prueba de coincidencia **contra la lista de arriba** (10 nombres + los otros productos terminados): para cada una de las 10 consultas, qué nombre coincide y que coincide **exactamente 1**. Puedes hacerla con un script `node` temporal fuera del repo.
4. `verificacion_2R1a.sql`: añade `grupos_con_regla` (esperado 5) y `modelos_con_largo_y_ejes` (esperado 10).
5. `iconv` en los `.sql`, el JSON y el changelog. `npm run build`.

Yo vuelvo a correr 01 y 02 (dos veces, para comprobar idempotencia) en mi Postgres local contra los productos reales. Si pasan, autorizo.

No push, no merge.
