const fs = require('fs');
let c = fs.readFileSync('src/app/App.tsx', 'utf8');

c = c.replace('comprasProveedor={props.comprasProveedor}', 'comprasProveedor={comprasProveedor}');

fs.writeFileSync('src/app/App.tsx', c);
console.log('Fixed props 1');
