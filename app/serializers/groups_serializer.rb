# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class GroupsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name,
            :status,
            :pretty_status,
            :notes,
            :user_id,
            :progress,
            :code,
            :created_at,
            :updated_at

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