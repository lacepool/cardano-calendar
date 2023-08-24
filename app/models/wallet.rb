class Wallet < ApplicationRecord
  validates :stake_address, uniqueness: true

  after_create :fetch_events

  def fetch_events
    response = Blockfrost.client.get_account_delegations(stake_address)

    if response[:status] == 200
      response.dig(:body).each do |delegation|
        pool_id = delegation.fetch(:pool_id)
        pool = Blockfrost.client.get_pool_metadata(pool_id).dig(:body)
        pool_name = pool[:name] || "N/A"
        pool_ticker = pool[:ticker] || "N/A"

        Events::Wallet.new.tap do |event|
          event.name = "Delegation activates for pool #{pool_ticker}"
          event.description = "Wallet delegation becomes active for Cardano Stake Pool [#{pool_ticker}] #{pool_name} with ID #{pool_id}"
          event.category = :wallet
          event.start_time = Epoch.timestamp_from_epoch(delegation[:active_epoch])
          event.end_time = event.start_time
          event.extras = { stake_address: stake_address, stake_pool: pool }

          event.save
        end
      end
    else
      raise Blockfrost::ResponseError.new(response.body)
    end
  end
end