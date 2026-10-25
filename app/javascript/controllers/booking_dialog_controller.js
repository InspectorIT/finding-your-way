import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
    static targets = ["dialog"]

    static values = {
        autoOpen: Boolean,
        profileId: Number
    }

    connect() {
        if (this.autoOpenValue && !this.dialogTarget.open) {
            this.dialogTarget.showModal()
        }
    }

    open() {
        if (!this.dialogTarget.open) {
            this.dialogTarget.showModal()
        }
    }

    close() {
        if (this.dialogTarget.open) {
            this.dialogTarget.close()
        }
    }

    closeOnBackdrop(event) {
        if (event.target === this.dialogTarget) {
            this.close()
        }
    }

    syncUrl() {
        const url = new URL(window.location.href)

        if (url.searchParams.get("calendar") !== String(this.profileIdValue)) {
            return
        }

        url.searchParams.delete("calendar")

        if (url.hash === `#psychologist-${this.profileIdValue}-calendar`) {
            url.hash = ""
        }

        window.history.replaceState(window.history.state, "", url)
    }
}
