-- Migración: 20261105_02_gondola_volumen_escalas.sql
-- Propósito: Marcar renglones de la tina de góndola con escala 'por_volumen'
-- Tanto en receta_base (acero base de góndola) como en opcion_componentes (tina_material A-36 y Hardox 450).
-- Idempotente y multi-tenant (sin UUIDs fijos).
-- Para revertir: UPDATE ... SET escala = 'fija' WHERE escala = 'por_volumen';

BEGIN;

-- 1. receta_base: Marcar renglones de tina de góndola con 'por_volumen'
UPDATE receta_base
SET escala = 'por_volumen'
WHERE modelo_id IN (SELECT id FROM modelos WHERE tipo = 'gondola')
  AND seccion = 'acero'
  AND uso IN (
    'Alma',
    'Soleras',
    'Borda delantera',
    'Cajon para casquillo trasero'
  );

-- 2. opcion_componentes: Marcar componentes de tina en grupo tina_material con 'por_volumen'
UPDATE opcion_componentes
SET escala = 'por_volumen'
WHERE opcion_id IN (
    SELECT oc.id
    FROM opciones_configuracion oc
    JOIN grupos_configuracion gc ON oc.grupo_id = gc.id
    WHERE gc.clave = 'tina_material' AND oc.clave IN ('a36', 'hardox_450')
  )
  AND seccion = 'acero'
  AND uso IN (
    'Vueltas traseras',
    'Cuellos',
    'Vueltas frontales',
    'Placas laterales para tina',
    'Bisera',
    'Postes para gato',
    'Borda trasera',
    'Resvalon',
    'Poste trasero',
    'Charola',
    'Aletas traseras',
    'Cartabon para gato',
    'Piso',
    'Placa frontal',
    'Placa para tapa',
    'Refuerzo para poste',
    'HSS inferior',
    'Brasos frontales',
    'Brasos traseros',
    'Hss superior',
    'Refuerzo interno de tina',
    'Hss frontal',
    'Paquete vueltas/cuellos',
    'Paquete piso/tapa',
    'Botas para tapa',
    'Bases para tapa',
    'Seguro para puerta',
    'Puera'
  );

COMMIT;
