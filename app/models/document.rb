# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Document < ApplicationRecord
  include Hashid::Rails
  hashid_config min_hash_length: 16

  before_validation :set_version_number, on: :create
  after_commit :run_project_stats_job
  after_create :update_group_last_document

  belongs_to :group
  belongs_to :project

  has_one_attached :file, dependent: :destroy_async # DOCX
  has_one_attached :converted_file, dependent: :destroy_async # PDF

  # Party signatured is saved on each users profile
  has_one_attached :counter_party_signature, dependent: :destroy_async #PNG
  
  has_one_attached :signed_pdf, dependent: :destroy_async

  enum owner: {
    party: 0,
    counter_party: 1
  }

  def generate_sanitized_filename
    ext   = self.project.template.filename.extension_with_delimiter
    group = self.group.name

    filename =
      "#{project.name}_#{group}_NDA_V#{version_number}#{ext}"

    sanitize_filename(filename)
  end

  def generate_reclaimed_filename(last_document_id)
    last_document = Document.find_by(id: last_document_id)
    
    return "default_filename.ext" unless last_document&.file&.attached?
    
    ext        = last_document.file.filename.extension_with_delimiter
    group_name = self.group.name
    filename   = "#{self.project.name}_#{group_name}_NDA_V#{version_number}#{ext}"

    sanitize_filename(filename)
  end

  private

  def set_version_number
    last_version = self.group.documents.maximum(:version_number) || 0
    self.version_number = last_version + 1
  end

  def run_project_stats_job
    ProjectStatsJob.perform_async(group.project_id)
  end

  def update_group_last_document
    group.update(last_document_id: id)
  end

  def sanitize_filename(filename)
    filename.gsub(/[^a-zA-Z0-9\-_.]/, '_')
  end
end