with open('src/styles/globals.css', 'a') as f:
    f.write('''
@media print {
  body.printing-modal * {
    visibility: hidden;
  }
  
  body.printing-modal [role="dialog"],
  body.printing-modal [role="dialog"] * {
    visibility: visible;
  }
  
  body.printing-modal [role="dialog"] {
    position: absolute;
    left: 0;
    top: 0;
    width: 100%;
    margin: 0;
    padding: 0;
    box-shadow: none;
    border: none;
    background: white;
  }

  body.printing-modal button {
    display: none !important;
  }
}
''')
