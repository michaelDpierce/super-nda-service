# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name, :description
end 
