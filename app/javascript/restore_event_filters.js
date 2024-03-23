(() => {
  'use strict'

  document.addEventListener('DOMContentLoaded', () => {
    const currentUrl = new URL(document.location)

    // if no filters set => check localStorage for filters
    // if filters found in localStorage => ask user to restore stored filters, and option to delete from localStorage

    const storedFilters = localStorage.getItem("eventFilters").forEach(filter => filter)

    if (currentUrl.searchParams != ) {

      // 
      // Turbo.visit(url)
    }

    if()
  })
})()
