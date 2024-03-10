# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

class User < ApplicationRecord
  include Hashid::Rails

  before_save :update_email_domain, if: :will_save_change_to_email?

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true

  has_many :project_users, dependent: :destroy_async
  has_many :projects, through: :project_users

  has_many :project_users_with_access, -> { with_access }, class_name: "ProjectUser"

  has_many :projects_with_access,
    source: :project,
    through: :project_users_with_access

  private

  def update_email_domain
    self.domain = extract_domain_from_email
  end

  def extract_domain_from_email
    email.split('@').last
  end
end
