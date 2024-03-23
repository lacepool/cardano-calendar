namespace :pools do
  desc "Sync Stake Pools"
  task sync: :environment do
    StakePool.create_from_delegation_events
    Events::StakePool.create_update_events
  end
end
