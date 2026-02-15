import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

import { createApp } from "vue"
import App from "@/components/App.vue"

// Prevent FOUC: Show body once Bootstrap CSS is loaded
document.addEventListener("DOMContentLoaded", () => {
  // Add 'loaded' class to body to make it visible with smooth fade-in
  document.body.classList.add("loaded")
})

const el = document.getElementById("vue-app")
if (el) {
  createApp(App).mount(el)
}
