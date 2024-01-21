# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class PinnedProjectsSerializer < ApplicationSerializer

  set_id :hashid
  set_type :project

  attribute :name, :description, :primary_color

  attribute :logo do |object|
    puts object.logo
    Rails.application.routes.url_helpers.rails_blob_url(object.logo) if object.logo.attached?
  rescue URI::InvalidURIError
    nil
  end
end 


