# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description, :status, :start_date, :end_date, :code

  attribute :permissions do |_, params|
    params[:permissions]
  end

  attribute :meta do |_, params|
    params[:meta]
  end

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

  attribute :template do |object|
    if object.template.attached?
      {
        url: Rails.application.routes.url_helpers.rails_blob_url(object.template),
        name: object.template.filename.to_s
      }
    end
  rescue URI::InvalidURIError
    nil
  end
end 