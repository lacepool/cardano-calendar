class ApplicationController < ActionController::Base
  around_action :set_time_zone

  private

  def set_time_zone(&block)
    session[:tz] = params[:tz] if params[:tz]
    Time.use_zone(session[:tz] || "Etc/UTC", &block)

  rescue ArgumentError => e
    flash[:warning] = "#{e} – Falling back to UTC"
    flash.discard(:warning)

    Time.use_zone("UTC", &block)
  end
end
