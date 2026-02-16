import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = ["input", "preview", "dropzone", "fileName"]
  static values = {
    maxSize: { type: Number, default: 10485760 }, // 10MB default
    accept: { type: String, default: "image/*" }
  }

  connect() {
    console.log("FileUpload controller connected")
    this.setupDragAndDrop()
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
    this.handleFiles(files)
  }

  // Triggered when file input changes
  change(event) {
    const files = event.target.files
    this.handleFiles(files)
  }

  handleFiles(files) {
    if (files.length === 0) return

    const file = files[0]

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
      this.previewTarget.classList.remove('d-none')
      this.dropzoneTarget.classList.add('d-none')
    }

    reader.readAsDataURL(file)
  }

  previewFile(file) {
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
    this.previewTarget.classList.remove('d-none')
    this.dropzoneTarget.classList.add('d-none')
  }

  remove(event) {
    event.preventDefault()
    this.inputTarget.value = ''
    this.previewTarget.innerHTML = ''
    this.previewTarget.classList.add('d-none')
    this.dropzoneTarget.classList.remove('d-none')

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
