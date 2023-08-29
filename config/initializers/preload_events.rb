events = "#{Rails.root}/app/models/events"

Rails.application.config.to_prepare do
  Rails.autoloaders.main.eager_load_dir(events)
end
