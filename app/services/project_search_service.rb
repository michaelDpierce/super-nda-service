# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectSearchService
  attr_reader :status

  def initialize(project, query)
    @project = project
    @query   = query
    @status  = 200
  end

  def result    
    data =
      perform_search.map { |record| build_search_result(record)}

    puts data

    @result = {
      data: data,
      status: 200,
    }
  end

  private

  def perform_search
    @project.directory_files.search_by_tag(@query)
  end

  def build_search_result(record)
    url = if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(
        record.file,
        host: "http://localhost:3001"
      )
    else
      record.file.url(expires_in: 60.minutes)
    end

    if record.converted_file.attached?
      converted_file_url = if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(
          record.converted_file,
          host: "http://localhost:3001"
        )
      else
        record.converted_file.url(expires_in: 60.minutes)
      end
    else
      converted_file_url = nil
    end

    filename = record.filename.to_s 
    extension = File.extname(filename).to_s
    cleanFilename = File.basename(filename, extension).to_s

    { 
      hashid: record.hashid,
      key: "file-#{record.hashid}",
      name: filename,
      convertedFilename: record.converted_file.filename.to_s,
      cleanFilename: cleanFilename,
      date: record&.display_date,
      extension: extension,
      type: "file",
      url: url,
      convertedFileUrl: converted_file_url,
      tags: record.tag_list,
      supported: record.docx_file? || record.pdf_file?,
      conversionStatus: record.conversion_status,
      convertedFile: record.converted_file.attached?,
      committee: record.committee,
      directory_id: record.directory.hashid
    }
  end
end
