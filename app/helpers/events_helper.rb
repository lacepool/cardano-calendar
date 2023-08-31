module EventsHelper
  def epoch_description(epoch)
    "#{l(epoch.start_time, format: :short)} – #{l(epoch.end_time, format: :short)}, Slots: #{epoch.start_slot} – #{epoch.end_slot}"
  end

  def event_time(event)
    if event.momentary? || event.open_end?
      l(event.start_time.to_time, format: event.time_format&.to_sym || :short)
    elsif event.one_day?
      "#{l(event.start_time.to_time, format: :short)} – #{l(event.end_time.to_time, format: :time)}"
    else
      "#{l(event.start_time.to_time, format: event.time_format&.to_sym || :short)} – #{l(event.end_time.to_time, format: event.time_format&.to_sym || :short)}"
    end
  end

  def current_filters
    @current_filters ||= permitted_params.fetch(:filter, {})
  end

  def render_event_filters
    EventFilterRegistry.registered.map do |category, filters|
      html_id = category.parameterize

      links = filters.map do |filter_param, filter|
        if event_param_filters.is_on?(filter_param)
          icon_state = "on"

          if filter[:default] == "off"
            updated_params = permitted_params.merge(filter: current_filters.except(filter_param))
          else
            updated_params = permitted_params.deep_merge(filter: {filter_param => "off"})
          end
        else
          icon_state = "off"

          if filter[:default] == "off"
            updated_params = permitted_params.deep_merge(filter: {filter_param => "on"})
          else
            updated_params = permitted_params.merge(filter: current_filters.except(filter_param))
          end
        end

        link_to events_path(updated_params), class: "list-group-item list-group-item" do
          tag.i(class: "bi-toggle-#{icon_state} me-2") + tag.span(filter[:label], class: "small")
        end
      end.join.html_safe

      tag.div class: "accordion-item" do
        filter_accordion_heading(category, html_id) + filter_accordion_body(links, html_id)
      end
    end.join.html_safe
  end

  def filter_list(links)
    tag.ul class: "list-group list-group-flush mb-4" do
      links
    end
  end

  def filter_accordion_heading(title, html_id)
    tag.h2 class: "accordion-header", id: "heading_#{html_id}" do
      tag.button class: "accordion-button collapsed", type: "button", data: { "bs-toggle" => "collapse", "bs-target" => "##{html_id}" }, "aria-expanded" => "false", "aria-controls" => html_id do
        title
      end
    end
  end

  def filter_accordion_body(links, html_id)
    tag.div id: html_id, class: "accordion-collapse collapse", "aria-labelledby" => "heading_#{html_id}", "data-bs-parent" => "#event_filter" do
      tag.div class: "accordion-body p-0" do
        filter_list(links)
      end
    end
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
