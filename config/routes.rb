Rails.application.routes.draw do
  namespace :api do
    namespace :v1 do
      concern :blogable do
        resources :blogs, shallow: true do
          resources :comments, shallow: true do
            
          end
        end
      end
      resources :users, :tags, :categories, concerns: :blogable
      devise_for :users, controllers: {
        sessions: 'api/v1/sessions',
        registrations: 'api/v1/registrations'
      }
    end
  end

  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  # root "posts#index"
end
