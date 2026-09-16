const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const importStatement = `import { TableroProduccionPage } from './components/TableroProduccion/TableroProduccionPage';\nimport { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';`;
code = code.replace("import { TrazabilidadList } from './components/Trazabilidad/TrazabilidadList';", importStatement);

const hookDestructuring = `    ordenesTrabajo,
    lineasProducto,
    fasesProduccion,
    moverOrdenKanban,`;
code = code.replace("    ordenesTrabajo,", hookDestructuring);

const route = `          <Route path="/tablero-produccion" element={
            <TableroProduccionPage
              lineasProducto={lineasProducto}
              fasesProduccion={fasesProduccion}
              ordenesTrabajo={ordenesTrabajo}
              loading={loading}
              onMoverOrden={moverOrdenKanban}
            />
          } />
          <Route path="/trazabilidad"`;
code = code.replace('<Route path="/trazabilidad"', route);

fs.writeFileSync(filePath, code, 'utf-8');
