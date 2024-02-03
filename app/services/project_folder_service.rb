# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectFolderService
  def initialize(project, directory_id, current_user=nil)
    @project      = project
    @directory_id = directory_id
    @current_user = current_user
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
          hashid: directory&.parent_id,
          key: "folder-#{directory.hashid}",
          name: "..",
          date: nil,
          ableToView: false,
          extension: '-',
          type: 'folder'
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
          date: d&.display_date,
          ableToView: false,
          extension: '-',
          type: 'folder'
        }
      )
    end

    directory_files = directory.directory_files

    directory_files.each do |df|
      # url = if Rails.env.development?
      #   Rails.application.routes.url_helpers.rails_blob_path(df.file, only_path: true)
      # else
      #   df.file.url(expires_in: 5.minutes)
      # end

      url = df.file.url(expires_in: 20.minutes)

      puts "url: #{url}"

      records.push(
        {
          hashid: df.hashid,
          key: "file-#{df.hashid}",
          name: df.filename.to_s,
          date: df&.display_date,
          ableToView: true,
          extension: df&.file&.blob&.filename&.extension,
          type: 'file',
          url: url,
          # url: df.file.url(expires_in: 5.minutes, disposition: "attachment"),
          tags: df.tag_list
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

    {
      breadcrumbs: breadcrumbs,
      records: records,
      directoryID: directory.hashid,
    }
  end
end
