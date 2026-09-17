const fs = require('fs');
const filePath = 'src/app/components/OrdenesTrabajo/OrdenesTrabajoList.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

// Container bg
code = code.replace(/bg-slate-900 border border-border/g, 'bg-card border border-border/50');
code = code.replace(/bg-slate-900 border-border text-foreground/g, 'bg-card border-border/50 text-foreground');
code = code.replace(/bg-slate-900/g, 'bg-card');

// Inputs and Selects
code = code.replace(/bg-slate-800 border-border text-foreground/g, 'bg-background border-border text-foreground');
code = code.replace(/bg-slate-800 border-border/g, 'bg-background border-border');
code = code.replace(/bg-slate-800/g, 'bg-background');

// Table text
code = code.replace(/text-gray-300/g, 'text-muted-foreground');
code = code.replace(/text-gray-400 uppercase bg-slate-800\/50/g, 'text-muted-foreground uppercase bg-muted/50');

// Table rows
code = code.replace(/border-b border-white\/5 hover:bg-card\/50/g, 'border-b border-border/50 hover:bg-muted/50');

// Badge defaults
code = code.replace(/bg-slate-500\/10 text-slate-300 border-slate-500\/20/g, 'bg-muted text-muted-foreground border-border');

// Button
code = code.replace(/bg-white text-black hover:bg-slate-200/g, 'bg-primary text-primary-foreground hover:bg-primary/90');

fs.writeFileSync(filePath, code, 'utf-8');
