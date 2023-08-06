class EventsController < ApplicationController
  helper_method :permitted_params

  def index
    @events = []
    off_filters = filter.select {|_, value| value == "false" }.keys

    unless off_filters.include?("epochs")
      @events = Events::Epoch.all(between: date_range)
    end

    @events += Events::Custom.all(except: off_filters, between: date_range)
  end

  def start_date
    permitted_params.fetch(:start_date, Date.today).to_date
  end

  def date_range
    start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week
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
