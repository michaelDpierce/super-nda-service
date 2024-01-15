# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class DashboardSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description, :primary_color

  attribute :logo do |object|
    object.logo.blob.url if object.logo.attached?
  rescue URI::InvalidURIError
    nil
  end

  attribute :cover do |object|
    object.cover.blob.url if object.cover.attached?
  rescue URI::InvalidURIError
    nil
  end
end 
