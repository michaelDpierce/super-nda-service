# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectUser < ApplicationRecord
  include Hashid::Rails

  enum role: {
    view: 1,
    edit: 2,
  }

  belongs_to :project
  belongs_to :user

  scope :with_access, -> { where(access: true) }
  scope :with_admin, -> { where(access: true, admin: true) }
end