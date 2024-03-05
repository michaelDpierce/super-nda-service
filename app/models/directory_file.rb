# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class DirectoryFile < ApplicationRecord
  include Hashid::Rails

  acts_as_taggable_on :tags

  belongs_to :directory
  belongs_to :user

  has_one_attached :file
  has_one_attached :converted_file

  has_one :project, through: :directory, source: :project

  has_many :meeting_attendances
  has_many :contacts, through: :meeting_attendances

  enum conversion_status: { pending: 0, in_progress: 1, completed: 2, failed: 3, not_supported: 4 }

  def docx_file?
    file.content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
  end

  def pdf_file?
    file.content_type == "application/pdf"
  end
end
