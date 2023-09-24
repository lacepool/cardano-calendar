require 'sidekiq/web'

Rails.application.routes.draw do
  get "/", to: redirect("/month")

  get "/:view", to: "events#index", as: :events
  get "/ical", to: "events#index", as: :ical, defaults: { format: 'ics' }
  get "/events/:name/:id", to: "events#show", as: :event

  resources :wallets, only: [:create]

  namespace :admin do
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["ADMIN_USERNAME"])) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["ADMIN_PASSWORD"]))
    end

    mount Sidekiq::Web, at: '/sidekiq'
  end
end
