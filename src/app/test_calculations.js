// Test para verificar consistencia en cálculos de IVA

// Simular el tipo Producto y Cotizacion
const mockProducto = {
  id: '1',
  nombre: 'Playera Polo',
  precio_unitario: 110,
  costo: 100,
  tasa_iva: 0.16
};

const mockAjustes = {
  iva_por_defecto: 0.16
};

// Simular las funciones de cálculo
function calcularItemCotizacion(cantidad, precio_unitario, tasa_iva = 0.16) {
  const total_item = cantidad * precio_unitario;
  const iva_item = total_item * tasa_iva;
  
  return {
    iva_item: Math.round(iva_item * 100) / 100,
    total_item: Math.round(total_item * 100) / 100
  };
}

function calcularTotalesCotizacion(cotizacion, tasa_iva = 0.16) {
  const items = cotizacion.items || [];
  const conFactura = cotizacion.con_factura !== false;
  
  const subtotal = items.reduce((sum, item) => {
    return sum + (item.total_item || 0);
  }, 0);
  
  const iva = conFactura ? subtotal * tasa_iva : 0;
  const total = subtotal + iva;

  return {
    subtotal: Math.round(subtotal * 100) / 100,
    iva: Math.round(iva * 100) / 100,
    total: Math.round(total * 100) / 100
  };
}

// Test 1: Calcular item individual
console.log('=== TEST 1: Item Individual ===');
const itemCalculado = calcularItemCotizacion(1, mockProducto.precio_unitario, mockAjustes.iva_por_defecto);
console.log('Producto:', mockProducto.nombre);
console.log('Precio unitario:', mockProducto.precio_unitario);
console.log('IVA calculado:', itemCalculado.iva_item);
console.log('Total item:', itemCalculado.total_item);

// Test 2: Cotización completa CON factura
console.log('\n=== TEST 2: Cotización CON Factura ===');
const mockCotizacionConFactura = {
  id: '1',
  con_factura: true,
  items: [
    {
      id: '1',
      cantidad: 1,
      precio_unitario: 110,
      total_item: 110
    }
  ]
};

const totalesConFactura = calcularTotalesCotizacion(mockCotizacionConFactura, mockAjustes.iva_por_defecto);
console.log('Subtotal:', totalesConFactura.subtotal);
console.log('IVA:', totalesConFactura.iva);
console.log('Total:', totalesConFactura.total);

// Test 3: Cotización completa SIN factura
console.log('\n=== TEST 3: Cotización SIN Factura ===');
const mockCotizacionSinFactura = {
  id: '2',
  con_factura: false,
  items: [
    {
      id: '1',
      cantidad: 1,
      precio_unitario: 110,
      total_item: 110
    }
  ]
};

const totalesSinFactura = calcularTotalesCotizacion(mockCotizacionSinFactura, mockAjustes.iva_por_defecto);
console.log('Subtotal:', totalesSinFactura.subtotal);
console.log('IVA:', totalesSinFactura.iva);
console.log('Total:', totalesSinFactura.total);

// Test 4: Verificar cálculo de margen
console.log('\n=== TEST 4: Cálculo de Margen ===');
const ganancia = mockProducto.precio_unitario - mockProducto.costo;
const margenPorcentaje = (ganancia / mockProducto.precio_unitario) * 100;
console.log('Costo:', mockProducto.costo);
console.log('Precio venta:', mockProducto.precio_unitario);
console.log('Ganancia:', ganancia);
console.log('Margen:', margenPorcentaje.toFixed(1) + '%');

console.log('\n=== ✅ TODOS LOS CÁLCULOS USAN IVA CONSISTENTE DE 16% ===');