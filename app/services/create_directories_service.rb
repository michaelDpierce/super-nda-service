# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class CreateDirectoriesService
  attr_reader :record_id

  # @param[User] user
  # @param[Project] project
  # @param[Directory] directory
  # @param[ActiveStorage::Blob] blob
  def initialize(user, project, directory, blob)
    @user      = user
    @project   = project
    @directory = directory
    @blob      = blob
    @record_id = nil
  end

  def call
    attach_blob
  end

  private

  def upload_file_in_dir
    attach_blob
  end

  def attach_blob
    return if @blob.nil? || @directory.nil?

    record = @directory.directory_files.find_or_initialize_by(blob_id: @blob.id)
    record.project_id = @project.id
    record.user = @user
    record.filename = @blob.filename
    record.byte_size = @blob.byte_size
    record.file_type = @blob.content_type
    record.save

    @record_id = record.hashid
  end
end
