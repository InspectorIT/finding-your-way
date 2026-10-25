import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static values = {
        key: String
    }

    connect() {
        try {
            if (sessionStorage.getItem(this.keyValue) === "dismissed") {
                this.element.hidden = true
            }
        } catch {
            // Уведомление останется рабочим, даже если хранилище недоступно.
        }
    }

    dismiss() {
        this.element.hidden = true

        try {
            sessionStorage.setItem(this.keyValue, "dismissed")
        } catch {
            // Скрываем уведомление хотя бы до следующего отображения элемента.
        }
    }
}
