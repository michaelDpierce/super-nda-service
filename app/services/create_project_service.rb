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
        # create_def_directory!
        @result = ProjectSerializer.new(@project).serialized_json
      else
        @status = :unprocessable_entity
        @result = @project.errors
      end
    end
  rescue StandardError => err
    puts err.inspect
    @status = :unprocessable_entity
  end

  def assign_project_user!
    ProjectUser.create!(
      project_id: @project.id,
      user_id: @user.id,
      admin: true,
      access: true,
      pinned: true,
      pinned_at: Time.now
    )
  end

  # def create_def_directory!
  #   Directory
  #     .create!(
  #       user: @user,
  #       slug: Directory::ROOT_SLUG,
  #       project_id: @project.id,
  #       name: @project.name,
  #       modified_by_user_id: @user.id
  #     )
  #     .permissions
  #     .create!(
  #       permission_subject: @group,
  #       view: true,
  #       download: true,
  #       edit: true
  #     )
  # end
end
