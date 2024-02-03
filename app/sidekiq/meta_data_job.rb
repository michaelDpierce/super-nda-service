# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require 'docx'
require 'pdf-reader'
require 'tempfile'

class MetaDataJob
  include Sidekiq::Job

  def perform(directory_file_id, user_id)
    Rails.logger.info "directory_file_id: #{directory_file_id}"
    Rails.logger.info "user_id: #{user_id}"

    df = DirectoryFile.find(directory_file_id)
    blob = df.file.blob

    if blob.present?
      Rails.logger.info "Creating Tempfile for Blob: #{blob.filename}"

      if blob.filename.extension_with_delimiter.downcase == '.pdf'
        Rails.logger.info 'Processing PDF File'

        Tempfile.create(
          [blob.filename.base, blob.filename.extension_with_delimiter],
          binmode: true
        ) do |file|
          file.write(blob.download)
          file.rewind

          text = String.new

          reader = PDF::Reader.new(file.path)
          text = reader.pages.map(&:text).join("\n")

          text = text.squish

          Rails.logger.info "Updaing Database with Text: #{text}"
          df.update(content: text)
        end
      elsif blob.filename.extension_with_delimiter.downcase == '.docx'
        Rails.logger.info 'Processing DOCX File'

        Tempfile.create(
          [blob.filename.base, blob.filename.extension_with_delimiter],
          binmode: true
        ) do |file|
          file.write(blob.download)
          file.rewind

          doc = Docx::Document.open(file.path)
        
          content = String.new
  
          doc.paragraphs.each do |paragraph|
            content += paragraph.text.strip + "\n"
          end
        
          doc.tables.each do |table|
            table.rows.each do |row|
              row_cells = row.cells.map { |cell| cell.text.strip }.join(' | ')
              content += row_cells + "\n"
            end
            content += "\n"
          end

          content = content.squish

          Rails.logger.info "Updaing Database with Content: #{content}"
          df.update(content: content)
        end
      else
        Rails.logger.info 'Unsupported File Type'
      end
    end
  end
end