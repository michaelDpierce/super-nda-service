# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Group < ApplicationRecord
  include Hashid::Rails

  belongs_to :project
  belongs_to :user

  validates :user_id, presence: true

  enum status: {
    queued: 0,
    teaser_sent: 1,
    nda_sent: 2,
    redline_returned: 3,
    redline_sent: 4,
    ready_to_sign: 5,
    signed: 6,
    no_response: 7,
    passed: 8
  } 
end