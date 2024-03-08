# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require "convert_api"
require "tempfile"
require "fileutils"

class RepairDocxJob
  include Sidekiq::Job

  def perform(directory_file_id)
    directory_file = DirectoryFile.find(directory_file_id)

    return unless directory_file.accepted_changes_file.attached? && 
                  directory_file.accepted_changes_file.content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

    repaired_file_temp_file = convert_to_docx(directory_file)

    puts repaired_file_temp_file

    Rails.logger.info "Converted file: #{repaired_file_temp_file.path}"

    directory_file.repaired_file.attach(
      io: File.open(repaired_file_temp_file.path),
      filename: "#{directory_file.accepted_changes_file.filename.base}.docx",
      content_type: "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
    )

    Rails.logger.info "Attached file: #{directory_file.repaired_file.filename}"
    Rails.logger.info "Attached attached?: #{directory_file.repaired_file.attached?}"

    clean_tempfile(repaired_file_temp_file)
  end

  private

  def convert_to_docx(df)    
    begin
      download_blob_to_tempfile(df.accepted_changes_file) do |tempfile|
        result = ConvertApi.convert("docx", { File: tempfile.path })
        download_path = result.file.save(tempfile.path.sub(".docx", "_converted.docx")) # Ensure a new file name
        File.new(download_path) # Assuming you're doing something with this File object later
      end
    rescue StandardError => e # Adjust the error class as needed
      Rails.logger.error "Error converting file: #{e.message}"
    end
  end

  def download_blob_to_tempfile(blob)
    tempfile = Tempfile.new([blob.filename.base, blob.filename.extension_with_delimiter])
    tempfile.binmode
    blob.download { |chunk| tempfile.write(chunk) }
    tempfile.rewind
    yield(tempfile)
  ensure
    tempfile.close!
  end

  def clean_tempfile(tempfile)
    if File.exist?(tempfile.path)
      Rails.logger.info "Tempfile exists: #{tempfile.path}"
      FileUtils.remove_file(tempfile.path, true)
      Rails.logger.info "Temfile exists: #{File.exist?(tempfile.path)}"
    else
      Rails.logger.info "Tempfile does not exist."
    end
  end
end