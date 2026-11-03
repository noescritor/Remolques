-- Verificación de esquema y contratos para T3 (Checklist de entregas almacén)
-- Debe retornar todo_ok = true

WITH conteos AS (
    SELECT
        (SELECT count(*) FROM information_schema.tables WHERE table_name = 'orden_despiece_lineas') AS tiene_lineas,
        (SELECT count(*) FROM information_schema.tables WHERE table_name = 'orden_despiece_entregas') AS tiene_entregas,
        (SELECT count(*) FROM information_schema.views WHERE table_name = 'v_orden_despiece_avance') AS tiene_vista,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'registrar_entrega_despiece') AS tiene_fn_entrega,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'anular_entrega_despiece') AS tiene_fn_anular,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'ajustar_cantidad_despiece') AS tiene_fn_ajustar,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'eliminar_linea_despiece') AS tiene_fn_eliminar,
        (SELECT count(*) FROM information_schema.routines WHERE routine_name = 'entregar_fase_despiece') AS tiene_fn_entregar_fase,
        (SELECT count(*) FROM information_schema.columns WHERE table_name = 'orden_despiece_entregas' AND column_name = 'orden_trabajo_id') AS tiene_col_ot_en_entregas,
        (SELECT count(*) FROM information_schema.triggers WHERE trigger_name = 'trg_lineas_requerida_vs_entregada') AS tiene_trigger,
        (SELECT count(*) FROM pg_policies WHERE tablename IN ('orden_despiece_lineas', 'orden_despiece_entregas') AND cmd <> 'SELECT') AS politicas_no_select
)
SELECT
    tiene_lineas,
    tiene_entregas,
    tiene_vista,
    tiene_fn_entrega,
    tiene_fn_anular,
    tiene_fn_ajustar,
    tiene_fn_eliminar,
    tiene_fn_entregar_fase,
    tiene_col_ot_en_entregas,
    tiene_trigger,
    politicas_no_select,
    (
        tiene_lineas = 1 AND
        tiene_entregas = 1 AND
        tiene_vista = 1 AND
        tiene_fn_entrega = 1 AND
        tiene_fn_anular = 1 AND
        tiene_fn_ajustar = 1 AND
        tiene_fn_eliminar = 1 AND
        tiene_fn_entregar_fase = 1 AND
        tiene_col_ot_en_entregas = 1 AND
        tiene_trigger = 1 AND
        politicas_no_select = 0
    ) AS todo_ok
FROM conteos;
