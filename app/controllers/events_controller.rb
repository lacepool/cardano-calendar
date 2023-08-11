class EventsController < ApplicationController
  helper_method :permitted_params

  def index
    off_filters = filter.select {|_, value| value == "off" }.keys
    on_filters = filter.select {|_, value| value == "on" }.keys

    respond_to do |f|
      f.html do
        events = Events::SimpleEvent.all(except: off_filters, between: date_range)
        events += Events::LeaderlogCheck.all(between: date_range) if on_filters.include?("leaderlog-check")
        @epochs = Epoch.all(between: date_range, with_events: events)
      end

      f.ics do
        events = Events::SimpleEvent.all(except: off_filters, between: ics_date_range)
        events += Events::LeaderlogCheck.all(between: date_range) if on_filters.include?("leaderlog-check")
        @epochs = Epoch.all(between: ics_date_range, with_events: events)

        render plain: ics_calendar.to_ical
      end
    end
  end

  def start_date
    permitted_params.fetch(:start_date, Date.today).to_time
  end

  def ics_date_range
    Time.at(Epoch::SHELLY_UNIX).utc..(Time.current.utc + 1.year)
  end

  def ics_calendar
    current_timestamp = Time.current.utc.to_i

    Icalendar::Calendar.new.tap do |cal|
      cal.x_wr_calname = "cardano-calendar.com"

      @epochs.each do |epoch|
        cal.event do |ce|
          ce.summary = epoch.name
          ce.description = "Slots #{epoch.start_slot} – #{epoch.end_slot}"
          ce.dtstart = epoch.start_time.utc
          ce.dtend = epoch.end_time.utc
          ce.uid = epoch.id
          ce.sequence = current_timestamp

          epoch.events.each do |event|
            cal.event do |ce|
              ce.summary = event.name
              ce.description = event.description
              ce.dtstart = event.start_time.utc
              ce.dtend = event.end_time.utc
              ce.uid = event.id
              ce.sequence = current_timestamp
            end
          end
        end
      end

      cal.publish
    end
  end

  def date_range
    if permitted_params[:view] == "list"
      start_date.beginning_of_month..start_date.end_of_month
    else
      start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week.end_of_day
    end
  end

  def filter
    @filter ||= permitted_params.fetch(:filter, {})
  end

  def permitted_params
    @params ||= params.permit(
      :format, :view, :start_date, :tz, filter: {}
    ).to_h.with_indifferent_access.symbolize_keys
  end
end
