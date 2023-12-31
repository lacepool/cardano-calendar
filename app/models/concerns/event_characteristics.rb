module EventCharacteristics
  extend ActiveSupport::Concern
  include Filterable

  # to be overwritten if needed
  def recurring
    false
  end

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

  def tags
    if self.respond_to?(:model_name)
      EventFilter.by_class(self.model_name).map(&:keys).flatten
    else
      []
    end
  end

  def website
    extras.try(:[], "website")
  end

  def footer_links
    extras.try(:[], "footer_links")
  end

  def urlname
    name.parameterize
  end
end
