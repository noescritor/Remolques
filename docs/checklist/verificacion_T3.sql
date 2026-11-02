-- Verificación de esquema y contratos para T3 (Checklist de entregas almacén)
-- Debe retornar todo_ok = true

WITH conteos AS (
    SELECT
        (SELECT count(*) FROM information_schema.tables WHERE table_name = 'orden_despiece_lineas') AS tiene_lineas,
        (SELECT count(*) FROM information_schema.tables WHERE table_name = 'orden_despiece_entregas') AS tiene_entregas,
        (SELECT count(*) FROM information_schema.views WHERE table_name = 'v_orden_despiece_avance') AS tiene_vista,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'registrar_entrega_despiece') AS tiene_fn_entrega,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'anular_entrega_despiece') AS tiene_fn_anular
)
SELECT
    tiene_lineas,
    tiene_entregas,
    tiene_vista,
    tiene_fn_entrega,
    tiene_fn_anular,
    (tiene_lineas = 1 AND tiene_entregas = 1 AND tiene_vista = 1 AND tiene_fn_entrega = 1 AND tiene_fn_anular = 1) AS todo_ok
FROM conteos;
