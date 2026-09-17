const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /app\.get\("\/produccion\/lineas", async \(c\) => \{\s*try \{\s*const orgId = c\.get\("organizacionId"\);/;
code = code.replace(regex, 'app.get("/produccion/lineas", async (c) => {\n  try {\n    const orgId = c.get("organizacionId");\n    const supabase = c.get("supabase") as any;');

const regex2 = /app\.get\("\/produccion\/fases", async \(c\) => \{\s*try \{\s*const orgId = c\.get\("organizacionId"\);/;
code = code.replace(regex2, 'app.get("/produccion/fases", async (c) => {\n  try {\n    const orgId = c.get("organizacionId");\n    const supabase = c.get("supabase") as any;');

const regex3 = /app\.put\("\/produccion\/ordenes\/:id\/mover", async \(c\) => \{\s*try \{\s*const orgId = c\.get\("organizacionId"\);/;
code = code.replace(regex3, 'app.put("/produccion/ordenes/:id/mover", async (c) => {\n  try {\n    const orgId = c.get("organizacionId");\n    const supabase = c.get("supabase") as any;');

const regex4 = /app\.put\("\/produccion\/ordenes\/:id\/material", async \(c\) => \{\s*try \{\s*const orgId = c\.get\("organizacionId"\);/;
code = code.replace(regex4, 'app.put("/produccion/ordenes/:id/material", async (c) => {\n  try {\n    const orgId = c.get("organizacionId");\n    const supabase = c.get("supabase") as any;');

fs.writeFileSync(filePath, code, 'utf-8');
