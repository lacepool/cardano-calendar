class Wallet < ApplicationRecord
  validates :stake_address, uniqueness: true

  after_create :fetch_all_events

  def fetch_all_events
    [:fetch_delegations, :fetch_rewards].each do |action|
      args = { wallet_id: id, action: action.to_s }.stringify_keys
      # WalletEventWorker.new.perform(args)
      WalletEventWorker.perform_async(args)
    end
  end

  def fetch_rewards
    rewards = Events::Wallet.staking_rewards.with_stake_address(stake_address)
    page = rewards.count/Blockfrost::PER_PAGE+1

    response = Blockfrost.client.get_account_rewards(stake_address, from_page: page)

    case response[:status]
    when 200
      response.dig(:body).each do |reward|
        # TODO: make sure not to create duplicates!

        epoch = reward[:epoch]
        ada_amount = (reward[:amount].to_i/1000000).floor(2)
        pool_id = reward.fetch(:pool_id)
        pool = Blockfrost.client.get_pool_metadata(pool_id).dig(:body)
        pool_name = pool[:name] || "N/A"
        pool_ticker = pool[:ticker] || "N/A"

        Events::Wallet.new.tap do |event|
          case reward[:type]
          when "member"
            event.name = "₳ #{ada_amount} staking rewards from [#{pool_ticker}]"
            event.description = "<p>Your account was credited with ₳ #{ada_amount} due to your active delegation to [#{pool_ticker}] #{pool_name} in epoch #{epoch-2}.</p><p>In Cardano's staking mechanism, there is a delay of two epochs between the epoch in which the pool created blocks and the epoch in which rewards are distributed:</p><p>Epoch #{epoch-2}: Block creation.<br>Epoch #{epoch-1}: The rewards for the previous epoch are calculated.<br>Epoch #{epoch}: The calculated rewards are distributed to stake pool operators and delegators.</p>"
            event.category = :staking_rewards
          when "leader"
            event.name = "₳ #{ada_amount} pool rewards for [#{pool_ticker}]"
            event.description = "<p>Your account was credited with ₳ #{ada_amount} due to the block creation of your pool [#{pool_ticker}] in epoch #{epoch-2}.</p>"
            event.category = :pool_rewards
          when "pool_deposit_refund"
            event.name = "₳ #{ada_amount} refund of pool deposit for [#{pool_ticker}]"
            event.description = "<p>Your account was credited with ₳ #{ada_amount} due to the refunding of your pool deposit for [#{pool_ticker}] #{pool_name}.</p>"
            event.category = :pool_deposit_refund
          end

          event.start_time = Epoch.timestamp_from_epoch(epoch)
          event.end_time = event.start_time
          event.extras = { stake_address: stake_address, stake_pool: pool, epoch: epoch, lovelace: reward[:amount] }
          event.save
        end
      end
    when 404
      # nothing
    when nil
      # nothing
    else
      raise Blockfrost::ResponseError.new(response[:body])
    end
  end

  def fetch_delegations
    response = Blockfrost.client.get_account_delegations(stake_address, from_page: 1)

    case response[:status]
    when 200
      response.dig(:body).each do |delegation|
        pool_id = delegation.fetch(:pool_id)
        pool = Blockfrost.client.get_pool_metadata(pool_id).dig(:body)
        pool_name = pool[:name] || "N/A"
        pool_ticker = pool[:ticker] || "N/A"

        Events::Wallet.new.tap do |event|
          event.name = "Delegation activates for pool #{pool_ticker}"
          event.description = "Wallet delegation becomes active for Cardano Stake Pool [#{pool_ticker}] #{pool_name} with ID #{pool_id}"
          event.category = :delegations
          event.start_time = Epoch.timestamp_from_epoch(delegation[:active_epoch])
          event.end_time = event.start_time
          event.extras = { stake_address: stake_address, stake_pool: pool }

          event.save
        end
      end
    when 404
      # nothing
    when nil
      # nothing
    else
      raise Blockfrost::ResponseError.new(response[:body])
    end
  end
end