class StakePool < ApplicationRecord
  scope :active, -> { where.not(ticker: nil) }
  # after_create :add_as_event_filter

  # This adds a newly created record as a filter value at runtime.
  # This is only required once, until next applicaction boot.
  #
  # def add_as_event_filter
  #   Events::StakePool.add_filter(self)
  # end

  def self.create_from_delegation_events
    Events::Wallet.delegations.each do |delegation|
      pool = delegation.extras["stake_pool"]

      next if where(poolid: pool["pool_id"]).exists?

      new.tap do |p|
        p.ticker = pool["ticker"]
        p.name = pool["name"]
        p.hex = pool["hex"]
        p.description = pool["description"]
        p.poolid = pool["pool_id"]
        p.homepage = pool["homepage"]

        p.save!
      end
    end
  end

  def full_name
    if ticker.present? && name.present?
      "[#{ticker}] #{name}"
    else
      "Retired (#{poolid.first(12)})"
    end
  end
end
