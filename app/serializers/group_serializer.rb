# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class GroupSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name,
            :status,
            :notes,
            :user_id,
            :code,
            :created_at,
            :updated_at

  has_many :documents, serializer: DocumentSerializer

  attribute :document_owner do |object|
    object.last_document&.owner || 'N/A'
  end

  attribute :document_version_number do |object|
    object.last_document&.version_number || 0
  end

  attribute :last_document_url do |object|
    if object.last_document&.hashid
      Rails.application.routes.url_helpers.rails_blob_url(object.last_document&.file, disposition: "attachment")
    end
  rescue URI::InvalidURIError
    nil
  end
end 