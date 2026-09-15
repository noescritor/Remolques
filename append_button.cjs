const fs = require('fs');
const filePath = 'src/app/components/Cotizaciones/CotizacionDetalle.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

// 1. Add to Props
code = code.replace(
  "onRegistrarMovimientoInventario?: (movimiento: any) => Promise<any>;",
  "onRegistrarMovimientoInventario?: (movimiento: any) => Promise<any>;\n  onGenerarOrdenesTrabajo?: (cotizacionId: string) => Promise<any>;"
);

// 2. Destructure
code = code.replace(
  "onRegistrarMovimientoInventario\n}: CotizacionDetalleProps) {",
  "onRegistrarMovimientoInventario,\n  onGenerarOrdenesTrabajo\n}: CotizacionDetalleProps) {"
);

// 3. Add handler
const handler = `
  const handleGenerarOrdenes = async () => {
    if (!onGenerarOrdenesTrabajo) return;
    try {
      await onGenerarOrdenesTrabajo(cotizacion.id);
      alert('Órdenes de trabajo generadas exitosamente. Revisa el módulo de Producción.');
    } catch (e: any) {
      alert('Error: ' + e.message);
    }
  };
`;
code = code.replace("const handleGenerarProduccion = async", handler + "\n  const handleGenerarProduccion = async");

// 4. Add Button in UI
// It's probably around the `<div className="flex gap-2">` where the other buttons are.
// Let's just insert it after the "Enviar a Producción" button if it exists, or just next to the "Requisición" button.
// Actually, let's put it in the Dropdown Menu or action buttons.
const btn = `
          <Button variant="outline" className="bg-slate-800 text-white hover:bg-slate-700" onClick={handleGenerarOrdenes}>
            <Factory className="w-4 h-4 mr-2" />
            Crear Órdenes de Producción
          </Button>
`;
code = code.replace(
  /<Button onClick=\{\(\) => setShowRequisicion\(true\)\}/,
  btn + '\n          <Button onClick={() => setShowRequisicion(true)}'
);

code = code.replace("import { Download, Edit2", "import { Download, Edit2, Factory");

fs.writeFileSync(filePath, code, 'utf-8');
