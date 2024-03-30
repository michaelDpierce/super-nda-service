# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectUser < ApplicationRecord
  include Hashid::Rails

  has_paper_trail skip: [:last_viewed_at]
  
  belongs_to :project
  belongs_to :user

  scope :with_access, -> { where(access: true) }
  scope :with_admin, -> { where(access: true, admin: true) }
end
