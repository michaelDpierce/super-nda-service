# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class GroupsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name,
            :status,
            :notes,
            :user_id,
            :code,
            :created_at,
            :updated_at

  attribute :document_id do |object|
    object.last_document&.hashid
  end

  attribute :version_number do |object|
    object.last_document&.version_number || 0
  end

  attribute :current_owner do |object|
    object.last_document&.owner
  end

  attribute :last_interaction do |object|
    object.last_document&.created_at
  end
end 