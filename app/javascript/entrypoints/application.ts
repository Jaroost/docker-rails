import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

import { createApp } from "vue"
import App from "@/components/App.vue"

const el = document.getElementById("vue-app")
if (el) {
  createApp(App).mount(el)
}
