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

  def event_views
    ["month", "week", "list"]
  end

  def event_view_icon(view)
    view == "list" ? "bi-list-ul" : "bi-calendar-#{view}"
  end

  def render_event_view_switches
    default_classes = "event_view list-group-item list-group-item-action"
    active_classes = "active bg-secondary border-secondary"

    event_views.map do |view|
      classes = current_view == view ? [default_classes, active_classes].join(" ") : default_classes

      link_to events_path(permitted_params.merge(view: view)), class: classes, data: { view: view } do
        tag.i(nil, class: "#{event_view_icon(view)} me-1") + view.upcase_first
      end
    end.join.html_safe
  end

  def render_event_filters
    EventFilterRegistry.registered.map do |category, filters|
      html_id = category.parameterize

      links = filters.map do |filter_param, filter|
        dataset = {
          "events-target": "filter",
          "filter-param": filter_param,
          "filter-default": filter[:default]
        }
        checked = event_param_filters.is_on?(filter_param)
        checkbox_name = "filter_#{filter_param}"

        tag.div data: dataset, class: "event_filter form-switch list-group-item" do
          check_box_tag(checkbox_name, nil, checked, class: "form-check-input me-2 float-none", role: "switch") +
            tag.label(filter[:label], class: "form-check-label small", for: checkbox_name)
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

  def current_view
    params.fetch(:view, "month")
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
