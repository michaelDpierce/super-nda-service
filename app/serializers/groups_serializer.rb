# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class GroupsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name, :status, :notes, :created_at, :updated_at, :user_id, :progress, :code

  attribute :project_id do |object|
    object.project.hashid
  end

  attribute :user do |object|
    {
      id: object.user.hashid,
      full_name: object.user.full_name,
      email: object.user.email
    }
  end
end 