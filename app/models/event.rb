class Event < ApplicationRecord
  enum category: [:meetup]

  scope :between, ->(date_range) { where(start_time: date_range).or(where(end_time: date_range)) }

  def time_range
    start_time..end_time
  end
end