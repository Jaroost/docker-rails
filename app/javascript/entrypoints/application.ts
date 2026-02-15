import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

// Import the Vue mounting system
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"

// Import all Vue components that can be used with data-behavior
import App from "@/components/App.vue"
import Counter from "@/components/Counter.vue"
import Greeting from "@/components/Greeting.vue"
import TodoList from "@/components/TodoList.vue"

// Register components (name should match data-behavior="vue-{name}")
registerComponent("app", App)
registerComponent("counter", Counter)
registerComponent("greeting", Greeting)
registerComponent("todo-list", TodoList)

// Initialize the Vue mounting system when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  // Add 'loaded' class to body to make it visible with smooth fade-in
  document.body.classList.add("loaded")

  // Mount all Vue apps and watch for new ones
  initVueMounter()
})
