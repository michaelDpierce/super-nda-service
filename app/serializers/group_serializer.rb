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
            :updated_at,
            :job_id,
            :job_status

  has_many :documents, serializer: DocumentSerializer

  attribute :document_owner do |object|
    object.last_document&.owner || 'N/A'
  end

  attribute :document_version_number do |object|
    object.last_document&.version_number || 0
  end

  attribute :party_date do |object|
    object.last_document&.party_date
  end

  attribute :counter_party_date do |object|
    object.last_document&.counter_party_date
  end

  attribute :url do |object|    
    generate_blob_url_for(object&.last_document&.file)
  end

  attribute :has_signature do |object, params|
    params[:has_signature]
  end

  attribute :logo_url do |object|
    if object.project.logo.attached?
      Rails.application.routes.url_helpers.rails_blob_url(object.project.logo)
    end
  rescue URI::InvalidURIError
    '/super-nda-logo.png'
  end

  private

  def self.generate_blob_url_for(attachment)
    return unless attachment&.attached?

    begin
      Rails.application.routes.url_helpers.rails_blob_url(attachment, disposition: "attachment")
    rescue URI::InvalidURIError
      nil
    end
  end
end 
