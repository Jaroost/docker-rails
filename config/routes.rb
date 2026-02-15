Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Devise authentication routes with Keycloak OAuth
  # Skip sessions routes since we're OAuth-only (no password authentication)
  devise_for :users, 
    skip: [ :sessions ],
    controllers: {
      omniauth_callbacks: "users/omniauth_callbacks"
    }

  # Custom session routes for OAuth-only authentication
  devise_scope :user do
    delete "/users/sign_out", to: "users/sessions#destroy", as: :destroy_user_session
    get "/signup", to: "users/sessions#signup"
  end

  # API routes (JWT authentication)
  namespace :api do
    namespace :v1 do
      resources :users, only: [] do
        collection do
          get :me
        end
      end
    end
  end

  # ArticlesRequest resources
  resources :articles_requests

  root "home#test"
end
