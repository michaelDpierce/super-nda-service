# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ContactSerializer < ApplicationSerializer
  set_id :hashid
  set_type :contact

  attribute :prefix, :first_name, :last_name
end 