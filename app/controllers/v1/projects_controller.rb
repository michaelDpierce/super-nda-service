# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require "csv"

class V1::ProjectsController < V1::BaseController
  before_action :find_project,
    only: %i[
      show
      update
      destroy
      folder
      remove_supporting_document
      tags
      export
      create_project_user
      check_admin
    ]

  before_action :find_project_user,
    only: %i[
      show
      update
      destroy
      folder
      remove_supporting_document
      tags
      export
      create_project_user
      check_admin
    ]

  # GET /v1/projects
  def index
    base_filtering!

    project_ids =
      ProjectUser.where(user_id: @current_user.id)
        .pluck(:project_id)

    @resource = @resource.where(id: project_ids)

    render_resource(
      @resource,
      ProjectsSerializer,
      {}
    )
  end

  # GET /v1/pinned
  def pinned
    base_filtering!

    project_ids =
      ProjectUser.where(user_id: @current_user.id, pinned: true)
        .pluck(:project_id)

    @resource = @resource.where(id: project_ids).where(status: "active")

    render_resource(
      @resource,
      PinnedProjectsSerializer,
      params: { user_id: @current_user.id }
    )
  end

  # POST /v1/projects
  def create
    service =
      CreateProjectService.new(
        @current_user,
        create_project_params,
        request&.remote_ip
      )

    service.call
    render(json: service.result, status: service.status)
  end

  # GET /v1/projects/:hashid
  def show
    options = {
      params: {
        permissions: {
          isAdmin: @project_user.try(:admin)
        },
        meta: {
          current_user_id: @current_user.try(:id),
          project_user_id: @project_user.try(:hashid),
          status: @project.try(:status),
          pinned: @project_user.try(:pinned)
        }
      },
    }

    if @project.present?
      LastViewedAtJob.perform_async(@project_user.id)

      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { message: "Project not found" }, status: :not_found
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    options = {
      params: {
        permissions: {
          isAdmin: @project_user.try(:admin)
        },
        meta: {
          current_user_id: @current_user.try(:id),
          project_user_id: @project_user.try(:hashid),
          status: @project.try(:status),
          pinned: @project_user.try(:pinned)
        }
      },
    }

    if @project.update(update_project_params)
      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { errors: @project.errors.messages },
             status: :unprocessable_entity
    end
  end

  # DELETE /v1/projects/:hashid
  def destroy    
    @project.destroy!
    head(:no_content)
  end

  # GET /v1/search
  def search
    service = ProjectSearchService.new(
      @current_user.id,
      { q: params[:q] },
      params[:limit] || 10
    )

    render(json: { result: service.result })
  end

  # GET /v1/projects/:hashid/folder/:directory_id
  def folder
    directory_id = if params[:directory_id].present?
      params[:directory_id]
    else
      @project.directories.root.id
    end

    service =
      ProjectFolderService.new(@project, directory_id, @current_user)
      
    render(json: { data: service.data })
  end

  # GET /v1/projects/:hashid/tags
  def tags
    directory_file_ids = @project.directory_files.pluck(:id)

    tag_list = ActsAsTaggableOn::Tag.joins(:taggings)
      .where(taggings: { taggable_id: directory_file_ids, taggable_type: "DirectoryFile" })
      .select("distinct tags.name")
      .pluck(:name)
        
    render(json: { data: tag_list })
  end

  # GET /v1/projects/:hashid/export
  def export
    dfs = @project.directory_files

    data = CSV.generate(headers: true) do |csv|
      csv << [
        "ID",
        "Name",
        "Directory",
        "Created At",
        "Updated At",
        "Date",
        "Uploaded By",
        "Tags"
      ]

      dfs.each do |df|
        csv << [
          df.id,
          df.filename,
          df.directory.try(:name),
          df.created_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.display_date.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.user.try(:email),
          df.tag_list.join(", ").to_s

        ]
      end
    end

    send_data data, filename: "report.csv", type: "text/csv"
  end

  # POST /v1/projects/:hashid/create_project_user
  def create_project_user
    ActiveRecord::Base.transaction do
      email = params["data"]["email"]
  
      # Check if a ProjectUser already exists with the given user's email for this project
      existing_project_user = ProjectUser.joins(:user).find_by(users: {email: email}, project_id: @project.id)
      if existing_project_user.present?
        # If a ProjectUser with the given email already exists, return an error
        render(json: { error: 'A user with that email already exists in this project.' }, status: :unprocessable_entity)
        return # Stop execution to ensure no further processing
      end
  
      # Attempt to find an existing user by email or create a new one
      user = User.find_or_create_by!(email: email) do |user|
        user.first_name = params["data"]["firstName"]
        user.last_name = params["data"]["lastName"]
      end
    
      # Create a new ProjectUser since we've confirmed one does not exist for this user and project
      project_user = ProjectUser.create!(user_id: user.id, project_id: @project.id, pinned: true)
  
      render(json: { data: project_user }, status: :created)
    end
  rescue ActiveRecord::RecordInvalid => e
    render(json: { error: e.message }, status: :unprocessable_entity)
  end

  # GET /v1/projects/:hashid/check_admin
  def check_admin
    render(json: { admin: @project_user.admin? }, status: :ok)
  end

  private

  def find_project
    @project = @current_user.projects_with_access.find(params[:id])
    head(:no_content) unless @project.present?
  end
  
  def find_project_user
    @project_user = @project.project_users.find_by(user_id: @current_user.id)

    if @project_user.nil?
      render(json: { message: "Project access is denied" }, status: :forbidden)
    end
  end

  def create_project_params
    params.require(:project).permit(:name, :description, :user_id)
  end

  def update_project_params
    params
      .require(:project)
      .permit(:name, :description, :logo, :status)
      .select { |x,v| v.present? }
  end

  def forbidden
    head(:forbidden)
  end

  def base_filtering!
    load_resource!

    basic_search_resource_by!
    filter_resource_by_created!

    order_resource!

    @resource = @resource.includes(:project_users)
  end

  def load_resource!
    @resource = @current_user.projects_with_access
  end

  def order_resource!
    return if params[:sort_by].present?

    @resource = @resource.order(created_at: :desc)
  end
end
