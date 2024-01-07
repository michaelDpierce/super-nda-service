# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

class User < ApplicationRecord
  include Hashid::Rails

  validates :email, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :email, uniqueness: true
end
