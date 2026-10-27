import { defineConfig, loadEnv } from 'vite';
import react from '@vitejs/plugin-react';

/**
 * 開發時把這些路徑轉送給 Spring Boot（預設 http://localhost:8080）。
 * 好處：前端和後端看起來是同一個網址，不會遇到 CORS，登入的 Session Cookie 也會自動帶上。
 * 後端新增了其他開頭的路徑，就加到這個清單。
 */
const BACKEND_PATHS = [
  '/api',
  '/members',
  '/member',
  '/coaches',
  '/coach',
  '/admin',
  '/booking',
  '/login',
  '/logout',
  '/session-test',
];

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '');
  const target = env.VITE_PROXY_TARGET || 'http://localhost:8080';

  return {
    plugins: [react()],
    server: {
      port: 5173,
      proxy: Object.fromEntries(
        BACKEND_PATHS.map((path) => [
          path,
          // changeOrigin 保持 false：Spring 登入後的 redirect 才會導回 5173，而不是跳到 8080
          { target, changeOrigin: false },
        ]),
      ),
    },
  };
});
