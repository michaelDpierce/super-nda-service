# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description, :status, :action, :start_date, :end_date

  attribute :user do |object|
    {
      id: object.user.hashid,
      full_name: object.user.full_name,
      email: object.user.email
    }
  end

  attribute :logo do |object|
    Rails.application.routes.url_helpers.rails_blob_url(object.logo) if object.logo.attached?
  rescue URI::InvalidURIError
    nil
  end
end 
