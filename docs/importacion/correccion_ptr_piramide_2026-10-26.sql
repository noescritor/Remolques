-- Corrección de datos (no es migración): precio de PIRAMIDE capturado en la fila equivocada del Excel.
-- El Excel "PRECIOS DE ACERO.xlsx" tenía $5,050 de PIRAMIDE en 'PTR de 6X2" Cal. 3/16"' (fila 6),
-- pero ese precio corresponde al 'PTR 6X4" Cal. 3/16 a 12.20m' (fila 5; Fortacero 5,201.48 / Serviacero 5,230.61).
-- Seguro de re-ejecutar: solo actúa si el precio sigue tal como se importó (5050, notas import-2r13)
-- y si el PTR 6X4" no tiene ya precio de PIRAMIDE. Deja rastro en acero_precios_historial.

BEGIN;

DO $$
DECLARE
    r_org RECORD;
    v_mat_6x2 uuid;
    v_mat_6x4 uuid;
    v_n int;
BEGIN
    FOR r_org IN SELECT id FROM organizaciones LOOP
        SELECT count(*), (array_agg(id))[1] INTO v_n, v_mat_6x2
        FROM acero_materiales
        WHERE organizacion_id = r_org.id AND nombre = 'PTR de 6X2" Cal. 3/16"';
        IF v_n <> 1 THEN
            RAISE NOTICE 'Org %: PTR 6X2 encontrado % veces; se omite', r_org.id, v_n;
            CONTINUE;
        END IF;

        SELECT count(*), (array_agg(id))[1] INTO v_n, v_mat_6x4
        FROM acero_materiales
        WHERE organizacion_id = r_org.id AND nombre = 'PTR 6X4" Cal. 3/16 a 12.20m';
        IF v_n <> 1 THEN
            RAISE NOTICE 'Org %: PTR 6X4 encontrado % veces; se omite', r_org.id, v_n;
            CONTINUE;
        END IF;

        IF EXISTS (
            SELECT 1 FROM acero_precios p
            WHERE p.organizacion_id = r_org.id AND p.material_id = v_mat_6x2
              AND p.proveedor = 'PIRAMIDE' AND p.precio = 5050 AND p.notas = 'import-2r13'
        ) AND NOT EXISTS (
            SELECT 1 FROM acero_precios p
            WHERE p.organizacion_id = r_org.id AND p.material_id = v_mat_6x4 AND p.proveedor = 'PIRAMIDE'
        ) THEN
            INSERT INTO acero_precios (organizacion_id, material_id, proveedor, precio, incluye_iva, fuente, notas)
            VALUES (r_org.id, v_mat_6x4, 'PIRAMIDE', 5050, true,
                    'PRECIOS DE ACERO.xlsx (Hoja1); corregido: estaba en la fila del PTR 6X2', 'import-2r13');

            INSERT INTO acero_precios_historial (organizacion_id, material_id, proveedor, precio_anterior, precio_nuevo)
            VALUES (r_org.id, v_mat_6x4, 'PIRAMIDE', NULL, 5050);

            INSERT INTO acero_precios_historial (organizacion_id, material_id, proveedor, precio_anterior, precio_nuevo)
            VALUES (r_org.id, v_mat_6x2, 'PIRAMIDE', 5050, 0);

            DELETE FROM acero_precios
            WHERE organizacion_id = r_org.id AND material_id = v_mat_6x2
              AND proveedor = 'PIRAMIDE' AND precio = 5050 AND notas = 'import-2r13';
        END IF;
    END LOOP;
END $$;

COMMIT;

-- Verificación (debe dar 1 fila PIRAMIDE=5050 en el 6X4 y ninguna PIRAMIDE en el 6X2):
SELECT m.nombre, p.proveedor, p.precio
FROM acero_precios p
JOIN acero_materiales m ON m.id = p.material_id
WHERE m.nombre IN ('PTR de 6X2" Cal. 3/16"', 'PTR 6X4" Cal. 3/16 a 12.20m')
ORDER BY m.nombre, p.proveedor;
