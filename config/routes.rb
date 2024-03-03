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

    # Contact management
    resources :contacts, only: [:show, :update]

    # Project management
    resources :projects, only: [:index, :show, :create, :update, :destroy] do
      # Nested directory management within projects
      resources :directories, only: [:create, :update, :destroy]

      # Project-specific routes
      get :folder, on: :member
      get :tags, on: :member
      get :export, on: :member
      post :create_project_user, on: :member
      post :create_project_contact, on: :member
      get :check_admin, on: :member
    end

    # Project search
    get :search, to: "projects#search"

    # Directory file management
    resources :directory_files, except: [:new, :edit] do
      # Custom actions for directory_files
      collection do
        post :upload
      end

      member do
        get :analyze
        get :download
      end
    end

    # Project contacts and users
    resources :project_contacts, only: [:index, :update, :destroy]
    resources :project_users, only: [:index, :update, :destroy]
  end
end