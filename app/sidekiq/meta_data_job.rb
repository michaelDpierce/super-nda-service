# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require 'pdf-reader'
require 'tempfile'

class MetaDataJob
  include Sidekiq::Job

  def perform(directory_file_id, user_id)
    Rails.logger.info "directory_file_id: #{directory_file_id}"
    Rails.logger.info "user_id: #{user_id}"

    text = ""

    df = DirectoryFile.find(directory_file_id)
    blob = df.file.blob

    if blob.present?
      Rails.logger.info "Creating Tempfile for Blob: #{blob.filename}"

      Tempfile.create(
        [blob.filename.base, blob.filename.extension_with_delimiter],
        binmode: true
      ) do |file|
        file.write(blob.download)
        file.rewind

        reader = PDF::Reader.new(file.path)
        text = reader.pages.map(&:text).join("\n")

        Rails.logger.info text

        text = text.squish

        Rails.logger.info "Updaing Database with Text: #{text}"
        df.update(content: text)
      end
    end
  end
end