import { Controller } from "@hotwired/stimulus"
import * as bootstrap from "bootstrap"

export default class extends Controller {
  static targets = [ 'filter', 'view' ]

  viewTargetConnected(element) {
    const defaultClasses = element.querySelector("a:not(.active)").className
    const activeClasses = element.querySelector("a.active").className
    const viewLinks = [...element.children]

    viewLinks.forEach(link => {
      link.addEventListener('click', event => {
        viewLinks.forEach(l => l.setAttribute("class", defaultClasses))
        event.currentTarget.setAttribute("class", activeClasses)


        const currentUrl = new URL(document.location)
        currentUrl.pathname = event.currentTarget.dataset["view"]

        event.preventDefault()
        Turbo.visit(currentUrl)
      })
    })
  }

  filterTargetConnected(element) {
    element.addEventListener('click', event => {
      const currentUrl = new URL(document.location)
      const currentParams = currentUrl.searchParams
      const filterParam = event.currentTarget.dataset["filterParam"]
      const defaultValue = event.currentTarget.dataset["filterDefault"]
      const switchInput = event.currentTarget.children[0]

      currentParams.delete("filter["+filterParam+"]")

      if(switchInput.checked) {
        if(defaultValue == "off") currentParams.set("filter["+filterParam+"]", "on")
      }
      else {
        if(defaultValue == "on") currentParams.set("filter["+filterParam+"]", "off")
      }

      Turbo.visit(currentUrl)
    })
  }

  // filtersTargetConnected(element) {
  //   const toggleBtn = document.getElementById('filterToggle')
  //   const offcanvas = new bootstrap.Offcanvas(element)

  //   toggleBtn.addEventListener('click', event => {
  //     if(element.classList.contains('show')) {
  //       offcanvas.hide()
  //     }
  //     else {
  //       offcanvas.show()
  //     }
  //   })

  //   element.addEventListener('shown.bs.offcanvas', () => {
  //     const url = new URL(location)
  //     url.searchParams.set('filters', 'show')

  //     Turbo.visit(url.pathname + url.search)
  //   })

  //   element.addEventListener('hidden.bs.offcanvas', () => {
  //     const url = new URL(location)
  //     url.searchParams.delete('filters')

  //     Turbo.visit(url.pathname + url.search)
  //   })
  // }
}
