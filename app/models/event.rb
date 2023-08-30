class Event < ApplicationRecord
  include EventCharacteristics
  extend Filterable

  enum category: %i(
    meetup
    delegations
    staking_rewards
    pool_rewards
    pool_deposit_refund
  )

  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }

  def website
    extras.try(:[], "website")
  end
end