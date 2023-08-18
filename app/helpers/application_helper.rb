module ApplicationHelper
  def current_timezone
    @current_timezone ||= Time.zone.tzinfo.identifier
  end
end
