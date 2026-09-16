const fs = require('fs');
const filePath = 'src/styles/globals.css';
let code = fs.readFileSync(filePath, 'utf-8');

const lightTheme = `:root {
  --font-size: 16px;
  --background: #ffffff;
  --foreground: #09090b;
  --card: #ffffff;
  --card-foreground: #09090b;
  --popover: #ffffff;
  --popover-foreground: #09090b;
  --primary: #A191FF;
  --primary-foreground: #ffffff;
  --secondary: #f4f4f5;
  --secondary-foreground: #18181b;
  --muted: #f4f4f5;
  --muted-foreground: #71717a;
  --accent: #f4f4f5;
  --accent-foreground: #18181b;
  --destructive: #ef4444;
  --destructive-foreground: #ffffff;
  --border: #e4e4e7;
  --input: #e4e4e7;
  --ring: #A191FF;

  --accent-violet: #A191FF;
  --accent-blue: #3b82f6;
  --accent-green: #22c55e;
  --accent-yellow: #eab308;
  --accent-pink: #ec4899;
  --accent-purple: #a855f7;
  
  --text-primary: rgba(0,0,0,0.9);
  --text-secondary: rgba(0,0,0,0.60);
  --text-tertiary: rgba(0,0,0,0.40);
  --text-muted: rgba(0,0,0,0.25);
  --border-soft: rgba(0,0,0,0.06);
  --border-hover: rgba(0,0,0,0.15);
  
  --chart-1: #A191FF;
  --chart-2: #3b82f6;
  --chart-3: #22c55e;
  --chart-4: #eab308;
  --chart-5: #a855f7;
  
  --radius: 0.625rem;
  
  --sidebar: #f4f4f5;
  --sidebar-foreground: #09090b;
  --sidebar-primary: #A191FF;
  --sidebar-primary-foreground: #ffffff;
  --sidebar-accent: #e4e4e7;
  --sidebar-accent-foreground: #09090b;
  --sidebar-border: #d4d4d8;
  --sidebar-ring: #A191FF;
}

.dark {`;

code = code.replace(':root, .dark {', lightTheme);

fs.writeFileSync(filePath, code, 'utf-8');
