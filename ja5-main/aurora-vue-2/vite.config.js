import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 使用相对路径 base，方便直接以 file:// 或任意子路径部署
export default defineConfig({
  plugins: [vue()],
  base: './',
  server: {
    host: true,
    port: 5173,
    // 双保险：若 .env 丢失（VITE_API_BASE 不存在），前端回退到 '/api'
    // 相对路径，由下面的代理转发到 8081 后端，不依赖 CORS
    proxy: {
      '/api': {
        // 固定 IPv4，避免部分 Windows/Node 环境把 localhost 解析到 ::1，
        // 后端只监听 IPv4 时造成页面能开、登录/注册却 500。
        target: 'http://127.0.0.1:8081',
        changeOrigin: true
      }
    }
  }
})
