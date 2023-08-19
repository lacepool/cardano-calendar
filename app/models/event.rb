class Event < ApplicationRecord
  include EventCharacteristics

  enum category: [:meetup]

  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }

  def website
    extras["website"] if extras
  end
end