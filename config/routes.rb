# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

Rails.application.routes.draw do
  root 'home#welcome'

  namespace :v1, defaults: { format: :json } do
    resources :auth, only: :create

    resources :projects, only: %i[index show create update destroy]
    
    get 'search', to: 'projects#search'
  end
end
