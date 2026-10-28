import { defineConfig, loadEnv } from 'vite'
import react from '@vitejs/plugin-react'

/*
[vite.config.js](D:/iSpan course/GymProject/frontend/vite.config.js)	Vite 設定檔。
啟用 React 支援、設定開發網址 localhost:5173，並把 /api、/login、/logout 請求轉送至後端，預設為 localhost:8080。
打包結果輸出到 dist。
*/


export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  const target = env.BACKEND_URL || 'http://localhost:8080'
  return {
    plugins: [react()],
    server: {
      host: 'localhost', port: 5173, strictPort: true,
      // Keep redirects in the frontend. The Java login redirects to /admin or /coach;
      // both are SPA paths here. Only form posts and APIs go to Spring Boot.
      proxy: Object.fromEntries(['/api', '^/login(?:\\?.*)?$', '^/logout(?:\\?.*)?$', '/admin/schedules', '^/coaches/(?:dashboard|schedules|[0-9]+/)', '/members/courses', '/booking'].map(path => [path, {
        target, changeOrigin: true, autoRewrite: true, cookieDomainRewrite: '',
        bypass(req) {
          // Login form POSTs reach Spring; HTML GETs render the shared React login.
          if (req.method === 'GET' && /^\/login(?:\?|$)/.test(req.url) && req.headers.accept?.includes('text/html')) return '/index.html'
        }
      }]))
    },
    build: { outDir: 'dist' }
  }
})
