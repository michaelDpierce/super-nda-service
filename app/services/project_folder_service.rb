# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectFolderService
  def initialize(project, directory_id, current_user=nil)
    @project      = project
    @directory_id = directory_id
    @current_user = current_user
    @project_user = ProjectUser.find_by(project_id: @project.id, user_id: @current_user.id)
  end

  def data
    build_directory
  end

  private

  def build_directory
    directory = @project.directories.find(@directory_id)

    if directory.has_parent? == true
      records =  [
        {
          hashid: Directory.find(directory&.parent_id).hashid,
          key: "folder-#{directory.hashid}",
          name: "..",
          date: nil,
          extension: "-",
          type: "folder"
        }
      ]
    else
      records = Array.new
    end

    breadcrumbs = Array.new

    child_ids   = directory.child_ids
    path_ids    = directory.path_ids

    child_directories = Directory.where(id: child_ids)
    path_directories  = Directory.where(id: path_ids)

    # Build records
    child_ids.each do |child_id|      
      d = child_directories.find_by(id: child_id)

      records.push(
        {
          hashid: d.hashid,
          key: "folder-#{d.hashid}",
          name: d.name.to_s,
          date: d&.created_at,
          extension: "-",
          type: "folder",
          directory_id: d.id
        }
      )
    end

    directory_files = directory.directory_files

    directory_files.each do |df|
      url = if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(
          df.file,
          host: "http://localhost:3001"
        )
      else
        df.file.url(expires_in: 60.minutes)
      end

      if df.converted_file.attached?
        converted_file_url = if Rails.env.development?
          Rails.application.routes.url_helpers.rails_blob_url(
            df.converted_file,
            host: "http://localhost:3001"
          )
        else
          df.converted_file.url(expires_in: 60.minutes)
        end
      else
        converted_file_url = nil
      end

      filename = df.filename.to_s 
      extension = File.extname(filename).to_s
      cleanFilename = File.basename(filename, extension).to_s

      records.push(
        {
          hashid: df.hashid,
          key: "file-#{df.hashid}",
          name: filename,
          convertedFilename: df.converted_file.filename.to_s,
          cleanFilename: cleanFilename,
          date: df&.display_date,
          extension: extension,
          type: "file",
          url: url,
          convertedFileUrl: converted_file_url,
          tags: df.tag_list,
          supported: df.docx_file? || df.pdf_file?,
          conversionStatus: df.conversion_status,
          convertedFile: df.converted_file.attached?,
          committee: df.committee,
          directory_id: df.directory.hashid
        }
      )
    end

    # Build breadcrumbs
    path_ids.each do |path_id|      
      d = path_directories.find_by(id: path_id)

      breadcrumbs.push({
        hashid: d.hashid,
        name: d.name,
        projectId: @project.hashid
      })
    end

    sorted_records = records.sort_by do |record|
      [record[:type] == "folder" ? 0 : 1, record[:name].downcase]
    end

    {
      breadcrumbs: breadcrumbs,
      records: sorted_records,
      directoryID: directory.hashid,
      permissions: {
        admin: @project_user.admin,
      }
    }
  end
end
