const fs = require('fs');
const filePath = 'src/app/components/Dashboard/DashboardMain.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

// Replace hardcoded background/border colors on Cards
code = code.replace(/bg-white\/\[0\.02\]/g, "bg-card/50");
code = code.replace(/border-white\/\[0\.06\]/g, "border-border/50");

// Replace hardcoded text colors
code = code.replace(/text-white\/40/g, "text-muted-foreground");
code = code.replace(/text-white/g, "text-foreground");

// For charts
code = code.replace(/rgba\(255,255,255,0\.1\)/g, "var(--border-hover)");
code = code.replace(/rgba\(255,255,255,0\.4\)/g, "var(--text-muted)");
code = code.replace(/rgba\(255,255,255,0\.25\)/g, "var(--text-muted)"); // Maybe used in COLORS

// Replace specific COLORS object
code = code.replace(/borrador: 'rgba\\(255,255,255,0\\.25\\)'/, "borrador: 'var(--text-muted)'");

fs.writeFileSync(filePath, code, 'utf-8');
