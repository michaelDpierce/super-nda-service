# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class Contact < ApplicationRecord
  include Hashid::Rails

  before_save :update_lookups

  has_many :directory_files, through: :meeting_attendances
  has_many :meeting_attendances
  has_many :project_contacts, dependent: :destroy_async

  def full_name
    "#{first_name} #{last_name}"
  end
  
  private

  def update_lookups
    self.formal_name_lookup =
      "#{prefix}#{last_name}".gsub(/[^A-Za-z0-9]/, '').downcase

    self.full_name_lookup =
      "#{first_name}#{last_name}".gsub(/[^A-Za-z0-9]/, '').downcase
  end
end