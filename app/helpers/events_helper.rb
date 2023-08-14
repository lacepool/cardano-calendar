module EventsHelper
  def epoch_description(epoch)
    "#{l(epoch.start_time, format: :short)} – #{l(epoch.end_time, format: :short)}, Slots: #{epoch.start_slot} – #{epoch.end_slot}"
  end

  def meetup_event_filters
    Events::Meetup::GROUPS.map do |name, url_name|
      if @filter[url_name] == "on"
        path = events_path(permitted_params.merge(filter: permitted_params.fetch(:filter, {}).except(url_name)))
        link_css = "active bg-secondary border-secondary"
        icon_state = "on"
      else
        path = events_path(permitted_params.deep_merge(filter: {url_name => "on"}))
        icon_state = "off"
      end

      link_to path, class: "list-group-item list-group-item-action" do
        tag.i(class: "bi-toggle-#{icon_state} me-2") + name
      end
    end.join.html_safe
  end

  def simple_event_filters
    Events::SimpleEvent.filters.map do |f|
      if f["default_value"] == "off"
        if @filter[f["param"]] == "on"
          path = events_path(permitted_params.merge(filter: permitted_params.fetch(:filter, {}).except(f["param"])))
          link_css = "active bg-secondary border-secondary"
          icon_state = "on"
        else
          path = events_path(permitted_params.deep_merge(filter: {f["param"] => "on"}))
          icon_state = "off"
        end
      else
        if @filter[f["param"]] == "off"
          path = events_path(permitted_params.merge(filter: permitted_params.fetch(:filter, {}).except(f["param"])))
          icon_state = "off"
        else
          path = events_path(permitted_params.deep_merge(filter: {f["param"] => "off"}))
          icon_state = "on"
        end
      end

      link_to path, class: "list-group-item list-group-item-action" do
        tag.i(class: "bi-toggle-#{icon_state} me-2") + f["name"]
      end
    end.join.html_safe
  end

  def views
    ["month", "week", "list"]
  end

  def current_view
    params.fetch(:view, "month")
  end

  def current_view_icon_class
    if list_view?
      css_class = "bi-#{current_view}"
    else
      css_class = "bi-calendar-#{current_view}"
    end
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
    url_for(
      permitted_params.merge(
        :start_date => Time.current.to_date.iso8601,
        view: current_view,
        anchor: "today"
      )
    )
  end
end
