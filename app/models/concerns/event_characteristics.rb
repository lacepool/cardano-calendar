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

  def add_to_calendar
    AddToCalendar::URLs.new(
      start_datetime: start_time,
      end_datetime: end_time,
      description: description,
      title: name,
      timezone: Time.zone.tzinfo.identifier
    )
  end
end