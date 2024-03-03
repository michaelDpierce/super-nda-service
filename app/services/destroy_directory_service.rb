# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class DestroyDirectoryService
  attr_reader :result, :status

  def initialize(directory_id)
    @directory_id = directory_id
    @result       = {}
    @status       = 200
  end

  def call
    @directory = Directory.find(@directory_id)

    if directory_empty?
      @result = {
        hashid: parent_directory.hashid,
        key: "folder-#{parent_directory.hashid}",
        name: parent_directory.name,
        date: parent_directory.created_at,
        extension: "-",
        type: "folder"
      }

      @directory.destroy!
    else
      @status = 422 
      @result = { error: "Folder is not empty. Please delete all documents before deleting the folder." }
    end
  rescue StandardError => e
    @status = 500
    @result = { error: e.message }
  end

  def directory_empty?
    @directory.directory_files.empty? && @directory.is_childless?
  end

  def parent_directory
    @parent_directory ||= @directory.parent
  end
end