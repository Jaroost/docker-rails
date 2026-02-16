import "bootstrap/dist/css/bootstrap.min.css"
import "bootstrap"

// Import Stimulus
import { Application } from "@hotwired/stimulus"

// Import the Vue mounting system
import { registerComponent, initVueMounter } from "@/utils/vue-mounter"

// Start Stimulus application
const Stimulus = Application.start()

// Auto-register all Stimulus controllers
const controllerModules = import.meta.glob<{ default: any }>('@/controllers/**/*_controller.js', { eager: true })

for (const path in controllerModules) {
  // Extract controller name from path
  // Example: "/controllers/nested_form_controller.js" → "nested-form"
  const controllerName = path
    .replace(/^.*\/controllers\//, '')
    .replace(/_controller\.js$/, '')
    .replace(/_/g, '-')

  const controller = controllerModules[path].default
  Stimulus.register(controllerName, controller)

  console.log(`[Stimulus] Auto-registered "${controllerName}" controller`)
}

/**
 * Auto-register all Vue components from the components directory (including subdirectories)
 *
 * Convention: Path + filename becomes the component name
 * - components/App.vue → "app" → data-behavior="vue-app"
 * - components/Counter.vue → "counter" → data-behavior="vue-counter"
 * - components/TodoList.vue → "todo-list" → data-behavior="vue-todo-list"
 * - components/shared/Button.vue → "shared-button" → data-behavior="vue-shared-button"
 * - components/forms/inputs/TextInput.vue → "forms-inputs-text-input" → data-behavior="vue-forms-inputs-text-input"
 *
 * This prevents naming conflicts when multiple components have the same filename in different folders.
 *
 * This uses Vite's import.meta.glob which supports tree-shaking:
 * Only components actually used in your HTML will be included in the bundle!
 */
const componentModules = import.meta.glob<{ default: any }>('@/components/**/*.vue', { eager: true })

for (const path in componentModules) {
  // Extract relative path from components directory
  // Example: "/components/shared/Button.vue" → "shared/Button"
  // Note: Vite transforms @/components/ to /components/ in the glob result
  const relativePath = path
    .replace(/^.*\/components\//, '') // Remove everything up to and including /components/
    .replace('.vue', '')

  // Convert path segments to kebab-case
  // Example: "shared/Button" → "shared-button"
  // Example: "forms/inputs/TextInput" → "forms-inputs-text-input"
  const kebabName = relativePath
    .split('/')
    .map(segment =>
      segment
        .replace(/([a-z0-9])([A-Z])/g, '$1-$2')
        .toLowerCase()
    )
    .join('-')

  const component = componentModules[path].default
  registerComponent(kebabName, component)

  console.log(`[VueMounter] Auto-registered "${kebabName}" from ${relativePath}.vue`)
}

// Initialize the Vue mounting system when DOM is ready
document.addEventListener("DOMContentLoaded", () => {
  // Add 'loaded' class to body to make it visible with smooth fade-in
  document.body.classList.add("loaded")

  // Mount all Vue apps and watch for new ones
  initVueMounter()
})
