const fs = require('fs');
let c = fs.readFileSync('src/app/components/Presupuestos/PresupuestosList.tsx', 'utf8');

if (!c.includes('import { ModeloConfiguratorModal }')) {
  c = c.replace(
    "import { formatearMoneda } from '../../utils/calculations';",
    "import { formatearMoneda } from '../../utils/calculations';\nimport { ModeloConfiguratorModal } from './ModeloConfiguratorModal';"
  );
}

// Add state for selected model
if (!c.includes('const [modeloConfig, setModeloConfig]')) {
  c = c.replace(
    'const navigate = useNavigate();',
    'const navigate = useNavigate();\n  const [modeloConfig, setModeloConfig] = useState<Producto | null>(null);'
  );
}

// Update the onClick of "Cotizar" button
c = c.replace(
  'onClick={() => navigate(`/cotizaciones/nueva?producto_id=${modelo.id}`)}',
  'onClick={() => setModeloConfig(modelo)}'
);
c = c.replace(
  'Cotizar <ArrowRight className="w-4 h-4 ml-1" />',
  'Configurar (CPQ) <ArrowRight className="w-4 h-4 ml-1" />'
);

// Add the modal component at the end of the return statement
if (!c.includes('<ModeloConfiguratorModal')) {
  const modalHTML = `
      <ModeloConfiguratorModal 
        modelo={modeloConfig} 
        productosCatalog={productos} 
        onClose={() => setModeloConfig(null)} 
      />
    </div>
  );`;
  c = c.replace('</div>\n  );\n}', modalHTML + '\n}');
}

fs.writeFileSync('src/app/components/Presupuestos/PresupuestosList.tsx', c);
