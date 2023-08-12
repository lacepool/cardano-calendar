class Events::SimpleEvent < OpenStruct
  FILE_PATH = Rails.root.join("config", "simple_events.json").freeze
  ALL = JSON.parse(File.read(FILE_PATH))

  def self.all(between: nil, except: [])
    all = ALL.except(*except).reduce({}) do |hash, v|
      hash[v[0]] = v[1]["events"]
      hash
    end

    if between
      between_dates(all, between)
    else
      all
    end
  end

  def self.categories(except: [])
    ALL.except(*except).map { |k, v| { k => v["name"] } }
  end

  def self.filters
    ALL.map { |k, v| { "name" => v["name"], "param" => k, "default_value" => v.dig("filter", "default_value") } }
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

      arr
    end
end