-- 1. Aseguramos que la organización exista
INSERT INTO public.organizaciones (id, nombre) 
VALUES ('00000000-0000-0000-0000-000000000001', 'Empresa de Remolques')
ON CONFLICT (id) DO NOTHING;

-- 2. Clientes
INSERT INTO public.clientes (id, organizacion_id, nombre_razon_social, nombre_contacto, telefono, correo, ciudad, estado) VALUES
(gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'Transportes del Norte S.A. de C.V.', 'Carlos Slim', '8112345678', 'compras@transportesnorte.com', 'Monterrey', 'Nuevo León'),
(gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'Agropecuaria El Rancho', 'Juan Pérez', '3312345678', 'juan.perez@elrancho.mx', 'Guadalajara', 'Jalisco'),
(gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'Logística Express', 'Ana Torres', '5512345678', 'ana@logisticaexpress.com.mx', 'CDMX', 'Ciudad de México');

-- 3. Categorías de Producto
DO $$
DECLARE
  cat_remolques_id uuid := gen_random_uuid();
  cat_refacciones_id uuid := gen_random_uuid();
  cat_materiales_id uuid := gen_random_uuid();
BEGIN
  INSERT INTO public.categorias_producto (id, organizacion_id, nombre, color) VALUES
  (cat_remolques_id, '00000000-0000-0000-0000-000000000001', 'Remolques Terminados', 'blue'),
  (cat_refacciones_id, '00000000-0000-0000-0000-000000000001', 'Refacciones', 'green'),
  (cat_materiales_id, '00000000-0000-0000-0000-000000000001', 'Materias Primas', 'orange');

  -- 4. Productos (Remolques Terminados)
  INSERT INTO public.productos (id, organizacion_id, tipo, nombre, descripcion, unidad, precio_unitario, costo, stock_actual, categoria_id) VALUES
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Remolque Ganadero 14ft', 'Remolque ganadero de 14 pies con división central, 2 ejes de 3500 lbs', 'pz', 85000.00, 55000.00, 2, cat_remolques_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Remolque Cama Baja 18ft', 'Cama baja para maquinaria, madera de pino tratada, rampas traseras', 'pz', 65000.00, 42000.00, 5, cat_remolques_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Remolque Cuello de Ganso 24ft', 'Cuello de ganso 24 pies, capacidad 14,000 lbs', 'pz', 130000.00, 85000.00, 1, cat_remolques_id);

  -- 5. Materias Primas / Componentes
  INSERT INTO public.productos (id, organizacion_id, tipo, nombre, descripcion, unidad, precio_unitario, costo, stock_actual, categoria_id) VALUES
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Eje de 3500 lbs', 'Eje con frenos eléctricos 3500 lbs', 'pz', 3500.00, 2800.00, 20, cat_materiales_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Llanta Rin 15 6 Birlos', 'Llanta de carga Rin 15 ST205/75R15', 'pz', 1800.00, 1400.00, 40, cat_refacciones_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Tirón Bola 2"', 'Tirón reforzado para bola de 2 pulgadas', 'pz', 850.00, 600.00, 15, cat_materiales_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Gato manual 5000 lbs', 'Gato de manivela superior', 'pz', 1200.00, 850.00, 10, cat_materiales_id),
  (gen_random_uuid()::text, '00000000-0000-0000-0000-000000000001', 'bien', 'Placa de Acero 1/8"', 'Hoja de placa de acero 4x8 ft 1/8 de grosor', 'hoja', 2400.00, 1900.00, 50, cat_materiales_id);
END $$;

-- 6. Proveedores
INSERT INTO public.proveedores (id, organizacion_id, nombre, contacto, telefono, condiciones_pago) VALUES
('11111111-1111-1111-1111-111111111111', '00000000-0000-0000-0000-000000000001', 'Aceros de México S.A.', 'Raúl Garza', '8180001111', 'Crédito 30 días'),
('22222222-2222-2222-2222-222222222222', '00000000-0000-0000-0000-000000000001', 'Ejes y Partes Nacionales', 'Mariana López', '3330002222', 'Contado'),
('33333333-3333-3333-3333-333333333333', '00000000-0000-0000-0000-000000000001', 'Llantas Industriales', 'Luis Fernández', '5550003333', 'Contado');

-- 7. Compras a Proveedor (Ejemplo)
INSERT INTO public.compras_proveedor (id, organizacion_id, folio, proveedor_id, estado, fecha) VALUES
('44444444-4444-4444-4444-444444444444', '00000000-0000-0000-0000-000000000001', 'COMP-001', '22222222-2222-2222-2222-222222222222', 'Recibida', now() - interval '5 days');

-- NOTA: Insertamos usando subconsultas para evitar hardcodear IDs que generamos al vuelo.
INSERT INTO public.compra_items (compra_id, material_id, cantidad, costo_unitario)
SELECT '44444444-4444-4444-4444-444444444444', id, 10, 2800.00
FROM public.productos WHERE nombre = 'Eje de 3500 lbs' LIMIT 1;

-- 8. Cotización de Ejemplo (Remolque Ganadero)
DO $$
DECLARE
  cte_id text;
  prod_id text;
  cot_id text := gen_random_uuid()::text;
BEGIN
  SELECT id INTO cte_id FROM clientes WHERE nombre_razon_social = 'Agropecuaria El Rancho' LIMIT 1;
  SELECT id INTO prod_id FROM productos WHERE nombre = 'Remolque Ganadero 14ft' LIMIT 1;

  INSERT INTO public.cotizaciones (id, organizacion_id, folio, cliente_id, estado, subtotal, iva, total)
  VALUES (cot_id, '00000000-0000-0000-0000-000000000001', 'COT-2024-001', cte_id, 'Aprobada', 85000.00, 13600.00, 98600.00);

  INSERT INTO public.items_cotizacion (cotizacion_id, organizacion_id, producto_id, posicion, cantidad, unidad, descripcion, precio_unitario, total_item)
  VALUES (cot_id, '00000000-0000-0000-0000-000000000001', prod_id, 1, 1, 'pz', 'Remolque Ganadero 14ft con accesorios', 85000.00, 85000.00);
END $$;
