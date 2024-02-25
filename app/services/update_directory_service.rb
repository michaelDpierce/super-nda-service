# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class UpdateDirectoryService
  attr_reader :result
  attr_reader :status

  def initialize(directory, params, user)
    @directory = directory
    @params    = params
    @user      = user
    @result    = {}
    @status    = 202
  end

  def call
    ActiveRecord::Base.transaction do
      @directory.assign_attributes(@params)

      begin
        ActiveRecord::Base.transaction do
          @directory.save!
        end
  
        success
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Directory update failed: #{e.message}")
        failed("Directory validation failed. Please try again.")
      rescue ActiveRecord::RecordNotUnique => e
        Rails.logger.error("Directory update failed due to uniqueness constraint: #{e.message}")
        failed("Directory name must be unique within the parent directory. Please choose a different name.")
      rescue => e
        Rails.logger.error("Unexpected error during directory creation: #{e.message}")
        failed("An unexpected error occurred. Please try again.")
      end
    end
  end

  def failed(message)
    @status = 422
    @result = { error: message }
  end

  def success
    @result = {
      hashid: @directory.hashid,
      key: "folder-#{@directory.hashid}",
      name: @directory.name.to_s,
      date: @directory&.created_at,
      extension: "-",
      type: "folder"
    }
  end
end
