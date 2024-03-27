# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class SharingSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name, :code, :status

  attribute :last_document do |object|
    last_document = object.last_document

    if last_document
      id = last_document.hashid
      owner = last_document.owner
      version_number = last_document.version_number

      file = last_document.file
      filename = file.filename.to_s

      expires_in = 15.minutes
      host = "#{ENV['SERVER_PROTOCOL']}://#{ENV['SERVER_HOST']}"

      url = if Rails.env.development?
              Rails.application.routes.url_helpers.rails_blob_url(file, disposition: 'attachment', host: host)
            else
              file.url(disposition: 'attachment', expires_in: expires_in)
            end

      document_hash = {
        id: id,
        owner: owner,
        version_number: version_number,
        url: url,
        filename: filename,
        party_date: last_document.party_date,
        counter_party_date: last_document.counter_party_date
      }

      # Only add converted file details if a converted file exists
      if last_document.converted_file.present?
        converted_file = last_document.converted_file
        converted_filename = converted_file.filename.to_s

        converted_url = if Rails.env.development?
                          Rails.application.routes.url_helpers.rails_blob_url(converted_file, disposition: 'attachment', host: host)
                        else
                          converted_file.url(disposition: 'attachment', expires_in: expires_in)
                        end

        document_hash.merge!(
          converted_url: converted_url,
          converted_filename: converted_filename
        )
      end

      document_hash
    end
  rescue URI::InvalidURIError
    nil
  end
end