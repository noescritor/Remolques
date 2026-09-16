const fs = require('fs');
const filePath = 'src/app/components/ModernLayout.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

code = code.replace(/border-white\/\[0\.06\]/g, "border-border/50");
code = code.replace(/text-white\/70/g, "text-muted-foreground");
code = code.replace(/hover:bg-white\/\[0\.04\]/g, "hover:bg-muted/50");
code = code.replace(/hover:text-white/g, "hover:text-foreground");
code = code.replace(/text-white/g, "text-foreground");

fs.writeFileSync(filePath, code, 'utf-8');
