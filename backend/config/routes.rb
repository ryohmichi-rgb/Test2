Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      resources :grades, only: [:index, :show]
      resources :units, only: [:show]
      resources :students, only: [:create, :show] do
        get :progress, on: :member
      end
      resources :answer_records, only: [:create]
    end
  end
end
