# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class User < ApplicationRecord
  include Hashid::Rails

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true

  has_one_attached :signature, dependent: :destroy_async

  has_many :documents, foreign_key: 'creator_id', dependent: :destroy_async

  has_many :project_users, dependent: :destroy_async
  has_many :projects, through: :project_users

  has_many :project_users_with_access, -> { with_access }, class_name: "ProjectUser"

  has_many :projects_with_access,
    source: :project,
    through: :project_users_with_access

  def full_name_reverse
    "#{last_name}, #{first_name} "
  end

  def full_name
    "#{first_name} #{last_name}"
  end
end
