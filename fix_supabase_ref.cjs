const fs = require('fs');
const filePath = 'supabase/functions/make-server-feea4382/index.ts';
let code = fs.readFileSync(filePath, 'utf-8');

const regex = /const orgId = c\.get\("organizacionId"\);/g;
code = code.replace(regex, 'const orgId = c.get("organizacionId");\n    const supabase = c.get("supabase") as any;');

fs.writeFileSync(filePath, code, 'utf-8');
