# Creates all wallet related events

class WalletEventWorker
  include Sidekiq::Worker

  sidekiq_options retry: 5, backtrace: 15

  def perform(options)
    wallet = Wallet.find(options["wallet_id"])
    wallet.send(options["action"])
  end
end
