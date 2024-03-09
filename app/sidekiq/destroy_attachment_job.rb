# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class DestroyAttachmentJob
  include Sidekiq::Job

  def perform(attachment_id)
    attachment = ActiveStorage::Attachment.find_by(id: attachment_id)
    attachment&.purge
  end
end