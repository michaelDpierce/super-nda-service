# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================
require 'sidekiq/web'

Sidekiq::Web.use ActionDispatch::Cookies
Sidekiq::Web.use ActionDispatch::Session::CookieStore, key: '_mb_session'

Rails.application.routes.draw do
  root 'home#welcome'

  mount Sidekiq::Web => '/sidekiq'

  namespace :v1, defaults: { format: :json } do
    resources :auth, only: :create

    resources :projects, only: %i[index show create update destroy] do
      resources :directories, only: %i[index create update destroy] do
        # resources :files, only: %i[update destroy]
      end
    end

    resources :directory_files
    match '/upload', to: 'directory_files#upload', via: 'post'

    get :pinned_projects, to: 'projects#pinned'
    get :search, to: 'projects#search'
    match '/projects/:id/folder', to: 'projects#folder', via: 'get'
    match '/projects/:id/remove_supporting_document/:document_id', to: 'projects#remove_supporting_document', via: 'delete'
    match '/projects/:id/tags', to: 'projects#tags', via: 'get'
    match '/projects/:id/export', to: 'projects#export', via: 'get'

    resources :project_users, only: %i[index create update destroy] do
      put :pinned, to: 'project_users#toggle_pinned', on: :member
    end
  end
end