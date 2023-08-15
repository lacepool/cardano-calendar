class Events::SimpleEvent < OpenStruct
  FILE_PATH = Rails.root.join("config", "simple_events.json").freeze
  ALL = JSON.parse(File.read(FILE_PATH))

  def self.default_off_filter
    ALL.values.map do |subcats|
      subcats.select { |k,v| v["filter_default_value"] == "off" }.keys
    end.flatten
  end

  def self.all(between:, except: [])
    all = ALL.values.reduce({}) do |h, subcats|
      subcats.except(*except).each do |subcat|
        if subcat[1]["recurring"]
          h[subcat[0]] = subcat[1]["recurring"]
        else
          h[subcat[0]] = subcat[1]["events"]
        end
      end
      h
    end

    between_dates(all, between)
  end

  def id
    Digest::MD5.hexdigest(name)
  end

  def time_range
    start_time..end_time
  end

  private

    def self.between_dates(data, date_range)
      arr = []

      data.each do |category, events|
        if events.is_a?(Hash) && events["frequency"]
          frequency = ActiveSupport::Duration.parse(events["frequency"])
          first_at = Time.at(events["schedule_start_time"]).in_time_zone

          if events["schedule_end_time"]
            last_at = Time.at(events["schedule_end_time"]).in_time_zone
          else
            last_at = Time.current.in_time_zone + 1.year
          end

          if events["duration"]
            duration = ActiveSupport::Duration.parse(events["duration"])
          else
            duration = 0.seconds
          end

          recurrence = Montrose.every(frequency, starts: first_at, until: last_at).events.each do |date|
            if date_range.include?(date)
              arr << new(
                start_time: date,
                end_time: date + duration,
                name: events["event_name"],
                description: events["event_description"],
                category: category
              )
            end
          end
        else
          events.map do |event|
            start_time = Time.at(event["start_time"]).in_time_zone
            end_time = Time.at(event["end_time"]).in_time_zone

            if date_range.overlaps?(start_time..end_time)
              arr << new(
                start_time: start_time,
                end_time: end_time,
                name: event["name"],
                description: event["description"],
                category: category
              )
            end
          end
        end
      end

      arr
    end
end