const fs = require('fs');
const path = require('path');

function walkDir(dir, callback) {
  fs.readdirSync(dir).forEach(f => {
    let dirPath = path.join(dir, f);
    let isDirectory = fs.statSync(dirPath).isDirectory();
    isDirectory ? walkDir(dirPath, callback) : callback(path.join(dir, f));
  });
}

walkDir('src/app/components', function(filePath) {
  if (!filePath.endsWith('.tsx')) return;
  
  let code = fs.readFileSync(filePath, 'utf-8');
  let original = code;
  
  // Replacements
  code = code.replace(/bg-white\/\[0\.02\]/g, "bg-card/50");
  code = code.replace(/border-white\/\[0\.06\]/g, "border-border/50");
  code = code.replace(/border-white\/10/g, "border-border");
  code = code.replace(/hover:bg-white\/\[0\.04\]/g, "hover:bg-muted/50");
  code = code.replace(/bg-white\/5/g, "bg-muted/20");
  
  // Avoid replacing text-white inside buttons (heuristic: look for bg-something before it, or just replace specific tags)
  // Let's replace "text-white" with "text-foreground" only if it's NOT next to a bg-* color that requires white text
  // Actually, standardizing on text-foreground is safest, except for known buttons.
  code = code.replace(/text-white\/40/g, "text-muted-foreground");
  code = code.replace(/text-white\/70/g, "text-muted-foreground");
  
  // Replace text-white on headings and spans but not inside standard buttons (we can just replace all text-white and see if buttons look bad)
  // Or we can specifically target `text-white` not preceded by `bg-`
  // A simple regex: replace `text-white` if it doesn't follow `bg-accent` or `bg-primary`
  // Actually, it's easier to just do:
  code = code.replace(/text-white/g, "text-foreground");
  // And then fix the buttons back!
  code = code.replace(/bg-accent-([a-z]+) (.*?)text-foreground/g, "bg-accent-$1 $2text-white");
  code = code.replace(/bg-primary (.*?)text-foreground/g, "bg-primary $1text-primary-foreground");

  if (code !== original) {
    fs.writeFileSync(filePath, code, 'utf-8');
    console.log("Updated", filePath);
  }
});
