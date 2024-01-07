# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

Rails.application.routes.draw do
  root 'home#welcome'

  namespace :v1, defaults: { format: :json } do
    resources :auth, only: :create
  end
end
