const fs = require('fs');
const filePath = 'index.html';
let code = fs.readFileSync(filePath, 'utf-8');

const injection = `
      <script>
        try {
          const theme = localStorage.getItem('theme');
          if (theme === 'light') {
            document.documentElement.classList.remove('dark');
          } else {
            document.documentElement.classList.add('dark');
          }
        } catch (e) {}
      </script>
    </head>`;

code = code.replace('</head>', injection);
// Also remove `class="dark"` so the script fully dictates it (or leave it as default and the script removes it)
code = code.replace('class="dark"', '');

fs.writeFileSync(filePath, code, 'utf-8');
