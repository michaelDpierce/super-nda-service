# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Document < ApplicationRecord
  include AASM

  belongs_to :group
  has_many :revisions, dependent: :destroy_async
  has_one_attached :file, dependent: :destroy_async

  aasm column: 'state' do
    state :queued, initial: true
    state :nda_sent
    state :negotiating
    state :ready_to_sign

    event :start_negotiation do
      transitions from: :nda_sent, to: :negotiating
    end

    event :prepare_to_sign do
      transitions from: :negotiating, to: :ready_to_sign
    end
  end

  # TODO
  def add_revision(file, side)
    # revisions.create!(file: file, side: side)
    # # Logic to increment revision numbers goes here
  end
end