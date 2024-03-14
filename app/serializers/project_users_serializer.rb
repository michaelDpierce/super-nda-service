# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectUsersSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project_user

  attribute :access,
            :admin,
            :last_viewed_at,
            :created_at,
            :updated_at


  attribute :logo do |object|
    if object.logo.attached?
      {
        url: Rails.application.routes.url_helpers.rails_blob_url(object.logo),
        name: object.logo.filename.to_s
      }
    end
  rescue URI::InvalidURIError
    nil
  end

  attribute :user_id do |object|
    object.user.hashid
  end

  attribute :email do |object|
    object.user.email
  end
  
  attribute :first_name do |object|
    object.user.first_name || "-"
  end

  attribute :last_name do |object|
    object.user.last_name || "-"
  end

  attribute :last_login do |object|
    object.user.last_login
  end

  attribute :created_account do |object|
    object.user.source_id ? true : false
  end
end