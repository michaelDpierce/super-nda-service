# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class SharingSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name

  attribute :current_nda_url do |object|
    last_document = object.documents.last

    if last_document
      file     = last_document.file
      filename = file.filename.to_s

      url = if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(
          file,
          disposition: "attachment",
          host: "#{ENV["SERVER_PROTOCOL"]}://#{ENV["SERVER_HOST"]}",
        )
      else
        file.url(disposition: "attachment", expires_in: 15.minutes)
      end

      {
        url: url,
        name: filename
      }
    end
  rescue URI::InvalidURIError
    nil
  end
end 
