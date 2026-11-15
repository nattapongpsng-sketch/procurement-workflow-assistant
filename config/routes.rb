Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  root "workflows#index"
  resources :workflows, only: %i[index show]

  resources :audit_events, only: :index

  namespace :admin do
    resources :users, only: %i[index new create edit update]
    resources :departments, only: %i[index new create edit update]
    resources :positions, only: %i[index new create edit update]
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  get "up" => "rails/health#show", as: :rails_health_check
end
