Rails.application.routes.draw do
  resources :books
  resources :authors, only: [:index, :new, :create, :destroy]
  resources :categories, only: [:index, :new, :create, :destroy]

  root "books#index"
end