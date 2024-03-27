# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Group < ApplicationRecord
  include Hashid::Rails

  belongs_to :project
  belongs_to :user, optional: true

  validates :project_id, presence: true

  has_one :last_document, class_name: 'Document', primary_key: 'last_document_id', foreign_key: 'id'
  has_many :documents, -> { order(version_number: :asc) }, class_name: 'Document', dependent: :destroy

  enum status: {
    queued: 1,
    sent: 2,
    negotiating: 3,
    signing: 4,
    complete: 5
  }
end