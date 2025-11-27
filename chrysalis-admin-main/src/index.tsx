import React, { StrictMode } from "react";
import { createRoot } from "react-dom/client";
import "antd/dist/reset.css";
import { App as AntdApp } from "antd"; // ✅ import AntD App provider

import App from "./App";

const rootElement = document.getElementById("root");

if (!rootElement) {
  throw new Error("Root element not found");
}

const root = createRoot(rootElement);

root.render(
  <StrictMode>
    <AntdApp>
      {" "}
      {/* ✅ AntD context provider */}
      <App />
    </AntdApp>
  </StrictMode>
);
