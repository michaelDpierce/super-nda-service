# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
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

  has_many :project_users, dependent: :destroy_async
  has_many :users, through: :project_users
  
  has_many :project_users_with_access, -> { with_access }, class_name: "ProjectUser"
  has_many :users_with_access, source: :user, through: :project_users_with_access

  has_many :admin_project_users, -> { with_admin }, class_name: "ProjectUser"
  has_many :admin_users, source: :user, through: :admin_project_users

  belongs_to :contact, optional: true

  has_many :project_contacts, dependent: :destroy_async
  has_many :contacts, through: :project_contacts

  has_many :directories, dependent: :destroy_async
  has_many :files, through: :directories
  has_many :directory_files, through: :directories

  has_one_attached :logo, dependent: :destroy_async

  enum status: {
    active: 0,
    archived: 1
  }
end
