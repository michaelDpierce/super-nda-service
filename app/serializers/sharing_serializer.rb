# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class SharingSerializer < ApplicationSerializer
  set_id :hashid
  set_type :group

  attribute :name
end 