import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'
import tailwindcss from '@tailwindcss/vite'
import { resolve } from 'path'

export default defineConfig({
  plugins: [vue(), tailwindcss()],
  resolve: {
    alias: {
      '@': resolve(__dirname, 'src'),
    },
  },
  server: {
    port: 5173,
    watch: {
      // The editor writes through temp dirs (".<name>.<pid>.<uuid>.tmpdir");
      // watching them triggers EBUSY on Windows and kills the dev server.
      ignored: ['**/*.tmpdir/**', '**/*.tmp', '**/node_modules/**', '**/.git/**'],
    },
    proxy: {
      '/api': {
        target: 'http://localhost:8000',
        changeOrigin: true,
      },
    },
  },
})
