# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
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
end 