# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class DocumentSerializer < ApplicationSerializer
  set_id :hashid
  set_type :document

  attribute :owner,
            :version_number,
            :created_at,
            :updated_at

  attribute :file do |object|
    if object.file.attached?
      {
        url: Rails.application.routes.url_helpers.rails_blob_url(object.file, disposition: "attachment"),
        name: object.file.filename.to_s
      }
    end
  rescue URI::InvalidURIError
    nil
  end

  attribute :signed_pdf_url do |object|
    if object.signed_pdf.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.signed_pdf, disposition: "attachment")
    end
  rescue URI::InvalidURIError
    nil
  end
end 