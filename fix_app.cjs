const fs = require('fs');
const filePath = 'src/app/App.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /toast\.error\('Error al guardar ajustes', \{\s+description: error instanceof Error \? error\.message : String\(error\)\s+\/\/ Handler para pagos/m;

const replacement = `toast.error('Error al guardar ajustes', {
        description: error instanceof Error ? error.message : String(error)
      });
    }
  };

  // Handler para pagos`;

code = code.replace(regex, replacement);

fs.writeFileSync(filePath, code, 'utf-8');
