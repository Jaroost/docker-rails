import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="nested-form"
export default class extends Controller {
  static targets = ["container", "template", "add"]

  connect() {
    console.log("NestedForm controller connected")
  }

  add(event) {
    event.preventDefault()

    // Clone the template
    const content = this.templateTarget.innerHTML.replace(/NEW_RECORD/g, new Date().getTime())

    // Insert before the add button
    this.containerTarget.insertAdjacentHTML("beforeend", content)
  }

  remove(event) {
    event.preventDefault()

    const item = event.target.closest(".nested-form-item")

    // Check if this is a persisted record (has an ID)
    const idField = item.querySelector('input[name*="[id]"]')

    if (idField && idField.value) {
      // Mark for destruction instead of removing
      const destroyField = item.querySelector('input[name*="[_destroy]"]')
      if (destroyField) {
        destroyField.value = "1"
      }
      item.style.display = "none"
    } else {
      // Remove from DOM if it's a new record
      item.remove()
    }

    // Ensure at least one visible item remains
    this.ensureMinimumItems()
  }

  ensureMinimumItems() {
    const visibleItems = Array.from(this.containerTarget.querySelectorAll(".nested-form-item"))
      .filter(item => item.style.display !== "none")

    if (visibleItems.length === 0) {
      // Add a new empty item
      this.add({ preventDefault: () => {} })
    }
  }
}
