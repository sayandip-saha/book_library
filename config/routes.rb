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

  root "books#index"
end