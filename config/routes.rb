Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"

  # Новые маршруты /auth/register и /auth/login
  namespace :auth do
    get 'register', to: 'registrations#new'      # Показывает форму регистрации
    post 'register', to: 'registrations#create'  # Обрабатывает отправку формы

    get 'login', to: 'sessions#new'              # Показывает форму входа
    post 'login', to: 'sessions#create'          # Обрабатывает вход
    delete 'logout', to: 'sessions#destroy'      # Обрабатывает выход
  end

  # Заглушка для главной страницы, чтобы было куда делать редирект после входа
  # Позже вы замените это на настоящий контроллер главной страницы
  root "application#index"
end
