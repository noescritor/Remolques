const fs = require('fs');
const filePath = 'src/app/components/Ajustes/AjustesForm.tsx';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `
      <Card>
        <CardHeader>
          <CardTitle>Apariencia</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="flex items-center justify-between md:justify-start md:space-x-8">
            <div className="space-y-1">
              <Label>Tema de la Interfaz</Label>
              <p className="text-sm text-muted-foreground">Alternar entre el modo oscuro y claro</p>
            </div>
            <select
              className="flex h-10 w-48 rounded-md border border-input bg-background px-3 py-2 text-sm ring-offset-background placeholder:text-muted-foreground focus:outline-none focus:ring-2 focus:ring-ring focus:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-50"
              value={localStorage.getItem('theme') || 'dark'}
              onChange={(e) => {
                const val = e.target.value;
                localStorage.setItem('theme', val);
                if (val === 'light') {
                  document.documentElement.classList.remove('dark');
                } else {
                  document.documentElement.classList.add('dark');
                }
                // Simular guardado para forzar re-render si es necesario
                setGuardado(true);
                setTimeout(() => setGuardado(false), 2000);
              }}
            >
              <option value="dark" className="bg-background text-foreground">🌙 Modo Oscuro</option>
              <option value="light" className="bg-background text-foreground">☀️ Modo Claro</option>
            </select>
          </div>
        </CardContent>
      </Card>

      <Card>`;

code = code.replace('<Card>', injection);

fs.writeFileSync(filePath, code, 'utf-8');
