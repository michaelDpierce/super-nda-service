# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Revision < ApplicationRecord
  belongs_to :document
  has_one_attached :file
end