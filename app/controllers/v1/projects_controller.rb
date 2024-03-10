# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

require "csv"

class V1::ProjectsController < V1::BaseController
  before_action :find_project,
    only: %i[
      show
      update
      destroy
      export
      create_project_user
      check_admin
    ]

  before_action :find_project_user,
    only: %i[
      show
      update
      destroy
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

  # POST /v1/projects
  def create
    service =
      CreateProjectService.new(
        @current_user,
        create_project_params
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
          status: @project.try(:status)
        }
      },
    }

    if @project.present?
      LastViewedAtJob.perform_async(@project_user.id)

      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { message: "Project not found." }, status: :not_found
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    was_not_archived = !@project.archived?

    options = {
      params: {
        permissions: {
          isAdmin: @project_user.try(:admin)
        },
        meta: {
          current_user_id: @current_user.try(:id),
          project_user_id: @project_user.try(:hashid),
          status: @project.try(:status)
        }
      },
    }

    if @project.update(update_project_params)
      if was_not_archived && @project.archived?
        ProjectArchiveJob.perform_async(@project.id)
      end

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
    service = 
      SearchService.new(
        @current_user.id,
        { q: params[:q] },
        params[:limit] || 10
      )
  
    render(json: { result: service.result, status: service.status })
  end

  # GET /v1/projects/:hashid/export
  def export
    # send_data data, filename: "report.csv", type: "text/csv"
  end

  # POST /v1/projects/:hashid/create_project_user
  def create_project_user
    ActiveRecord::Base.transaction do
      email = params["data"]["email"]
  
      existing_project_user =
        ProjectUser.joins(:user)
          .find_by(users: {email: email}, project_id: @project.id)
      
        if existing_project_user.present?
          render(
            json: {
              error: 'A user with that email already exists in this project.'
            },
            status: :unprocessable_entity
          )
          
          return
        end
  
      user = User.find_or_create_by!(email: email) do |user|
        user.first_name = params["data"]["first_name"] if params["data"]["first_name"].present?
        user.last_name = params["data"]["last_name"] if params["data"]["last_name"].present?
        user.title = params["data"]["title"] if params["data"]["title"].present?
      end
    
      project_user =
        ProjectUser.create!(user_id: user.id, project_id: @project.id)
  
      render(
        json: ProjectUsersSerializer.new(project_user, includes: :user),
        status: :created
      )
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
      render(json: { message: "Project access is denied." }, status: :forbidden)
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
