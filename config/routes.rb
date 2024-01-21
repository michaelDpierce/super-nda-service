# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

Rails.application.routes.draw do
  root 'home#welcome'

  namespace :v1, defaults: { format: :json } do
    resources :auth, only: :create

    resources :projects, only: %i[index show create update destroy]
    get :search, to: 'projects#search'
    get :pinned_projects, to: 'projects#pinned'

    resources :project_users, only: %i[index create update destroy] do
      put :pinned, to: 'project_users#toggle_pinned', on: :member
    end
  end
end
