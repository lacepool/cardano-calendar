class Events::Wallet < ::Event
  scope :with_stake_address, ->(addr) { where("extras @> ?", {stake_address: addr}.to_json) }

  filter category: "Staking", param: "delegations", label: "Stake Pool delegations", default: "on"
  filter category: "Staking", param: "staking_rewards", label: "Staking Rewards", default: "on"
  filter category: "Stake Pool Operators", param: "pool_rewards", label: "Pool Rewards", default: "off"
  filter category: "Stake Pool Operators", param: "pool_deposit_refund", label: "Pool Deposit Refunds", default: "off"
end