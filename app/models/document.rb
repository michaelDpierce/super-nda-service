# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Document < ApplicationRecord
  include Hashid::Rails

  before_validation :set_version_number, on: :create
  after_commit :run_project_stats_job, on: [:create]
  after_create :update_group_last_document

  belongs_to :group
  belongs_to :project

  has_one_attached :file, dependent: :destroy_async
  
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