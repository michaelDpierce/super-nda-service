# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name,
            :description,
            :status,
            :start_date,
            :end_date,
            :code,
            :authorized_agent_of_signatory_user_id

  attribute :permissions do |_, params|
    params[:permissions]
  end

  attribute :meta do |_, params|
    params[:meta]
  end

  attribute :logo_url do |object|
    if object.logo.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.logo)
    else
      '/super-nda-logo.png'
    end
  rescue URI::InvalidURIError
    '/super-nda-logo.png'
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