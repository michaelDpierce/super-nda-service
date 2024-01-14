# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectUser < ApplicationRecord
  include Hashid::Rails

  belongs_to :project
  belongs_to :user

  scope :with_access, -> { where(access: true) }
  scope :with_admin, -> { where(access: true, admin: true) }
end