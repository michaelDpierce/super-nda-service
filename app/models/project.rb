# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Project < ApplicationRecord
  include Hashid::Rails
  include PgSearch::Model

  multisearchable against: [:name]

  pg_search_scope :main_search,
                  against: %i[name],
                  using: {
                    tsearch: { prefix: true }
                  }

  validates :name, presence: true

  belongs_to :user, optional: true

  has_one_attached :logo, dependent: :destroy_async
  has_one_attached :template, dependent: :destroy_async

  has_many :project_users, dependent: :destroy_async
  has_many :users, through: :project_users
  
  has_many :project_users_with_access, -> { with_access }, class_name: "ProjectUser"
  has_many :users_with_access, source: :user, through: :project_users_with_access

  has_many :admin_project_users, -> { with_admin }, class_name: "ProjectUser"
  has_many :admin_users, source: :user, through: :admin_project_users

  has_many :groups, dependent: :destroy

  enum status: {
    active: 0,
    completed: 1,
    archived: 2
  }

  def create_template_blob(filename)
    file_content  = template.download
    rewindable_io = StringIO.new(file_content)
  
    ActiveStorage::Blob.create_and_upload!(
      io: rewindable_io,
      filename: filename,
      content_type: template.content_type
    )
  end

  def duplicate_version_blob(last_document_id, filename)
    last_document = Document.find(last_document_id)
    file_content  = last_document.file.download
    rewindable_io = StringIO.new(file_content)

    ActiveStorage::Blob.create_and_upload!(
      io: rewindable_io,
      filename: filename,
      content_type: last_document.file.blob.content_type
    )
  end

  def stats
    counts       = groups.group(:status).count
    passed_count = groups.where(passed: true).count
    
    {
      queued: counts['queued'] || 0,
      sent: counts['sent'] || 0,
      negotiating: counts['negotiating'] || 0,
      signing: counts['signing'] || 0,
      complete: counts['complete'] || 0,
      passed: passed_count
    }
  end
end
