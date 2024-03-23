# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class SharingSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name

  attribute :last_document do |object|
    last_document = object.last_document

    if last_document
      file           = last_document.file
      filename       = file.filename.to_s
      owner          = last_document.owner
      version_number = last_document.version_number

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
        filename: filename,
        owner: owner,
        version_number: version_number
      }
    end
  rescue URI::InvalidURIError
    nil
  end
end