const fs = require('fs');
let c = fs.readFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', 'utf8');

const hookInject = `  const [searchParams] = useSearchParams();
  const [formData, setFormData] = useState({`;

c = c.replace('  const [formData, setFormData] = useState({', hookInject);

const autoAddLogic = `
  useEffect(() => {
    const prodId = searchParams.get('producto_id');
    if (esNueva && prodId && productos.length > 0 && formData.items.length === 0) {
      const prod = productos.find(p => p.id === prodId);
      if (prod) {
        // Automatically add the item
        agregarItemDesdeProducto(prod);
        
        // Remove the param from URL without refreshing so it doesn't trigger again
        const url = new URL(window.location.href);
        url.searchParams.delete('producto_id');
        window.history.replaceState({}, '', url.toString());
      }
    }
  }, [productos, esNueva, searchParams]);
`;

// Insert after `const agregarItemDesdeProducto = async (producto: Producto) => { ... }`
// We'll just search for `const duplicarItem` and put it above that.
const target = 'const duplicarItem = (id: string) => {';
c = c.replace(target, autoAddLogic + '\n  ' + target);

fs.writeFileSync('src/app/components/Cotizaciones/CotizacionEditor.tsx', c);
console.log('CotizacionEditor auto-add logic patched');
