class Events::SimpleEvent
  attr_reader :start_time, :end_time, :open_end, :time_format,
              :name, :description, :category, :subcategory, :extras,
              :recurring

  FILE_PATH = Rails.root.join("config", "simple_events.json").freeze
  ALL = JSON.parse(File.read(FILE_PATH))

  include EventCharacteristics

  ALL.map do |category, filters|
    filters.each do |f|
      filter category: category, param: f[0], label: f[1]["filter_label"], default: f[1]["filter_default_value"]
    end
  end

  def initialize(category, subcategory, hsh, start_time: nil)
    @category = category
    @subcategory = subcategory

    @start_time = start_time || Time.at(hsh["start_time"]).in_time_zone

    if hsh["duration"]
      duration = ActiveSupport::Duration.parse(hsh["duration"])
    else
      duration = 0.seconds
    end

    if hsh["end_time"]
      @end_time = Time.at(hsh["end_time"]).in_time_zone
    else
      @end_time = @start_time + duration
    end

    @open_end = !!hsh["open_end"]
    @time_format = hsh["time_format"]
    @name = hsh["name"]
    @description = hsh["description"]

    @extras = {}
    @extras.merge!("website" => hsh["website"]) if hsh["website"]
  end

  def self.find(id)
    start_time, category, subcategory, name = decode_id_parts(id)

    if event = ALL.dig(category, subcategory, "recurring")
      start_time = Time.at(start_time.to_i).utc
      # we know the exact time of this event, so we don't really need a time span
      return new_series(category, subcategory, event, start_time..start_time).try(:first)
    else
      event = ALL.dig(category, subcategory, "events").detect do |e|
        e["name"] == name.force_encoding('UTF-8') && e["start_time"] == start_time.to_i
      end

      return new(category, subcategory, event) if event
    end
  end

  def self.all(between:, except: [])
    all = ALL.each_with_object({}) do |category, h|
      h[category[0]] = category[1].except(*except)
    end

    between_dates(all, between)
  end

  def self.decode_id_parts(id)
    Base64.decode64(id).split("/", 4)
  end

  def id
    Base64.encode64("#{start_time.to_i}/#{category}/#{subcategory}/#{name}")
  end

  def open_end?
    @open_end == true
  end

  def tags
    [category]
  end

  private

    def self.between_dates(data=ALL, date_range)
      arr = []

      data.each do |category, subcategories|
        subcategories.each do |subcategory, v|
          if events = v["events"]
            events.map do |event|
              start_time = Time.at(event["start_time"]).in_time_zone
              end_time = Time.at(event["end_time"]).in_time_zone

              if date_range.overlaps?(start_time..end_time)
                arr << new(category, subcategory, event)
              end
            end
          elsif event = v["recurring"]
            arr.concat(new_series(category, subcategory, event, date_range))
          else
            next
          end
        end
      end

      arr
    end

    def self.new_series(category, subcategory, event, date_range)
      first_at = Time.at(event["schedule_start_time"]).in_time_zone

      if event["schedule_end_time"]
        last_at = Time.at(event["schedule_end_time"]).in_time_zone
      else
        last_at = Time.current.in_time_zone + 1.year
      end

      interval = ActiveSupport::Duration.parse(event["interval"])
      recurrence = Montrose.every(interval, starts: first_at, until: last_at)

      if event["on"]
        r2 = Montrose.on(event["on"].map(&:to_sym))
        recurrence = recurrence.merge(r2)
      end

      arr = []

      recurrence.events.each do |date|
        if date_range.include?(date)
          arr << new(category, subcategory, event, start_time: date)
        end
      end

      arr
    end
end