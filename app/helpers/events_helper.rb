module EventsHelper
  def current_view
    params.fetch(:view, "month")
  end

  def current_view_icon
    if list_view?
      css_class = "bi-#{current_view}"
    else
      css_class = "bi-calendar-#{current_view}"
    end

    tag.i class: css_class
  end

  def list_view?
    current_view == "list"
  end

  def start_date
    params.fetch(:start_date, Date.current).to_date
  end

  def date_range
    (start_date.beginning_of_month.beginning_of_week..start_date.end_of_month.end_of_week).to_a
  end

  def url_for_previous_view
    url_for(permitted_params.merge(
      :start_date => (date_range.first - 1.day).iso8601
    ).merge(view: current_view))
  end

   def url_for_next_view
    url_for(permitted_params.merge(
      :start_date => (date_range.last + 1.day).iso8601
    ).merge(view: current_view))
  end

  def url_for_today_view
    url_for(permitted_params.merge(:start_date => Time.current.to_date.iso8601).merge(view: current_view))
  end
end
