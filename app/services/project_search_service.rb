# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectSearchService
  attr_reader :status

  def initialize(query, project_id)
    @query      = query
    @project_id = project_id
    @status     = 200
  end

  def result
    result =
      if @query.include?(':')
        attribute, value = @query.split(':', 2)
        clean_value = value.squish!

        case attribute
        when 'tag', 't'
          DirectoryFile.joins(:tags)
            .where("LOWER(tags.name) = LOWER(?) AND directory_files.project_id = ?", clean_value.downcase, @project_id)
            .distinct
        when 'committee', 'c'
          DirectoryFile.where("committee ILIKE ? AND project_id = ?", "%#{clean_value}%", @project_id)
        end
      else
        DirectoryFile.where("filename ILIKE ? AND project_id = ?", "%#{clean_value}%", @project_id)
      end

    data =
      result.map { |record| build_search_result(record)}

    @result = {
      data: data,
      status: 200
    }
  end

  private

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
