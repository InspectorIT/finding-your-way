import { Controller } from "@hotwired/stimulus"
import Cropper from "cropperjs"

export default class extends Controller {
    static targets = ["input", "image", "preview", "cropButton", "warning"]

    connect() {
        this.cropper = null
        this.objectUrl = null
        this.cropConfirmed = false
    }

    disconnect() {
        this.imageTarget.onload = null
        this.destroyCropper()
        this.revokeObjectUrl()
    }

    select(event) {
        const file = event.target.files[0]

        // Новая фотография требует нового подтверждения обрезки.
        this.cropConfirmed = false
        this.warningTarget.hidden = true
        this.cropButtonTarget.textContent = "Обрезать фотографию"
        this.cropButtonTarget.disabled = true

        this.destroyCropper()
        this.revokeObjectUrl()
        this.imageTarget.onload = null

        if (!file) {
            this.previewTarget.hidden = true
            return
        }

        if (!file.type.startsWith("image/")) {
            alert("Выберите файл изображения.")
            this.inputTarget.value = ""
            this.previewTarget.hidden = true
            return
        }

        this.objectUrl = URL.createObjectURL(file)
        this.previewTarget.hidden = false

        this.imageTarget.onload = () => {
            this.imageTarget.onload = null

            this.cropper = new Cropper(this.imageTarget, {
                aspectRatio: 4 / 3,
                viewMode: 1,
                dragMode: "move",
                autoCropArea: 1,
                responsive: true,
                background: false
            })

            this.cropButtonTarget.disabled = false
        }

        this.imageTarget.src = this.objectUrl
    }

    crop() {
        this.cropConfirmed = false
        this.warningTarget.hidden = true

        if (!this.cropper) return

        this.cropButtonTarget.disabled = true

        const canvas = this.cropper.getCroppedCanvas({
            width: 1200,
            height: 900,
            imageSmoothingEnabled: true,
            imageSmoothingQuality: "high"
        })

        if (!canvas) {
            alert("Не удалось обрезать фотографию.")
            this.cropButtonTarget.disabled = false
            return
        }

        canvas.toBlob(blob => {
            if (!blob) {
                alert("Не удалось обрезать фотографию.")
                this.cropButtonTarget.disabled = false
                return
            }

            const croppedFile = new File(
                [blob],
                "psychologist-photo.jpg",
                { type: "image/jpeg" }
            )

            const transfer = new DataTransfer()
            transfer.items.add(croppedFile)
            this.inputTarget.files = transfer.files

            // Подтверждение устанавливаем только после успешной обрезки.
            this.cropConfirmed = true

            this.destroyCropper()
            this.revokeObjectUrl()

            this.objectUrl = URL.createObjectURL(blob)
            this.imageTarget.onload = null
            this.imageTarget.src = this.objectUrl

            this.cropButtonTarget.textContent = "Фото обрезано"
            this.cropButtonTarget.disabled = true
        }, "image/jpeg", 0.9)
    }

    validateSubmit(event) {
        const photoSelected = this.inputTarget.files.length > 0

        if (photoSelected && !this.cropConfirmed) {
            event.preventDefault()

            this.warningTarget.textContent =
                "Вы прикрепили фотографию, но не обрезали её. Нажмите «Обрезать фотографию» перед отправкой заявки."

            this.warningTarget.hidden = false
            this.cropButtonTarget.focus()
        }
    }

    destroyCropper() {
        if (this.cropper) {
            this.cropper.destroy()
            this.cropper = null
        }
    }

    revokeObjectUrl() {
        if (this.objectUrl) {
            URL.revokeObjectURL(this.objectUrl)
            this.objectUrl = null
        }
    }
}