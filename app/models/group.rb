# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Group < ApplicationRecord
  include Hashid::Rails

  belongs_to :last_document, class_name: 'Document', optional: true
  belongs_to :project
  belongs_to :user

  validates :project_id, presence: true
  validates :user_id, presence: true

  has_one :last_document, -> { order(created_at: :desc) }, class_name: 'Document'
  has_many :documents, dependent: :destroy_async

  enum status: {
    queued: 1,
    sent: 2,
    negotiating: 3,
    signing: 4,
    complete: 5
  }
end