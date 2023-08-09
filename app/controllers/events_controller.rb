class EventsController < ApplicationController
  helper_method :permitted_params

  def index
    off_filters = filter.select {|_, value| value == "off" }.keys

    events = Event.all(except: off_filters, between: date_range)
    @epochs = Epoch.all(between: date_range, with_events: events)
  end

  def start_date
    permitted_params.fetch(:start_date, Date.today).to_time
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
      :view, :start_date, :tz, filter: {}
    ).to_h.with_indifferent_access.symbolize_keys
  end
end
