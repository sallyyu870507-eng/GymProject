import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

// 開發時：前端 5173，/api/* 轉給後端 8080（同網域，不需要 CORS，Session Cookie 正常運作）
export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      "/api": {
        target: "http://localhost:8080",
        changeOrigin: true,
        rewrite: p => p.replace(/^\/api/, ""),
      },
    },
  },
});
