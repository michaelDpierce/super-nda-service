# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description

  attribute :permissions do |_, params|
    params[:permissions]
  end

  attribute :meta do |_, params|
    params[:meta]
  end

  attribute :documents do |_, params|
    if params[:documents].present?      
      params[:documents].map do |document|
        url = Rails.application.routes.url_helpers.rails_blob_url(document)

        {
          id: document.id,
          name: document.filename.to_s,
          content_type: document.content_type,
          url: url
        }
      end
    else
      []
    end
  end
end 