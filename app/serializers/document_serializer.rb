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

  # Attribute to return file information
  attribute :file_info do |object|
    # Prioritize signed_pdf
    if object.signed_pdf.attached?
      generate_file_info(object.signed_pdf)
    # Next, check for a converted file if it exists
    elsif object.respond_to?(:converted_file) && object.converted_file.attached?
      generate_file_info(object.converted_file)
    # Lastly, fall back to the regular file
    elsif object.file.attached?
      generate_file_info(object.file)
    else
      nil
    end
  rescue URI::InvalidURIError
    nil
  end

  # Helper method to generate file information (URL and filename)
  def self.generate_file_info(attachment)
    {
      url: Rails.application.routes.url_helpers.rails_blob_url(attachment, disposition: "attachment"),
      name: attachment.filename.to_s
    }
  end
end