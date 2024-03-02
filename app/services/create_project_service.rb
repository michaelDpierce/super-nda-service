# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class CreateProjectService
  attr_reader :result
  attr_reader :status

  def initialize(user, params, ip=0)
    @user   = user
    @params = params
    @ip     = ip

    @result = {}
    @status = 201
  end

  def call
    ActiveRecord::Base.transaction do
      @project           = Project.new(@params)
      @project[:user_id] = @user&.id

      Rails.logger.info(@project.inspect)

      if @project.save
        assign_project_user!
        create_root_directory!
        @result = ProjectSerializer.new(@project).serialized_json
      else
        @status = :unprocessable_entity
        @result = @project.errors
      end
    end
  rescue StandardError => err
    Rails.logger.info err.inspect

    @status = :unprocessable_entity
  end

  def assign_project_user!
    ProjectUser.create!(
      project_id: @project.id,
      user_id: @user.id,
      admin: true,
      access: true
    )
  end

  def create_root_directory!
    Directory
      .create!(
        user_id: @user.id,
        slug: ROOT_SLUG,
        project_id: @project.id,
        name: @project.name
      )
  end
end
