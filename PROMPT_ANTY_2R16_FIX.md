# Prompt para Anty — 2R-16 correcciones (revisión de `bloque-2r-16`, commit f6082f2)

Revisé tu rama con Postgres 17 y el esquema real. **Lo bueno, medido:** la migración corre dos veces con los mismos conteos (4 políticas, 13 índices, 4 restricciones en `proveedores`); `verificacion_2R16.sql` da todo `true`; `prueba_2R16.sql` pasa y deja 0 filas tras el ROLLBACK; con dos organizaciones, una factura/pago de otra organización da `no_encontrada`/`no_encontrado`, un usuario no ve filas de la otra organización ni en la vista, `anon` ve 0 filas y `authenticated` no puede ejecutar las funciones; dos pagos simultáneos a la misma factura (dos sesiones) dejan 1 solo pago (el segundo espera y recibe `excede_saldo`); el índice único rechaza `sucursal` NULL contra `''`; las pruebas Deno dan 196 pasan, 0 fallan **sobre un checkout limpio de tu commit**; los 52 errores de `tsc` están todos en archivos que no tocaste (ninguno en los `Cxp*` ni en `cuentasPorPagar.ts`). **Pero no está listo para producción: hay un bloqueante.**

## Reglas (las de siempre)
Mismo `bloque-2r-16`, **commits nuevos encima** (nada de `--amend`, `reset`, `checkout`, `restore`, `stash`, `commit -am`, `git add -A`). Edita solo con tu herramienta de edición (nada de `sed`, `node -e`, `deno eval`, PowerShell `Set-Content`). **No ejecutes SQL contra producción.** Registra en `CHANGELOG_ANTIGRAVITY.md`. No hagas merge hasta que yo diga "APROBADO".

## 1. (ALTA, bloqueante) Registrar y anular pagos fallan en producción: se llaman con el cliente del usuario
`index.ts` pasa `c.get("supabase")` a `registrarPago` y `anularPago`, y el motor hace `supabase.rpc("registrar_pago_factura", …)` / `supabase.rpc("anular_pago_factura", …)` (`motor/cuentas_por_pagar.ts` ~705 y ~752). Ese cliente es el del **usuario** (llave anon + su token, rol `authenticated`: ver el `authMiddleware`, `createClient(supabaseUrl, supabaseAnonKey, …)`), y tu migración hace `REVOKE ALL … FROM PUBLIC, anon, authenticated` y `GRANT EXECUTE … TO service_role`. Lo comprobé en Postgres: con el rol `authenticated` la función responde `insufficient_privilege`. Resultado en producción: **todo pago y toda anulación devolverían error** (`Error RPC registrar_pago_factura: permission denied…`). Las pruebas con cliente falso no lo detectan.
- Haz como en `plan_produccion.ts`: `registrarPago` y `anularPago` reciben un `serviceClient` (`getServiceClient()` desde la ruta) y llaman el RPC con ese. La organización ya viaja en `p_org` desde el contexto, así que no cambia el aislamiento.
- Prueba Deno nueva: un cliente falso "de usuario" cuyo `.rpc()` falla con `permission denied` y un `serviceClient` falso que sí responde; verifica que el RPC se llamó **solo** en el `serviceClient` (y que con el cliente de usuario no se llama).
- Busca cualquier otro `.rpc(` en tu código nuevo y confirma por escrito qué cliente usa.

## 2. (MEDIA) "Hoy" se calcula en UTC, no en hora local
Pedí fechas locales sin conversión UTC. Después de las 18:00 hora de México, `new Date().toISOString().slice(0, 10)` ya devuelve el día siguiente:
- Backend: `obtenerResumenCxp`, `listarFacturas` (`hoyStr`) y `obtenerConciliacionProveedor` usan UTC para el corte por omisión y para `dias_atraso`/`estado_calculado` (una factura aparece "vencida" un día antes). Haz que `listarFacturas` acepte `?corte=YYYY-MM-DD` (la pantalla lo manda con su fecha local) y que el valor por omisión sea la fecha de `America/Mexico_City` (`Intl.DateTimeFormat('en-CA', { timeZone: 'America/Mexico_City' })`).
- Pantalla: reemplaza todos los `new Date().toISOString().slice(0, 10)` de `CuentasPorPagarMain.tsx` (líneas ~38 y ~139; la variable se llama `hoyLocal` pero es UTC), `CxpFacturasTab.tsx` (~70, 84, 151, 234) y `CxpConciliacionTab.tsx` (~21) por un helper `fechaLocalISO(d = new Date())` que arme `YYYY-MM-DD` con `getFullYear/getMonth/getDate` (ponlo en `cuentasPorPagar.ts`, con prueba: `2026-10-29 23:30` local → `2026-10-29`).

