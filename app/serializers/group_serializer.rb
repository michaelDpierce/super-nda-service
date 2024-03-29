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

  attribute :party_date do |object|
    object.last_document&.party_date
  end

  attribute :counter_party_date do |object|
    object.last_document&.counter_party_date
  end

  attribute :files do |object|
    last_document = object.last_document
    
    {
      docx_url: generate_blob_url_for(last_document&.file),
      pdf_url: generate_blob_url_for(last_document&.converted_file),
      signed_pdf_url: generate_blob_url_for(last_document&.signed_pdf)
    }
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
