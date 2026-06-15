
  import { createRoot } from "react-dom/client";
  import { BrowserRouter } from "react-router-dom";
  import App from "./app/App.tsx";
  import "./styles/index.css";
  import "@fontsource/dm-sans/400.css";
  import "@fontsource/dm-sans/500.css";
  import "@fontsource/dm-sans/700.css";
  import "@fontsource/dm-mono/400.css";
  import "@fontsource/dm-mono/500.css";

  createRoot(document.getElementById("root")!).render(
    <BrowserRouter>
      <App />
    </BrowserRouter>
  );
  