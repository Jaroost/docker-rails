import { defineConfig } from "vite"
import vue from "@vitejs/plugin-vue"
import ViteRuby from "vite-plugin-ruby"

export default defineConfig({
  base: "/",
  plugins: [
    vue(),
    ViteRuby(),
  ],
  server: {
    host: "0.0.0.0",
    port: 3036,
    https: false,
    middlewareMode: false,
    allowedHosts: ["vite", "localhost", "127.0.0.1"],
    hmr: {
      host: "localhost",
      port: 3036,
      protocol: "ws",
    },
  },
})
