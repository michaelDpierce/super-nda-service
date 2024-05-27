class SharingSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name, :code, :status

  attribute :logo_url do |object|
    if object.project.logo.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.project.logo)
    else
      '/super-nda-logo.png'
    end
  rescue URI::InvalidURIError
    '/super-nda-logo.png'
  end
    
  attribute :last_document do |object|
    last_document = object.last_document

    if last_document
      id = last_document.hashid
      owner = last_document.owner
      version_number = last_document.version_number
      party_date = last_document.party_date
      counter_party_date = last_document.counter_party_date

      file = last_document.file if last_document.respond_to?(:file)
      filename = nil
      url = nil

      if file&.attached?
        filename = file.filename.to_s

        expires_in = 15.minutes
        host = "#{ENV['SERVER_PROTOCOL']}://#{ENV['SERVER_HOST']}"

        # Determining URL based on environment
        url = if Rails.env.development?
                Rails.application.routes.url_helpers.rails_blob_url(file, disposition: 'attachment', host: host)
              else
                file.url(disposition: 'attachment', expires_in: expires_in)
              end
      end

      {
        id: id,
        owner: owner,
        version_number: version_number,
        url: url,
        filename: filename,
        party_date: party_date,
        counter_party_date: counter_party_date
      }
    end
  rescue URI::InvalidURIError
    nil
  end
end