(() => {
  'use strict'

  if (!window.scrollPositions) {
    window.scrollPositions = {"x": {}, "y": {}};
  }

  function preserveScroll() {
    let preservableElements = document.querySelectorAll("[data-preserve-scroll]")

    // internal interface, shouldn't be used but needed atm: https://github.com/hotwired/turbo/issues/37
    if (preservableElements.length > 0) Turbo.navigator.currentVisit.scrolled = true

    preservableElements.forEach((element) => {
      scrollPositions["y"][element.id] = element.scrollTop;
      scrollPositions["x"][element.id] = element.scrollLeft;
    })
  }

  function restoreScroll(event) {
    document.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
      element.scrollTop = scrollPositions["y"][element.id]
      element.scrollLeft = scrollPositions["x"][element.id]
    })

    if (!event.detail) return
    // event.detail.newBody is the body element to be swapped in.
    // for before-render only as turbo:render event.detail is null
    // https://turbo.hotwired.dev/reference/events
    event.detail.newBody.querySelectorAll("[data-preserve-scroll]").forEach((element) => {
      element.scrollTop = scrollPositions["y"][element.id]
      element.scrollLeft = scrollPositions["x"][element.id]
    })
  }

  window.addEventListener("turbo:before-cache", preserveScroll)
  window.addEventListener("turbo:before-render", event => restoreScroll(event))
  window.addEventListener("turbo:render", event => restoreScroll(event))
})()
