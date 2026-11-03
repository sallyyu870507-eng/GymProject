import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * 開發時把 API 和照片轉給後端（Spring Boot，http://localhost:8080），
 * 瀏覽器看起來是同一個網址，登入的 cookie（JSESSIONID）就會自動帶上。
 */
const backend = 'http://localhost:8080';

export default defineConfig({
  plugins: [react()],
  server: {
    port: 5173,
    proxy: {
      '/api': backend,
      '/uploads': backend,
    },
  },
});
