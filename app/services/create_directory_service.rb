# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class CreateDirectoryService
  attr_reader :result
  attr_reader :status

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
    @new_directory.display_date = current_time

    @new_directory.project = @project
    @new_directory.user = @user
    @new_directory.parent = @parent_directory

    if @new_directory.save
      @parent_directory.save(validate: false)
      success
    else
      failed
    end
  end

  def success
    @result = {
      directoryID: @new_directory.hashid
    }
  end

  def failed
    @status = 422
    @result[:errors] = @new_directory.errors.messages
  end
end
