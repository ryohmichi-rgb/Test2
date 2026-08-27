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
        post :complete_onboarding, on: :member
        get :stats, on: :member, to: "stats#index"
        get :plan, on: :member, to: "plan#show"
        put :goals, to: "goals#upsert", on: :member
        get :test_results, on: :member, to: "test_results#index"
        post :test_results, on: :member, to: "test_results#create"
        get :growth, on: :member, to: "growth#show"
        get :review, on: :member, to: "review#index"
        get :quota, on: :member, to: "quota#show"
        get :lesson_reads, on: :member, to: "lesson_reads#index"
        post :lesson_reads, on: :member, to: "lesson_reads#create"
        get :daily_problem, on: :member, to: "daily_problems#show"
        get :achievements, on: :member, to: "achievements#index"
        get :condition, on: :member, to: "condition#show"
        get :ai_usage, on: :member, to: "ai_teacher#usage"
        post :ask_teacher, on: :member, to: "ai_teacher#ask"
        # 「この人に聞く」（職業ペルソナへの相談）。先生とは回数の枠を分けている
        get :persona_usage, on: :member, to: "personas#usage"
        post :ask_persona, on: :member, to: "personas#ask"
        put :password, on: :member, to: "passwords#update"
        get :rank, on: :member, to: "promotion_exams#status"
        get :promotion_exam, on: :member, to: "promotion_exams#show"
        post :promotion_exam, on: :member, to: "promotion_exams#create"
        put :title, on: :member, to: "titles#update"
      end
      # 保護者が見られる子どもの一覧（学習状況そのものは /students/:id/* を使う）
      resources :children, only: [:index]
      resources :answer_records, only: [:create]
      resources :reference_stats, only: [:index]
      resource :problem_set, only: [:show], controller: "problem_sets"

      namespace :admin do
        get "meta", to: "meta#show"
        resources :subjects, only: [:index, :create, :update, :destroy]
        resources :units, only: [:index, :create, :update, :destroy]
        resources :problems, only: [:index, :create, :update, :destroy]
        resources :reference_stats, only: [:index, :create, :update, :destroy]
        resources :students, only: [:index, :show, :create, :destroy] do
          post :reset_password, on: :member
          # 保護者（:id）と子どもの紐づけ
          post   "guardianships",             on: :member, to: "students#create_guardianship"
          delete "guardianships/:student_id", on: :member, to: "students#destroy_guardianship"
        end
      end
    end
  end
end
