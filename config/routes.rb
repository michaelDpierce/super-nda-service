
# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

require "sidekiq/web"

# Sidekiq web interface configuration
Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_mb_session"

Rails.application.routes.draw do
  # Root route
  root "home#welcome"

  # Sidekiq web interface route
  mount Sidekiq::Web => "/sidekiq"

  # API versioning
  namespace :v1, defaults: { format: :json } do
    # Authentication
    resources :auth, only: [:create]

    # Project management
    resources :projects, only: [:index, :show, :create, :update, :destroy] do
      # Project-specific routes
      get :export_groups, on: :member
      post :create_project_user, on: :member
      post :create_groups, on: :member
      get :groups, on: :member
      get :stats, on: :member
    end

    # Project search
    get :search, to: "projects#search"

    # Project users
    resources :project_users, only: [:index, :update, :destroy]

    # Groups
    resources :groups, only: [:show, :create, :update, :destroy] do
      post :upload,       on: :member
      post :change_owner, on: :member
      get  :sign,         on: :member
    end

    # Settings
    get '/settings',        to: 'settings#show'
    put '/settings',        to: 'settings#update'

    # Share Links
    post '/verify_code',      to: 'sharing#verify_code'
    post '/upload',           to: 'sharing#upload'
    post '/reclaim',          to: 'sharing#reclaim'
    post '/signing',          to: 'sharing#signing'
    post '/sign',             to: 'sharing#sign'
    post '/create_analytic' , to: 'sharing#create_analytic'

    post '/verify_project_code', to: 'sharing#verify_project_code'
    post '/create_group',        to: 'sharing#create_group'
  end
end