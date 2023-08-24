import CardanoWallets from '@koralabs/cardano-wallets';
import numeral from "numeral";

'use strict'

var WalletConnect = {
  utils: {
    dropDownList: function() { return document.getElementById('wallet-dropdown-list') },
    spinner: function() { return document.getElementById('wallet-dropdown-spinner') },
    cardano: window.cardano,
    listLabel: function() { return document.getElementById('wallet-dropdown-text') },
    supportedWallets: ['eternl', 'lace', 'typhon', 'yoroi', 'nami', 'nufi'],
  },
  init: function(){
    this.buildDropDown()

    const lastConnectedWallet = this.getLastConnectedWallet();

    if(lastConnectedWallet) {
      this.connectToWallet(lastConnectedWallet)
      // this.handleActiveStates(lastConnectedWallet)
      return
    }
  },
  enableSpinner: function(){ this.utils.spinner().classList.remove("d-none")},
  disableSpinner: function(){ this.utils.spinner().classList.add("d-none")},
  getLastConnectedWallet: () => localStorage.getItem('lastConnectedCardanoWallet'),
  setLastConnectedWallet: walletKey => localStorage.setItem('lastConnectedCardanoWallet', walletKey),
  availableWallets: function() {
    return [...this.utils.supportedWallets].map(walletKey => (
      {
        walletKey: walletKey,
        wallet: cardano[walletKey]
      }
    )).filter(item => item['wallet'] != undefined)
  },
  buildDropDown: function() {
    let _this = this
    let utils = this.utils

    this.availableWallets().forEach((item) => {
      const walletKey = item['walletKey']
      const walletName = item['wallet'].name
      const li = document.createElement('li')
      const link = document.createElement('a')
      const linkText = document.createTextNode(walletName)

      link.appendChild(linkText)
      link.classList.add('dropdown-item')
      link.dataset.wallet = walletKey
      li.appendChild(link)
      utils.dropDownList().appendChild(li)

      link.addEventListener('click', (event) => {
        _this.connectToWallet(walletKey)
        // _this.handleActiveStates(walletKey)
      });
    });
  },
  // handleActiveStates: function(walletKey){
  //   this.utils.walletLinks.filter(l => l.dataset.wallet !== walletKey).forEach((link) => link.classList.add('disabled'))
  //   this.utils.walletLinks.filter(l => l.dataset.wallet === walletKey).forEach((link) => link.classList.add('active'))
  // },
  connectToWallet: function(walletKey){
    _this = this
    utils = this.utils

    this.enableSpinner()
    utils.listLabel.innerHTML = "Connecting Wallet"

    debugger
    CardanoWallets.connect(walletKey).then(
      async result => {
        const isMainnet = await CardanoWallets.isMainnet();
        if (!isMainnet) {
          throw new Error('Wallet must be in Mainnet');
        }

        _this.setLastConnectedWallet(walletKey)

        CardanoWallets.getRewardAddresses().then(
          async result => {
            const addr = result[0];
            const short_addr = addr.substr(0, 9) + ".." + addr.substr(-3)
            const balance = await CardanoWallets.getAdaBalance();

            utils.listLabel().innerHTML = short_addr + ' | ₳' + numeral(balance).format('(0.00 a)');

            this.disableSpinner()

            const headers = { "Content-Type": "application/json; charset=utf-8" };
            const body = JSON.stringify({wallet: {stake_address: addr}});

            const response = await fetch("/wallets", { method: 'POST', body: body, headers: headers})
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
            throw new Error('Error getting reward addresses');
          }
        )
      },
      err => {
        throw new Error('Error connecting to wallet');
      }
    )
  }
}

document.addEventListener("DOMContentLoaded", () => {
  WalletConnect.init();
});
