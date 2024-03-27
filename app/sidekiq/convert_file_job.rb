# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

require "convert_api"
require "tempfile"
require "fileutils"
require "pdf-reader"

class ConvertFileJob
  include Sidekiq::Job

  def perform(document_id)
    document = Document.find(document_id)

    return unless document.file.attached? && document.file.content_type == "application/vnd.openxmlformats-officedocument.wordprocessingml.document"

    converted_temp_file = convert_to_pdf(document)
    Rails.logger.info "Converted file: #{converted_temp_file.path}"

    # Count the number of pages in the converted PDF
    number_of_pages = count_pdf_pages(document, converted_temp_file.path)
    Rails.logger.info "Number of pages in PDF: #{number_of_pages}"

    document.converted_file.attach(
      io: File.open(converted_temp_file.path),
      filename: "#{document.file.filename.base}.pdf",
      content_type: "application/pdf"
    )

    Rails.logger.info "Attached file: #{document.converted_file.content_type}"
    Rails.logger.info "Attached file: #{document.converted_file.filename}"
    Rails.logger.info "Attached attached?: #{document.converted_file.attached?}"

    clean_tempfile(converted_temp_file)
  end

  private

  def convert_to_pdf(df)
    begin
      download_blob_to_tempfile(df.file) do |tempfile|
        result = ConvertApi.convert("pdf", { File: tempfile.path })
        download_path = result.file.save(tempfile.path.sub(".docx", ".pdf"))
        File.new(download_path)
      end
    rescue ConvertApi::ConvertApiError => e
      Rails.logger.error "Error converting file: #{e.message}"
      df.update!(conversion_status: :failed)
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

  def count_pdf_pages(document, file_path)
    reader = PDF::Reader.new(file_path)
    document.update!(number_of_pages: reader.page_count)
    reader.page_count
  rescue PDF::Reader::MalformedPDFError, PDF::Reader::UnsupportedFeatureError => e
    Rails.logger.error "Error reading PDF file: #{e.message}"
    document.update!(number_of_pages: reader.page_count)
    0
  end
end