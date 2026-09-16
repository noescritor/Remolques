const fs = require('fs');
const filePath = 'package.json';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(
  '"dependencies": {',
  '"dependencies": {\n    "@react-pdf/renderer": "^3.4.4",'
);

fs.writeFileSync(filePath, code, 'utf-8');
