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

  attribute :user_id do |object|
    object.user.hashid
  end

  attribute :email do |object|
    object.user.email
  end

  attribute :domain do |object|
    object.user.domain
  end
  
  attribute :first_name do |object|
    object.user.first_name || "-"
  end

  attribute :last_name do |object|
    object.user.last_name || "-"
  end

  attribute :title do |object|
    object.user.title || "-"
  end

  attribute :last_login do |object|
    object.user.last_login
  end

  attribute :created_account do |object|
    object.user.source_id ? true : false
  end
end