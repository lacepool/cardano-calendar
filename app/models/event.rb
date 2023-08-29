class Event < ApplicationRecord
  include EventCharacteristics
  extend Filterable

  enum category: %i(meetup)

  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }

  def website
    extras.try(:[], "website")
  end
end