const fs = require('fs');

const files = [
  'src/app/components/TableroProduccion/TableroProduccionPage.tsx',
  'src/app/components/TableroProduccion/OrderCard.tsx',
  'src/app/components/TableroProduccion/KanbanBoard.tsx'
];

files.forEach(file => {
  if (fs.existsSync(file)) {
    let content = fs.readFileSync(file, 'utf-8');
    // Replace \` with `
    content = content.replace(/\\`/g, '`');
    // Replace \$ with $
    content = content.replace(/\\\$/g, '$');
    fs.writeFileSync(file, content, 'utf-8');
    console.log('Fixed', file);
  }
});
