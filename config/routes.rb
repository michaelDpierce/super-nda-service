# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================
require "sidekiq/web"

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: "_mb_session"

Rails.application.routes.draw do
  root "home#welcome"

  mount Sidekiq::Web => "/sidekiq"

  namespace :v1, defaults: { format: :json } do
    resources :auth, only: :create

    resources :projects, only: %i[index show create update destroy] do
      resources :directories, only: %i[create update destroy]
    end

    resources :directory_files
    match "/upload", to: "directory_files#upload", via: "post"
    match "/directory_files/:id/analyze", to: "directory_files#analyze", via: "get"
    match "/directory_files/:id/download", to: "directory_files#download", via: "get"

    get :pinned_projects, to: "projects#pinned"
    get :search, to: "projects#search"
    
    match "/projects/:id/folder", to: "projects#folder", via: "get"
    match "/projects/:id/tags", to: "projects#tags", via: "get"
    match "/projects/:id/export", to: "projects#export", via: "get"
    match "/projects/:id/create_project_user", to: "projects#create_project_user", via: "post"
    match "/projects/:id/check_admin", to: "projects#check_admin", via: "get"

    resources :project_users, only: %i[index create update destroy] do
      put :pinned, to: "project_users#toggle_pinned", on: :member
    end
  end
end