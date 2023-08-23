import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = [ 'popover', 'toast' ]

  popoverTargetConnected(element) {
    new bootstrap.Popover(element, { trigger: 'focus' })
  }

  modal(event) {
    const eventId = event.currentTarget.nextElementSibling.id

    new bootstrap.Modal(
      document.getElementById(eventId), {}
    ).show()
  }

  toastTargetConnected(element) {
    new bootstrap.Toast(element, { animation: true }).show()
  }
}
