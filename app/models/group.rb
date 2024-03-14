# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class Group < ApplicationRecord
  include Hashid::Rails

  default_scope { order(name: :asc) }

  belongs_to :project
  belongs_to :user

  validates :user_id, presence: true

  has_many :documents, dependent: :destroy_async

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

  def pretty_status
    case status
    when "queued"
      "Queued"
    when "teaser_sent"
      "Teaser Sent"
    when "nda_sent"
      "NDA Sent"
    when "redline_returned"
      "Redline Returned"
    when "redline_sent"
      "Redline Sent"
    when "ready_to_sign"
      "Ready to Sign"
    when "signed"
      "Signed"
    when "no_response"
      "No Response"
    when "passed"
      "Passed"
    else
      "-"
    end
  end

  def progress
    case status
    when "queued"
      "queued"
    when "teaser_sent", "nda_sent", "redline_returned", "redline_sent", "ready_to_sign"
      "in_progress"
    when "no_response", "passed"
      "passed"
    when "signed"
      "completed"
    else
      "-"
    end
  end
end