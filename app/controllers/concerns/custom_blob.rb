# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class CustomBlob < ActiveStorage::Blob
  before_create :rename_blob

  def rename_blob
    self.filename = self.filename.to_s&.gsub(REGEX_PATTERN, '')
  end
end
