class EventParamFilters
  def initialize(params)
    @params = params
  end

  def on_filters
    @on_filters ||= @params.select {|_, value| value == "on" }.keys
  end

  def off_filters
    @off_filters ||= @params.select {|_, value| value == "off" }.keys +
      EventFilter.default_off - on_filters
  end

  def is_on?(filter)
    if @params[filter].nil?
      return EventFilter.default_for(filter) == "on"
    end

    @params[filter] == "on"
  end

  def is_off?(filter)
    if @params[filter].nil?
      return EventFilter.default_for(filter) == "off"
    end

    @params[filter] == "off"
  end
end