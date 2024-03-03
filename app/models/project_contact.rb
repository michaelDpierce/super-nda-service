# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectContact < ApplicationRecord
  include Hashid::Rails
  
  belongs_to :contact
  belongs_to :project
end
