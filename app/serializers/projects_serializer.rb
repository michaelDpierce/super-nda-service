# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description

  attribute :cover do |object|
    object.cover.blob.url if object.cover.attached?
  rescue URI::InvalidURIError
    nil
  end

  attribute :cover do |object|
    object.cover.blob.url if object.cover.attached?
  rescue URI::InvalidURIError
    nil
  end
end 
