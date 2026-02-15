import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

// Import the Vue mounting system
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"

/**
 * Auto-register all Vue components from the components directory
 *
 * Convention: Filename becomes the component name
 * - App.vue → "app" → data-behavior="vue-app"
 * - Counter.vue → "counter" → data-behavior="vue-counter"
 * - TodoList.vue → "todo-list" → data-behavior="vue-todo-list"
 *
 * This uses Vite's import.meta.glob which supports tree-shaking:
 * Only components actually used in your HTML will be included in the bundle!
 */
const componentModules = import.meta.glob<{ default: any }>('@/components/*.vue', { eager: true })

for (const path in componentModules) {
  // Extract filename without path and extension
  // Example: "@/components/TodoList.vue" → "TodoList"
  const componentName = path
    .split('/')
    .pop()!
    .replace('.vue', '')

  // Convert PascalCase to kebab-case
  // Example: "TodoList" → "todo-list"
  const kebabName = componentName
    .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
    .toLowerCase()

  const component = componentModules[path].default
  registerComponent(kebabName, component)

  console.log(`[VueMounter] Auto-registered "${kebabName}" from ${componentName}.vue`)
}

// Initialize the Vue mounting system when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  // Add 'loaded' class to body to make it visible with smooth fade-in
  document.body.classList.add("loaded")

  // Mount all Vue apps and watch for new ones
  initVueMounter()
})
