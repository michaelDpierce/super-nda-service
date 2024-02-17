# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require 'convert_api'
require 'tempfile'
require 'fileutils'

class ConvertFileJob
  include Sidekiq::Job

  def perform(directory_file_id, user_id)
    directory_file = DirectoryFile.find(directory_file_id)

    return unless directory_file.file.attached? && directory_file.file.content_type == 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'

    directory_file.update!(conversion_status: :in_progress)

    converted_temp_file = convert_to_pdf(directory_file.file)
    Rails.logger.info "Converted file: #{converted_temp_file.path}"

    directory_file.converted_file.attach(
      io: File.open(converted_temp_file.path),
      filename: "#{directory_file.file.filename.base}.pdf",
      content_type: 'application/pdf'
    )

    Rails.logger.info "Attached file: #{directory_file.converted_file.filename}"
    Rails.logger.info "Attached attached?: #{directory_file.converted_file.attached?}"

    clean_tempfile(converted_temp_file)
    directory_file.update!(conversion_status: :completed)
  # rescue StandardError => e
  #   Rails.logger.error "Error converting file: #{e.message}"
  #   directory_file.update!(conversion_status: :failed)
  end

  private

  def convert_to_pdf(file)    
    download_blob_to_tempfile(file) do |tempfile|
      result = ConvertApi.convert('pdf', { File: tempfile.path })
      download_path = result.file.save(tempfile.path.sub('.docx', '.pdf'))
      File.new(download_path)
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