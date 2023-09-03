import CardanoWallets from '@koralabs/cardano-wallets'
import numeral from "numeral"
import * as bootstrap from "bootstrap"

'use strict'

var WalletConnect = {
  utils: {
    dropDownContainer: function() { return document.getElementById('walletConnect') },
    disconnectLink: function() { return document.getElementById('walletConnectDisconnect') },
    dropDownToggle: function() { return document.getElementById('walletConnectToggle') },
    walletList: function() { return document.getElementById('walletList') },
    dropDownToggleLabel: function() { return document.getElementById('walletConnectToggleLabel') },
    dropDownToggleLabelText: "Connect Wallet",
    dropDowntoggleConnectingLabelText: "Connecting",
    disconnectIcon: '<i class="bi bi-eject-fill"></i>',
    spinner: function() { return document.getElementById('walletConnectSpinner') },
    supportedWallets: ['eternl', 'lace', 'typhoncip30', 'nami'],
    localStorageKey: "lastConnectedCardanoWallet",
  },
  init: function(){
    this.buildDropDown()

    const lastConnectedWallet = this.getLastConnectedWallet()

    if(lastConnectedWallet) {
      this.connectToWallet(lastConnectedWallet)
    }
  },
  enableSpinner: function(){ this.utils.spinner().classList.remove("d-none")},
  disableSpinner: function(){ this.utils.spinner().classList.add("d-none")},
  getLastConnectedWallet: function(){ return JSON.parse(localStorage.getItem(this.utils.localStorageKey)) },
  removeLastConnectedWallet: function(){ localStorage.removeItem(this.utils.localStorageKey)},
  setLastConnectedWallet: function(wallet){ localStorage.setItem(this.utils.localStorageKey, JSON.stringify(wallet))},
  availableWallets: function() {
    utils = this.utils
    arr = []
    return [...this.utils.supportedWallets].reduce((arr, walletKey) => {
      if(window.cardano[walletKey]) {
        arr.push(
          {
            walletKey: walletKey,
            walletName: window.cardano[walletKey].name,
            walletIcon: window.cardano[walletKey].icon
          }
        )
      }
      return arr
    }, [])
  },
  createWalletIcon: function(iconStr) {
    const icon = document.createElement('img')
    icon.setAttribute("src", iconStr)
    icon.setAttribute("width", "20")
    icon.classList.add('walletIcon', 'me-2')

    return icon
  },
  buildDropDown: function() {
    let _this = this
    let utils = this.utils

    // makes sure we start with an empty dropDownContainer
    const originalDropDownContainer = utils.dropDownContainer()
    const dropDownContainer = originalDropDownContainer.cloneNode(false)
    originalDropDownContainer.parentElement.replaceChild(dropDownContainer, originalDropDownContainer)

    // delete dropDownContainer.dataset.turboPermanent

    const dropDownToggle = document.createElement('a')
    dropDownToggle.classList.add("btn", "dropdown-toggle")
    dropDownToggle.dataset.bsToggle = "dropdown"
    dropDownToggle.setAttribute("id", "walletConnectToggle")
    dropDownToggle.setAttribute("aria-expanded", "false")

    const walletConnectToggleLabel = document.createElement("span")
    walletConnectToggleLabel.setAttribute("id", "walletConnectToggleLabel")
    walletConnectToggleLabel.innerText = utils.dropDownToggleLabelText

    dropDownToggle.append(walletConnectToggleLabel)
    dropDownContainer.append(dropDownToggle)

    const walletList = document.createElement('ul')
    walletList.setAttribute("id", "walletList")

    if (this.availableWallets().length > 0) {
      walletList.classList.add("dropdown-menu")
      dropDownToggle.after(walletList)
    }

    this.availableWallets().forEach((item) => {
      const walletListItem = document.createElement('li')

      const link = document.createElement('a')
      link.setAttribute("href", "#")
      link.classList.add('py-2')
      const linkText = document.createTextNode(item['walletName'])

      const icon = this.createWalletIcon(item['walletIcon'])

      link.appendChild(icon)
      link.appendChild(linkText)

      link.classList.add('dropdown-item')
      link.dataset.wallet = item['walletKey']

      walletListItem.appendChild(link)
      walletList.appendChild(walletListItem)

      link.addEventListener('click', (event) => {
        _this.connectToWallet(item)
        event.preventDefault()
      })
    })

    new bootstrap.Dropdown(utils.dropDownToggle())
  },
  disconnectWallet: async function() {
    await CardanoWallets.disableWallet()
    this.removeLastConnectedWallet()
    this.utils.dropDownContainer().classList.remove("connected")
    this.buildDropDown()

    const url = new URL(document.location)
    url.searchParams.delete("stake_address")
    Turbo.visit(url.pathname + url.search)
  },
  connectToWallet: function(wallet){
    _this = this
    utils = this.utils

    const spinner = document.createElement("span")
    spinner.classList.add("spinner-border", "spinner-border-sm", "me-2")
    spinner.setAttribute("id", "walletConnectSpinner")
    spinner.setAttribute("role", "status")
    spinner.setAttribute("aria-hidden", "true")
    utils.dropDownToggle().prepend(spinner)

    utils.dropDownContainer().dataset.turboPermanent = "" // set data-turbo-permanent without value
    utils.walletList().remove()
    utils.dropDownToggle().classList.remove("dropdown-toggle")
    utils.dropDownToggle().classList.add("disabled", "border-0")

    utils.dropDownToggleLabel().innerText = utils.dropDowntoggleConnectingLabelText

    CardanoWallets.connect(wallet['walletKey']).then(
      async result => {

        const isMainnet = await CardanoWallets.isMainnet()
        if (!isMainnet) {
          throw new Error('Wallet must be in Mainnet')
        }

        _this.setLastConnectedWallet(wallet)

        const disconnectLink = document.createElement("a")
        disconnectLink.classList.add("btn", "btn-sm", "btn-outline-secondary")
        disconnectLink.setAttribute("id", "walletConnectDisconnect")
        disconnectLink.innerHTML = utils.disconnectIcon
        disconnectLink.addEventListener('click', (event) => {
          _this.disconnectWallet()
          event.preventDefault()
        })

        utils.dropDownToggle().after(disconnectLink)

        const stakeAddresses = await CardanoWallets.getRewardAddresses()
        const addr = stakeAddresses[0]
        const short_addr = addr.substr(0, 9) + ".." + addr.substr(-4)

        const span = document.createElement("span")
        span.innerText = short_addr

        const icon = _this.createWalletIcon(wallet['walletIcon'])
        utils.dropDownToggleLabel().replaceChildren(icon)
        utils.dropDownToggleLabel().append(span)

        this.disableSpinner()
        utils.dropDownContainer().classList.add("connected")

        const headers = { "Content-Type": "application/json; charset=utf-8" }
        const body = JSON.stringify({wallet: {stake_address: addr}})

        fetch("/wallets", { method: 'POST', body: body, headers: headers})
          .then(response => {
            if(!response.ok) {
              throw new Error("HTTP status code: " + response.status)
            }
          })
          .catch(err => console.error("Error creating wallet"))

        const url = new URL(document.location)
        if (url.searchParams.get("stake_address") != addr){
          url.searchParams.append("stake_address", addr)
          Turbo.visit(url.pathname + url.search)
        }

      },
      err => {
        console.error(err)
        _this.buildDropDown()
      }
    )
  }
}

document.addEventListener("DOMContentLoaded", () => {
// document.addEventListener('turbo:load', () => {
  WalletConnect.init()
})
