import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = [ 'show' ]

  initialize() {
    let currentUrl = new URL(document.location)

    if(currentUrl.hash) {
      let id = currentUrl.hash.split('#')[1]
      let element = this.element.querySelector('#'+CSS.escape(id))
      this.selectDayTest(element)
    }
  }

  selectDay(event) {
    this.selectDayTest(event.currentTarget)
  }

  selectDayTest(day) {
    let allDays = [...day.parentElement.parentElement.querySelectorAll('td')].filter(child => child !== day)

    allDays.forEach(d => d.classList.remove("active"))
    day.classList.toggle("active")

    window.location.hash = day.getAttribute("id")
  }

  showTargetConnected(element) {
    if (element.dataset["format"] == "html") {
      element.addEventListener('hide.bs.modal', event => {
        const url = new URL(document.location)
        url.pathname = "month"
        url.searchParams.append("start_date", element.dataset["startDate"])

        if (element.dataset["filterDefault"] == "off") {
          url.searchParams.append("filter["+element.dataset["filterParam"]+"]", "on")
        }

        Turbo.visit(url)
      })
    }

    new bootstrap.Modal(element, {}).show()
  }
}
