require 'sidekiq/web'

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "health#show"

  get "/", to: redirect("/list")

  get "/:view", to: "events#index", as: :events
  get "/events/:name/:id", to: "events#show", as: :event

  get "/events/count", to: "events#count", as: :event_count
  get "/events/filters", to: "events#filters", as: :event_filters

  resources :wallets, only: [:create]

  namespace :admin do
    Sidekiq::Web.use Rack::Auth::Basic do |username, password|
      ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(username), ::Digest::SHA256.hexdigest(ENV["ADMIN_USERNAME"])) &
        ActiveSupport::SecurityUtils.secure_compare(::Digest::SHA256.hexdigest(password), ::Digest::SHA256.hexdigest(ENV["ADMIN_PASSWORD"]))
    end

    mount Sidekiq::Web, at: '/sidekiq'
  end
end
