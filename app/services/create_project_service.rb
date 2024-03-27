# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

require "securerandom"

class CreateProjectService
  attr_reader :result
  attr_reader :status

  def initialize(user, params)
    @user   = user
    @params = params

    @result = {}
    @status = 201
  end

  def call
    ActiveRecord::Base.transaction do
      @project              = Project.new(@params)
      @project[:user_id]    = @user&.id
      @project[:code]       = SecureRandom.random_number(100000..999999).to_s

      Rails.logger.info(@project.inspect)

      if @project.save
        assign_project_user!
        @result = ProjectSerializer.new(@project)
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
end
