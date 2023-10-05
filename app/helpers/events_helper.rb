module EventsHelper
  def tags(event)
    event.tags.map do |tag_name|
      tag.span tag_name, class: "badge text-bg-info"
    end.join.html_safe
  end

  def epoch_description(epoch, time_range: false, slot: true)
    time = [l(epoch.start_time, format: :short)]
    time << l(epoch.end_time, format: :short) if time_range

    desc = [tag.time(time.join(" – "))]
    desc << tag.p("Slot #{epoch.start_slot}", class: "slot") if slot
    desc << epoch_progress_bar(epoch) unless epoch.future?

    desc.join("")
  end

  def epoch_progress_bar(epoch)
    tag.div(class: "progress mt-3", role: "progressbar", aria: { label: "Epoch Progress", valuemin: "0", valuemax: "100" }) do
      tag.div(class: "progress-bar", style: "width: #{epoch.progress}%") do
        number_to_percentage(epoch.progress, precision: 0)
      end
    end
  end

  def current_epoch_border_gradient(progress)
    colors = [
      "var(--bs-primary) #{progress}%",
      "var(--bs-border-color) #{100-progress}%"
    ].join(',')

    "border-color: unset !important; border-image: linear-gradient(180deg, #{colors}) 1"
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

      link_to events_path(event_params.merge(view: view)), class: classes, data: { action: "click->filters#toggleView", "filters-view-value": view } do
        tag.i(nil, class: "#{event_view_icon(view)} me-1") + view.upcase_first
      end
    end.join.html_safe
  end

  def filter_badge(filter_class, filter_param)
    unless Object.const_defined?(filter_class)
      # todo: implement error tracking
      return nil
    end

    klass = filter_class.constantize

    if klass.respond_to?(:count_by_filter)
      args = [filter_param, date_range]
      args.prepend(current_stake_address) if filter_class == "Events::Wallet"

      count = klass.count_by_filter(*args)

      bg_color = count > 0 ? "bg-success" : "bg-secondary"
      css_classes = "badge position-absolute top-50 end-0 translate-middle rounded-pill #{bg_color}"

      tag.span(count, class: css_classes)
    end
  end

  def render_event_filters
    EventFilterRegistry.registered.sort.to_h.map do |category, filters|
      html_id = category.parameterize

      links = filters.map do |filter_param, filter|
        dataset = {
          "action": "change->filters#toggleFilter",
          "filter-param": filter_param,
          "filter-default": filter[:default]
        }
        checked = event_param_filters.is_on?(filter_param)
        checkbox_name = "filter_#{filter_param}"

        url = event_count_path(
          view: current_view,
          start_date: current_start_date,
          filter_class: filter[:class],
          filter_param: filter_param,
          stake_address: current_stake_address
        )

        frame_id = "#{filter[:class].parameterize}-#{filter_param}"

        badge = turbo_frame_tag(frame_id, class: "turboFrameFilter", loading: "lazy", src: url) do
          tag.div class: "filter_spinner_container position-absolute top-50 end-0 translate-middle" do
            tag.div class: "spinner-border spinner-border-sm", role: "status"
          end
        end

        tag.div class: "event_filter form-switch list-group-item" do
          check_box_tag(checkbox_name, nil, checked, data: dataset, class: "form-check-input me-2 float-none", role: "switch") +
            tag.label(filter[:label], class: "form-check-label small", for: checkbox_name) + badge
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

  def filters
    @filters ||= EventParamFilters.new(params.fetch(:filter, {}))
  end
  alias_method :event_param_filters, :filters

  def wallet_connected?
    @wallet_connected ||= params[:stake_address] && Wallet.where(stake_address: params[:stake_address]).exists?
  end

  def current_view
    event_params.fetch(:view, "month")
  end

  def current_stake_address
    params.fetch(:stake_address, nil)
  end

  def filter_params
    event_params.fetch(:filter, {}).merge(
      stake_address: event_params[:stake_address])
  end

  def current_start_date
    current_start_time.to_date
  end

  def current_start_time
    event_params.fetch(:start_date, Time.current).to_time
  end

  def date_range
    current_view == "week" ? week_date_range : month_date_range
  end

  def week_date_range
    current_start_time.beginning_of_week..current_start_time.end_of_week
  end

  def month_date_range
    current_start_time.beginning_of_month..current_start_time.end_of_month
  end

  # direction can either be :+ or :- for prev/next
  def start_time(direction=nil)
    return DateTime.current.in_time_zone unless direction

    if current_view == "week"
      date_range.first.public_send(direction, 1.week)
    else
      date_range.first.public_send(direction, 1.month)
    end
  end

  def start_date(direction=nil)
    start_time(direction).to_date
  end

  def url_for_previous_view
    url_for(event_params.merge(
      start_date: start_date(:-).iso8601
    ).merge(view: current_view))
  end

   def url_for_next_view
    url_for(event_params.merge(
      start_date: start_date(:+).iso8601
    ).merge(view: current_view))
  end

  def url_for_today_view
    url_for(
      event_params.merge(
        start_date: start_date.iso8601,
        view: current_view,
        anchor: start_date.iso8601
      )
    )
  end

  def ics_date_range
    Time.at(Epoch::SHELLY_UNIX).utc..(Time.current.utc + 6.months)
  end
end
