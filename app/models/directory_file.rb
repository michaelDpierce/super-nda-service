# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class DirectoryFile < ApplicationRecord
  include Hashid::Rails

  belongs_to :directory
  belongs_to :user

  has_one_attached :file
  has_one :project, through: :directory, source: :project
end
