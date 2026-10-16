Rails.application.routes.draw do
  get "users/new"
  resource :session
  resources :passwords, param: :token
  resources :books
  resources :authors, only: [:index, :new, :create, :destroy]
  resources :categories, only: [:index, :new, :create, :destroy]
  resources :users, only: %i[new create]

  root "books#index"
end