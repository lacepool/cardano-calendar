module EventCharacteristics
  extend ActiveSupport::Concern

  def time_range
    start_time..end_time
  end

  def momentary?
    start_time == end_time
  end

  def one_day?
    start_time.day == end_time.day
  end
end