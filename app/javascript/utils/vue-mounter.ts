import { createApp, Component } from "vue"

/**
 * Vue Mounter - Dynamic Vue component mounting system
 *
 * Automatically mounts Vue apps on elements with data-behavior="vue-*"
 * Supports dynamic component loading and prop passing via data-attributes
 *
 * Example usage in HTML:
 *   <div data-behavior="vue-counter" data-initial-count="5"></div>
 *   <div data-behavior="vue-greeting" data-name="John"></div>
 */

// Component registry - add your components here
const componentRegistry: Record<string, Component> = {}

/**
 * Register a Vue component to be used with data-behavior
 *
 * @param name - The name used in data-behavior (e.g., "counter" for "vue-counter")
 * @param component - The Vue component
 */
export function registerComponent(name: string, component: Component): void {
  componentRegistry[name] = component
}

/**
 * Extract props from data-attributes on an element
 * Converts data-my-prop="value" to { myProp: "value" }
 * Automatically parses JSON, numbers, and booleans
 *
 * @param element - The DOM element to extract props from
 * @returns Object containing all data-attributes as camelCase props
 */
function extractProps(element: HTMLElement): Record<string, any> {
  const props: Record<string, any> = {}
  const dataset = element.dataset

  // Skip the 'behavior' attribute
  for (const key in dataset) {
    if (key === "behavior") continue

    let value: any = dataset[key]

    // Try to parse as JSON first (handles objects, arrays, null, etc.)
    try {
      value = JSON.parse(value!)
    } catch {
      // If JSON parsing fails, try to convert common types
      if (value === "true") value = true
      else if (value === "false") value = false
      else if (value === "null") value = null
      else if (value === "undefined") value = undefined
      else if (!isNaN(Number(value)) && value !== "") value = Number(value)
      // Otherwise keep as string
    }

    props[key] = value
  }

  return props
}

/**
 * Mount a Vue app on a specific element
 *
 * @param element - The DOM element to mount on
 * @returns true if mounted successfully, false otherwise
 */
function mountVueApp(element: HTMLElement): boolean {
  const behavior = element.dataset.behavior

  if (!behavior || !behavior.startsWith("vue-")) {
    return false
  }

  // Extract component name (e.g., "vue-counter" -> "counter")
  const componentName = behavior.replace(/^vue-/, "")
  const component = componentRegistry[componentName]

  if (!component) {
    console.warn(`[VueMounter] No component registered for "${componentName}"`)
    return false
  }

  // Check if already mounted
  if (element.dataset.vueMounted === "true") {
    return false
  }

  try {
    // Extract props from data-attributes
    const props = extractProps(element)

    // Create and mount the Vue app
    const app = createApp(component, props)
    app.mount(element)

    // Mark as mounted to prevent double-mounting
    element.dataset.vueMounted = "true"

    console.log(`[VueMounter] Mounted "${componentName}" on`, element, "with props:", props)
    return true
  } catch (error) {
    console.error(`[VueMounter] Failed to mount "${componentName}":`, error)
    return false
  }
}

/**
 * Scan the DOM and mount all Vue apps
 *
 * @param root - The root element to scan (defaults to document.body)
 */
export function mountAllVueApps(root: HTMLElement = document.body): void {
  const elements = root.querySelectorAll<HTMLElement>('[data-behavior^="vue-"]')

  let mountedCount = 0
  elements.forEach(element => {
    if (mountVueApp(element)) {
      mountedCount++
    }
  })

  if (mountedCount > 0) {
    console.log(`[VueMounter] Mounted ${mountedCount} Vue app(s)`)
  }
}

/**
 * Set up a MutationObserver to automatically mount Vue apps
 * when new elements are added to the DOM
 *
 * @param root - The root element to observe (defaults to document.body)
 */
export function observeVueApps(root: HTMLElement = document.body): void {
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      mutation.addedNodes.forEach((node) => {
        if (node.nodeType === Node.ELEMENT_NODE) {
          const element = node as HTMLElement

          // Check if the added element itself has vue behavior
          if (element.dataset?.behavior?.startsWith("vue-")) {
            mountVueApp(element)
          }

          // Check for vue behaviors in descendants
          const vueElements = element.querySelectorAll<HTMLElement>('[data-behavior^="vue-"]')
          vueElements.forEach(mountVueApp)
        }
      })
    })
  })

  observer.observe(root, {
    childList: true,
    subtree: true
  })

  console.log("[VueMounter] MutationObserver started - watching for new Vue apps")
}

/**
 * Initialize the Vue mounting system
 * Mounts all existing apps and sets up automatic mounting for new ones
 *
 * @param root - The root element to work with (defaults to document.body)
 */
export function initVueMounter(root: HTMLElement = document.body): void {
  // Mount existing apps
  mountAllVueApps(root)

  // Watch for new apps being added
  observeVueApps(root)
}
