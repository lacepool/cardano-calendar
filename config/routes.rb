Rails.application.routes.draw do
  get "/", to: redirect("/month")
  get "/(:view)", to: "events#index", as: :events
end
