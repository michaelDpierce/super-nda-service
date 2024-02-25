# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class CreateDirectoryService
  attr_reader :result, :status

  def initialize(project, parent_directory, params, user)
    @project          = project
    @parent_directory = parent_directory
    @params           = params
    @user             = user
    @result           = {}
    @status           = 201
  end

  def call
    current_time = Time.current

    @new_directory = Directory.new(@params)
    @new_directory.set_slug

    @new_directory.project = @project
    @new_directory.user = @user
    @new_directory.parent = @parent_directory

    begin
      ActiveRecord::Base.transaction do
        @new_directory.save!
        @parent_directory.save!(validate: false)
      end

      success
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("Directory creation failed: #{e.message}")
      failed("Directory validation failed. Please try again.")
    rescue ActiveRecord::RecordNotUnique => e
      Rails.logger.error("Directory creation failed due to uniqueness constraint: #{e.message}")
      failed("Directory name must be unique within the parent directory. Please choose a different name.")
    rescue => e
      Rails.logger.error("Unexpected error during directory creation: #{e.message}")
      failed("An unexpected error occurred. Please try again.")
    end
  end

  def success
    @status = 201
    @result = {
      hashid: @new_directory.hashid,
      key: "folder-#{@new_directory.hashid}",
      name: @new_directory.name.to_s,
      date: @new_directory&.created_at,
      extension: "-",
      type: "folder"
    }
  end

  def failed(message)
    @status = 422
    @result = { error: message }
  end
end