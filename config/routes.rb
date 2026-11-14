Rails.application.routes.draw do
  root "home#index"
  get "ui_kit", to: "home#ui_kit"
  get "account", to: "account#show", as: :account
  get "account/appointments",
      to: "account#appointments",
      as: :account_appointments
  resources :psychologists, only: [ :index, :show ] do
    resources :comments, only: %i[create edit update destroy]
  end
  resources :appointments, only: %i[create update destroy]
  resources :psychologist_applications, only: [ :new, :create ]
  resources :slots, only: %i[index create edit update destroy]

  namespace :admin do
    resources :psychologist_applications, only: [ :index, :update ]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  # Проверка работоспособности приложения
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Новые маршруты /auth/register и /auth/login
  namespace :auth do
    get "register", to: "registrations#new"      # Показывает форму регистрации
    post "register", to: "registrations#create"  # Обрабатывает отправку формы

    get "login", to: "sessions#new"              # Показывает форму входа
    post "login", to: "sessions#create"          # Обрабатывает вход
    delete "logout", to: "sessions#destroy"      # Обрабатывает выход
  end

  if Rails.env.development?
    mount LetterOpenerWeb::Engine, at: "/letter_opener"
  end
end
