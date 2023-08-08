module ApplicationHelper
  def current_tz
    params.fetch(:tz, "UTC")
  end
end
