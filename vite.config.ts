import { defineConfig } from "vite"
import vue from "@vitejs/plugin-vue"
import ViteRuby from "vite-plugin-ruby"
import path from "path"

export default defineConfig({
  base: "/",
  plugins: [
    vue(),
    ViteRuby(),
  ],
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./app/javascript"),
    },
  },
  server: {
    host: "0.0.0.0",
    port: 3036,
    https: false,
    middlewareMode: false,
    allowedHosts: ["vite", "localhost", "127.0.0.1", "vite-rails.localtest.me"],
    hmr: {
      host: "vite-rails.localtest.me",
      protocol: "wss",
      clientPort: 443,
    },
  },
})
