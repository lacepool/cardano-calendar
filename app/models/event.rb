class Event < ApplicationRecord
  include EventCharacteristics

  enum category: %i(
    meetup
    delegations
    staking_rewards
    pool_rewards
    pool_deposit_refund
    software_releases
  )

  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }
end