# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

class User < ApplicationRecord
  include Hashid::Rails

  before_save :set_matchers 

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true

  has_many :project_users, dependent: :destroy_async
  has_many :projects, through: :project_users
  has_many :project_users_with_access, -> { with_access }, class_name: 'ProjectUser'
  has_many :projects_with_access, source: :project, through: :project_users_with_access

  private

  def sanitize_input(text)
    if text.present?
      text.gsub(/\s+/, "")
          .gsub(/[^\w\s]/, "")
          .downcase
    else
      ""
    end
  end

  def set_matchers
    self.prefixmatch = "#{sanitize_input(prefix)}#{sanitize_input(last_name)}"
    self.fullname_match = "#{sanitize_input(first_name)}#{sanitize_input(last_name)}"
  end
end
