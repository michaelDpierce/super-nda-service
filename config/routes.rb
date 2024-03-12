
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
      get :export, on: :member
      post :create_project_user, on: :member
      post :create_groups, on: :member
      get :groups, on: :member
      get :check_admin, on: :member
    end

    # Project search
    get :search, to: "projects#search"

    # Project users
    resources :project_users, only: [:index, :update, :destroy]

    # Groups
    resources :groups, only: [:create, :update, :destroy]
  end
end