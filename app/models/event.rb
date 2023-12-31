class Event < ApplicationRecord
  include EventCharacteristics

  enum category: %i(
    meetup
    delegations
    staking_rewards
    pool_rewards
    pool_deposit_refund
    software_releases
    research_papers
    hosksaid
  )

  scope :by_category, ->(category) { where(category: category) }
  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }
end
