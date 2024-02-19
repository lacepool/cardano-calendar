class EventsController < ApplicationController
  helper_method :event_params

  def index
    respond_to do |f|
      f.html do
        @epochs = epochs_with_events(between: helpers.date_range, events_sorted: true)
      end

      f.ics do
        @epochs = epochs_with_events(between: helpers.ics_date_range)

        if request.protocol.start_with?("http")
          send_data ics_calendar.to_ical, type: 'text/calendar', disposition: 'attachment', filename: "cardano-events.ics"
        else
          render plain: ics_calendar.to_ical
        end
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

    raise ActionController::RoutingError.new('Not Found') unless @event

    respond_to do |f|
      f.turbo_stream
      f.html
    end
  end

  private

  def is_active_record_event?(str)
    !!Integer(str)
  rescue ArgumentError, TypeError
    false
  end

  def epochs_with_events(between:, events_sorted: false)
    events = Events::SimpleEvent.all(except: helpers.filters.off_filters, between: between)
    events += Events::Meetup.where("extras->'group_urlname' ?| array[:names]", names: helpers.filters.on_filters).between(between)

    if helpers.wallet_connected?
      wallet_on_filters = EventFilter.by_class("Events::Wallet").map(&:values).flatten.map(&:keys).flatten - helpers.filters.off_filters
      events += Events::Wallet.by_category(wallet_on_filters).with_stake_address(params[:stake_address]).between(between)
    end

    papers_on_filters = EventFilter.by_class("Events::ResearchPaper").map(&:values).flatten.map(&:keys).flatten - helpers.filters.off_filters
    if papers_on_filters.any?
      papers_on_filters_years = papers_on_filters.map {|f| f.split("-").last }
      events += Events::ResearchPaper.where("extract(year from start_time) IN (#{papers_on_filters_years.join(',')})").between(between)
    end

    events += Events::Software.where("extras->'filter_param' ?| array[:repos]", repos: helpers.filters.on_filters).between(between)

    ama_on_filters = (EventFilter.by_class("Events::Ama").map(&:values).flatten.map(&:keys).flatten - helpers.filters.off_filters).uniq
    events += Events::Ama.by_category(ama_on_filters).between(between) if ama_on_filters.any?

    events = events.sort_by(&:start_time) if events_sorted

    Epoch.all(between: between, with_events: events)
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
              ce.description = event_url(name: event.urlname, id: event.id)
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

  def event_params
    @event_params ||= params.permit(
      :filter_param, :filter_class,
      :format, :view, :start_date, :tz, :stake_address, filter: {}
    ).to_h.with_indifferent_access.symbolize_keys
  end
end
