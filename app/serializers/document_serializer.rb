# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class DocumentSerializer < ApplicationSerializer
  set_id :hashid
  set_type :document

  attribute :owner,
            :version_number,
            :created_by,
            :created_at,
            :updated_at

  attribute :pretty_status do |object|
    object&.group_status_at_creation&.titleize || '-'
  end

  attribute :url do |object|
    if object.file.attached?
      generate_file_info(object.file)
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end

  # Helper method to generate file information (URL and filename)
  def self.generate_file_info(attachment)
    Rails.application.routes.url_helpers.rails_blob_url(attachment, disposition: "attachment")
  end
end