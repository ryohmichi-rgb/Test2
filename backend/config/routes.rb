Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :api do
    namespace :v1 do
      post "signup", to: "auth#signup"
      post "login", to: "auth#login"
      get "me", to: "auth#me"

      resources :grades, only: [:index, :show]
      resources :units, only: [:show]
      resources :students, only: [:show] do
        get :progress, on: :member
        get :stats, on: :member, to: "stats#index"
        get :plan, on: :member, to: "plan#show"
        put :goals, to: "goals#upsert", on: :member
        get :test_results, on: :member, to: "test_results#index"
        post :test_results, on: :member, to: "test_results#create"
        get :growth, on: :member, to: "growth#show"
        get :review, on: :member, to: "review#index"
        get :quota, on: :member, to: "quota#show"
      end
      resources :answer_records, only: [:create]
      resources :reference_stats, only: [:index]
      resource :problem_set, only: [:show], controller: "problem_sets"
    end
  end
end
