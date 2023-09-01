namespace :wallets do
  desc "Sync all delegations and rewards"
  task sync_all: [:environment, 'wallets:sync_delegations', 'wallets:sync_rewards']

  desc "Sync wallet delegations"
  task sync_delegations: :environment do
    Wallet.in_batches.each_record(&:fetch_delegations)
  end

  desc "Sync wallet rewards"
  task sync_rewards: :environment do
    Wallet.in_batches.each_record(&:fetch_rewards)
  end
end