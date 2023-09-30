import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ 'offcanvasBody' ]
  static values = {
    view: String
  }

  updateSubscribeLink(event) {
    const linkElement = event.currentTarget
    const currentUrl = new URL(document.location)
    const currentSearchParams = currentUrl.searchParams
    const linkUrl = new URL(linkElement.href)

    // Not required, but removing start_date from params
    currentSearchParams.delete('start_date')

    // The link uses webcal protocol.
    // It seems weird but `linkUrl.origin` is null and pathname contains the url
    const newUrl = linkUrl.protocol + linkUrl.pathname + currentUrl.search

    linkElement.setAttribute('href', newUrl)
  }

  offcanvasBodyTargetConnected(element) {
    const viewLinks = [...element.querySelectorAll('a.event_view')]
    const filterToggle = [...element.querySelectorAll('.event_filter input')]

    document.documentElement.addEventListener("turbo:visit", event => {
      setTimeout(() => {
        viewLinks.forEach(link => link.classList.add('disabled'))
        filterToggle.forEach(toggle => toggle.setAttribute('disabled', ''))
      }, "100")
    })

    'turbo:render turbo:before-stream-render'.split(' ').forEach(eventStr => {
      document.documentElement.addEventListener(eventStr, event => {
        setTimeout(() => {
          viewLinks.forEach(link => link.classList.remove('disabled'))
          filterToggle.forEach(toggle => toggle.removeAttribute('disabled'))
        }, "100")
      })
    })
  }

  toggleView(event) {
    const viewElement = event.currentTarget
    const siblings = [...viewElement.parentElement.children].filter(child => child !== viewElement)
    const defaultClasses = viewElement.parentElement.querySelector("a:not(.active)").className
    const activeClasses = viewElement.parentElement.querySelector("a.active").className

    siblings.forEach(s => s.setAttribute("class", defaultClasses))
    viewElement.setAttribute("class", activeClasses)
  }

  toggleFilter(event) {
    const switchInput = event.currentTarget
    const currentUrl = new URL(document.location)
    const currentParams = currentUrl.searchParams
    const filterParam = switchInput.dataset["filterParam"]
    const defaultValue = switchInput.dataset["filterDefault"]

    currentParams.delete("filter["+filterParam+"]")

    if(switchInput.checked) {
      if(defaultValue == "off") currentParams.set("filter["+filterParam+"]", "on")
    }
    else {
      if(defaultValue == "on") currentParams.set("filter["+filterParam+"]", "off")
    }

    Turbo.visit(currentUrl, { action: "restore" })
  }
}