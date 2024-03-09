# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class User < ApplicationRecord
  include Hashid::Rails

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true

  has_many :project_users, dependent: :destroy_async
  has_many :projects, through: :project_users
  has_many :project_users_with_access, -> { with_access }, class_name: "ProjectUser"
  has_many :projects_with_access, source: :project, through: :project_users_with_access
end
