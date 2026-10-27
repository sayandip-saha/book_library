Rails.application.routes.draw do
  resource :session
  resources :passwords, param: :token
  resources :books do
    collection do
      get :lookup
      post :import
    end
    member do
      patch :toggle_availability
    end
  end
  resources :authors, only: [:index, :new, :create, :destroy]
  resources :categories, only: [:index, :new, :create, :destroy]
  resources :users, only: %i[new create]

  namespace :admin do
    root "dashboard#index"
    post "sync_covers", to: "dashboard#sync_covers"
    resources :users, only: [:index, :create, :destroy] do
      member do
        patch :toggle_admin
      end
    end
  end

  get "admin", to: "admin/dashboard#index", as: :admin_dashboard

  root "books#index"
end