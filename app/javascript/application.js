// Entry point for the build script in your package.json
import { Turbo } from "@hotwired/turbo-rails"
Turbo.session.drive = true

import * as bootstrap from "bootstrap"

document.addEventListener("turbo:before-fetch-request", function(e){
    const logo = document.querySelector('#cardano-logo');
    logo.classList.add('spinning');
})
document.addEventListener("turbo:frame-render", function(e) { //
    const logo = document.querySelector('#cardano-logo');
    logo.classList.remove('spinning');
})

function ready(callback){
    // in case the document is already rendered
    if (document.readyState!='loading') callback();
    // modern browsers
    else if (document.addEventListener) document.addEventListener('DOMContentLoaded', callback);
    // IE <= 8
    else document.attachEvent('onreadystatechange', function(){
        if (document.readyState=='complete') callback();
    });
}

ready(function(){
  const toastElList = document.querySelectorAll('.toast');
  const toastList = [...toastElList].map(toastEl => new bootstrap.Toast(toastEl, {animation: true}));

  [...toastList].map(toast => toast.show())
});

ready(function(){
  const popoverTriggerList = document.querySelectorAll('[data-bs-toggle="popover"]')
  const popoverList = [...popoverTriggerList].map(popoverTriggerEl => new bootstrap.Popover(popoverTriggerEl, { trigger: 'focus' }))
});


/*!
 * Color mode toggler for Bootstrap's docs (https://getbootstrap.com/)
 * Copyright 2011-2023 The Bootstrap Authors
 * Licensed under the Creative Commons Attribution 3.0 Unported License.
 */

(() => {
  'use strict'

  const getStoredTheme = () => localStorage.getItem('theme')
  const setStoredTheme = theme => localStorage.setItem('theme', theme)

  const getPreferredTheme = () => {
    const storedTheme = getStoredTheme()
    if (storedTheme) {
      return storedTheme
    }

    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  const setTheme = theme => {
    if (theme === 'auto' && window.matchMedia('(prefers-color-scheme: dark)').matches) {
      document.documentElement.setAttribute('data-bs-theme', 'dark')
    } else {
      document.documentElement.setAttribute('data-bs-theme', theme)
    }
  }

  setTheme(getPreferredTheme())

  const showActiveTheme = (theme, focus = false) => {
    const themeSwitcher = document.querySelector('#themeSwitcher')

    if (!themeSwitcher) {
      return
    }

    const activeState = theme == 'light' ? true : false
    themeSwitcher.checked = activeState;

    // const themeSwitcherText = document.querySelector('#bd-theme-text')
    // const activeThemeIcon = document.querySelector('.theme-icon-active use')
    const btnToActive = document.querySelector(`[data-bs-theme-value="${theme}"]`)
    // const svgOfActiveBtn = btnToActive.querySelector('svg use').getAttribute('href')

    // document.querySelectorAll('[data-bs-theme-value]').forEach(element => {
    //   element.classList.remove('active')
    //   element.setAttribute('aria-pressed', 'false')
    // })

    // btnToActive.classList.add('active')
    // btnToActive.setAttribute('aria-pressed', 'true')
    // activeThemeIcon.setAttribute('href', svgOfActiveBtn)
    // const themeSwitcherLabel = `${themeSwitcherText.textContent} (${btnToActive.dataset.bsThemeValue})`
    // themeSwitcher.setAttribute('aria-label', themeSwitcherLabel)

    if (focus) {
      themeSwitcher.focus()
    }
  }

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    const storedTheme = getStoredTheme()
    if (storedTheme !== 'light' && storedTheme !== 'dark') {
      setTheme(getPreferredTheme())
    }
  })

  window.addEventListener('DOMContentLoaded', () => {
    showActiveTheme(getPreferredTheme())

    document.querySelectorAll('[data-bs-theme-value]')
      .forEach(toggle => {
        toggle.addEventListener('click', () => {
          const theme = toggle.checked ? 'light' : 'dark'
          setStoredTheme(theme)
          setTheme(theme)
          showActiveTheme(theme, true)
        })
      })
  })
})()
