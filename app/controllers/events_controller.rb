class EventsController < ApplicationController
  helper_method :permitted_params, :wallet_connected?, :event_param_filters

  def index
    respond_to do |f|
      f.html do
        @epochs = epochs_with_events(between: date_range, events_sorted: true)
      end

      f.ics do
        @epochs = epochs_with_events(between: ics_date_range)
        render plain: ics_calendar.to_ical
      end
    end
  end

  def show
    id = params.fetch(:id)

    if is_active_record_event?(id)
      @event = Event.find(id)
    else
      @event = Events::SimpleEvent.find(id)
    end

    respond_to do |f|
      f.turbo_stream
      f.html
    end
  end

  def is_active_record_event?(str)
    !!Integer(str)
  rescue ArgumentError, TypeError
    false
  end

  def epochs_with_events(between:, events_sorted: false)
    events = Events::SimpleEvent.all(except: filters.off_filters, between: between)
    events += Events::Meetup.where("extras->'group_urlname' ?| array[:names]", names: filters.on_filters).between(between)

    if wallet_connected?
      wallet_on_filters = EventFilter.by_class("Events::Wallet").map(&:keys).flatten - filters.off_filters
      events += Events::Wallet.where(category: wallet_on_filters).with_stake_address(permitted_params[:stake_address]).between(between)
    end

    events += Events::Software.where("extras->'filter_param' ?| array[:repos]", repos: filters.on_filters).between(between)

    events = events.sort_by(&:start_time) if events_sorted

    Epoch.all(between: between, with_events: events)
  end

  def wallet_connected?
    @wallet_connected ||= permitted_params[:stake_address] && Wallet.where(stake_address: permitted_params[:stake_address]).exists?
  end

  def start_date
    permitted_params.fetch(:start_date, Date.today).to_time
  end

  def ics_date_range
    Time.at(Epoch::SHELLY_UNIX).utc..(Time.current.utc + 6.months)
  end

  def ics_calendar
    current_timestamp = Time.current.utc.to_i

    Icalendar::Calendar.new.tap do |cal|
      cal.x_wr_calname = "cardano-calendar.com"
      cal.description = "My Customized Cardano Events"
      cal.refresh_interval = "P4H"

      @epochs.each do |epoch|
        cal.event do |ce|
          ce.summary = epoch.name
          ce.description = "Slots #{epoch.start_slot} – #{epoch.end_slot}"
          ce.categories = "Epoch"
          ce.dtstart = epoch.start_time.utc
          ce.dtend = epoch.end_time.utc
          ce.uid = epoch.id
          ce.sequence = current_timestamp

          epoch.events.each do |event|
            cal.event do |ce|
              ce.summary = event.name
              ce.description = nil
              ce.dtstart = event.start_time.utc
              ce.categories = event.category
              ce.dtend = event.end_time.utc
              ce.uid = event.id.to_s
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

  def filters
    @filters ||= EventParamFilters.new(permitted_params.fetch(:filter, {}))
  end
  alias_method :event_param_filters, :filters

  def permitted_params
    params.permit!.to_h.with_indifferent_access
  end
end
