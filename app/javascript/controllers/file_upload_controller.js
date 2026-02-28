import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = ["input", "preview", "dropzone", "fileName"]
  static values = {
    maxSize: { type: Number, default: 10485760 }, // 10MB default
    accept: { type: String, default: "image/*" },
    existingName: { type: String, default: "" },
    existingType: { type: String, default: "" }
  }

  connect() {
    console.log('[FileUpload] Controller connected', this.element)
    this.setupDragAndDrop()
    if (this.existingNameValue) {
      this.showExistingFile(this.existingNameValue, this.existingTypeValue)
    }
  }

  setupDragAndDrop() {
    const dropzone = this.dropzoneTarget

    // Prevent default drag behaviors
    ;['dragenter', 'dragover', 'dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, this.preventDefaults.bind(this), false)
      document.body.addEventListener(eventName, this.preventDefaults.bind(this), false)
    })

    // Highlight drop zone when item is dragged over it
    ;['dragenter', 'dragover'].forEach(eventName => {
      dropzone.addEventListener(eventName, () => this.highlight(), false)
    })

    ;['dragleave', 'drop'].forEach(eventName => {
      dropzone.addEventListener(eventName, () => this.unhighlight(), false)
    })

    // Handle dropped files
    dropzone.addEventListener('drop', this.handleDrop.bind(this), false)
  }

  preventDefaults(e) {
    e.preventDefault()
    e.stopPropagation()
  }

  highlight() {
    this.dropzoneTarget.classList.add('border-primary', 'bg-light')
  }

  unhighlight() {
    this.dropzoneTarget.classList.remove('border-primary', 'bg-light')
  }

  handleDrop(e) {
    const dt = e.dataTransfer
    const files = dt.files
    if (files.length > 0) {
      const dataTransfer = new DataTransfer()
      dataTransfer.items.add(files[0])
      this.inputTarget.files = dataTransfer.files
    }
    this.handleFiles(files)
  }

  // Triggered when file input changes
  change(event) {
    console.log('[FileUpload] change event fired', event.target.files)
    const files = event.target.files
    this.handleFiles(files)
  }

  handleFiles(files) {
    if (files.length === 0) return

    const file = files[0]
    console.log('[FileUpload] handleFiles', { name: file.name, size: file.size, type: file.type, maxSize: this.maxSizeValue })

    // Validate file size
    if (file.size > this.maxSizeValue) {
      alert(`Le fichier est trop volumineux. Taille maximum : ${this.formatFileSize(this.maxSizeValue)}`)
      return
    }

    // Update file name display
    if (this.hasFileNameTarget) {
      this.fileNameTarget.textContent = file.name
      this.fileNameTarget.classList.remove('d-none')
    }

    // Show preview for images
    if (file.type.startsWith('image/')) {
      this.previewImage(file)
    } else {
      this.previewFile(file)
    }
  }

  previewImage(file) {
    const reader = new FileReader()

    reader.onload = (e) => {
      this.previewTarget.innerHTML = `
        <div class="position-relative">
          <img src="${e.target.result}" class="img-fluid rounded" style="max-height: 300px;">
          <button type="button"
                  class="btn btn-sm btn-danger position-absolute top-0 end-0 m-2"
                  data-action="file-upload#remove">
            ✕
          </button>
        </div>
      `
      this.showPreview()
    }

    reader.readAsDataURL(file)
  }

  previewFile(file) {
    console.log('[FileUpload] previewFile', file.name, 'previewTarget:', this.previewTarget)
    const icon = this.getFileIcon(file.type)
    this.previewTarget.innerHTML = `
      <div class="d-flex align-items-center gap-3 p-3 border rounded">
        <div style="font-size: 3rem;">${icon}</div>
        <div class="flex-grow-1">
          <div class="fw-bold">${file.name}</div>
          <div class="text-muted small">${this.formatFileSize(file.size)}</div>
        </div>
        <button type="button"
                class="btn btn-sm btn-danger"
                data-action="file-upload#remove">
          ✕ Supprimer
        </button>
      </div>
    `
    this.showPreview()
    console.log('[FileUpload] After previewFile:', {
      previewDisplay: window.getComputedStyle(this.previewTarget).display,
      previewHeight: this.previewTarget.offsetHeight,
      previewVisible: this.previewTarget.offsetParent !== null,
      dropzoneHidden: this.dropzoneTarget.classList.contains('d-none'),
      html: this.previewTarget.innerHTML.trim().substring(0, 80)
    })
  }

  showPreview() {
    this.previewTarget.classList.remove('d-none')
    this.dropzoneTarget.classList.add('d-none')
    this.previewTarget.scrollIntoView({ behavior: 'smooth', block: 'nearest' })
  }

  showExistingFile(name, mimeType) {
    const icon = this.getFileIcon(mimeType)
    this.previewTarget.innerHTML = `
      <div class="d-flex align-items-center gap-3 p-3 border rounded">
        <div style="font-size: 3rem;">${icon}</div>
        <div class="flex-grow-1">
          <div class="fw-bold">${name}</div>
          <div class="text-muted small">Fichier existant</div>
        </div>
        <button type="button"
                class="btn btn-sm btn-danger"
                data-action="file-upload#remove">
          ✕ Supprimer
        </button>
      </div>
    `
    this.showPreview()
  }

  remove(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.innerHTML = ''
    this.previewTarget.classList.add('d-none')
    this.dropzoneTarget.classList.remove('d-none')

    // Clear the Shrine cached data hidden field
    const dataField = this.element.querySelector('input[type="hidden"][name*="_data"]')
    if (dataField) dataField.value = ''

    if (this.hasFileNameTarget) {
      this.fileNameTarget.classList.add('d-none')
    }
  }

  // Click on dropzone triggers file input
  triggerInput(event) {
    event.preventDefault()
    this.inputTarget.click()
  }

  getFileIcon(mimeType) {
    if (mimeType.startsWith('image/')) return '🖼️'
    if (mimeType.includes('pdf')) return '📄'
    if (mimeType.includes('word') || mimeType.includes('document')) return '📝'
    if (mimeType.includes('sheet') || mimeType.includes('excel')) return '📊'
    if (mimeType.includes('video')) return '🎥'
    return '📎'
  }

  formatFileSize(bytes) {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }
}