## 3. (MEDIA) Montos que hoy caen en `500` o se pasan por alto
- Pago de `0.004`: la función lo acepta (`> 0`), el redondeo a 2 decimales lo deja en 0.00 y salta `pagos_factura_monto_check` (23514) como error crudo. En la migración (aún no está en producción, la puedes editar) redondea al principio de `registrar_pago_factura`: `p_monto := round(p_monto, 2);` y que `<= 0` siga devolviendo `monto_invalido`. En el backend valida `Number.isFinite`, `>= 0.01` y redondea a 2 decimales antes del RPC (pago, importe de factura, límite de crédito, saldo de estado de cuenta); `tipo_cambio` finito y `> 0`; `dias_credito` entero (`Number.isInteger`) y `>= 0`. Todo `400`.
- Pruebas Deno: `0.004`, `Infinity`, `NaN`, `"abc"`, `dias_credito = 30.5`.
- Tras editar la migración, vuelve a entregar `prueba_2R16.sql` con un caso para `0.004` y `99.996` (debe aceptar y guardar 100.00 cuando el saldo es 100.00).

## 4. (MEDIA) Los errores inesperados salen como `400` con el mensaje crudo
Todas las rutas hacen `return c.json({ error: err.message }, err.status || 400)`. Un fallo de base de datos (por ejemplo `Error RPC … permission denied…`) se responde como `400` y se expone el texto interno. Crea un helper de respuesta de error: si el error trae `status` (los que lanzas tú) úsalo; si no, registra el error con `console.error` y responde `500` con un mensaje genérico ("No se pudo completar la operación"). Prueba Deno: un error sin `status` → `500` sin el texto interno.

## 5. (BAJA) Tope de 1000 filas de PostgREST
`obtenerResumenCxp` trae **todas** las facturas no canceladas (también las pagadas) sin paginar; PostgREST corta en 1000 sin avisar y el resumen quedaría subestimado con el tiempo. Haz que el resumen y la conciliación pidan solo lo necesario (facturas con saldo > 0 vía `v_facturas_proveedor_saldo` con `.gt("saldo", 0)`, o paginación con `.range()` hasta agotar) y que `listarFacturas` devuelva `truncado: true` cuando llegue a 500 y la pantalla lo avise. Mismo cuidado en `listarPagos` (200).

## 6. Corrige tu reporte
- La comprobación "checkout limpio de HEAD" de tu `verificar` corrió **antes** del commit (salió 180, que son las pruebas de `main`). Vuelve a correr `npm run verificar -- --limpio` **después** de commitear la corrección y pega la salida: la sección 9 debe mostrar las pruebas nuevas (≥ 196).
- `tsc`: dime cuánto da `main` en tu máquina. Yo conté 52 en tu rama y ninguno está en archivos nuevos o modificados por ti, pero mi criterio decía 51; confirma si el 52 ya estaba en `main`.
- Hoja `CADECO `: las filas con folio `114xxxxx` son la 2 a la 18 y las de folio `21xxx` la 19 a la 31 (no 6-18 / 19-31).
- Hoja `2-BASE DATOS`: las columnas `Status Pago` y `Cobrador` **no existen**. Las reales son `ESTADO`, `PROCESO COBRANZA`, `COMENTARIOS DE ESTATUS DE COBRANZA`, `TIPO DE FACTURA`, `COMPLEMETO DE PAGO`, `TIPO DE CAMBIO FECHA DE PAGO`, etc. Corrígelo.
- Conclusión "cada abono corresponde a una factura": no citaste hoja ni fila. En `NOTAS Y FACTURAS` hay celdas llenas en `RELACION FACTURA` (por ejemplo `GARROM` filas 5 a 8 con `4490`/`UI-4490`, `TROGRIM` fila 9 con `61408`, `BENJA` filas 6 y 7 con `NOTA N° 19970+`). Revísalas y dime, con hoja y fila, si algún abono o nota cubre **varias** facturas. **No cambies el modelo**: solo repórtalo y yo decido.

## Verificación (pega salidas reales)
1. `npm run verificar -- --limpio` completo, **después** del commit nuevo, con `RESULTADO: TODO OK`.
2. `git diff --numstat main` y el hash del commit nuevo.
3. Las pruebas Deno nuevas con su salida real (incluida la del punto 1).
4. Si cambiaste la migración: exactamente qué cambió en `registrar_pago_factura` (yo la corro de nuevo dos veces con dos organizaciones).
5. Lo que **no** pudiste ver renderizado (di claramente que no abriste la pantalla en un navegador).
