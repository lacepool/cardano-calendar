class EventFilter
  def self.default_off
    @default_off ||= by_default("off")
  end

  def self.default_on
    @default_on ||= by_default("on")
  end

  def self.by_class(klass)
    all.values.reduce([]) do |arr, filters|
      matching = filters.select { |_, v| v[:class] == klass }
      arr << matching if matching.any?
      arr
    end
  end

  def self.default_for(param)
    all.map do |category, filters|
      filter = filters.detect { |filter_param, filter| filter_param == param }
      break filter[1][:default] if filter
    end
  end

  def self.all
    EventFilterRegistry.registered
  end

  private

  def self.by_default(state)
    all.values.map do |filters|
      filters.select { |_,v| v[:default] == state }.keys
    end.flatten
  end
end
