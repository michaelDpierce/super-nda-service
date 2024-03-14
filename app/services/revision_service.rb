# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

# TODO

class RevisionService
  def self.add_revision(document_id, file, side)
    document = Document.find(document_id)
    
    new_revision_number = document.revisions.count + 1

    revision =
      document.revisions.create!(
        file: file,
        revision_number: new_revision_number,
        side: side
      )
    
    # if side == 'other'
    #   document.start_negotiation! if document.may_start_negotiation?
    # end

    revision
  end
end