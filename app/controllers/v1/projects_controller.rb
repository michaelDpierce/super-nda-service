# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ProjectsController < V1::BaseController
  before_action :find_project, only: %i[show update destroy]

  before_action :find_project_user, only: %i[show update destroy]

  # GET /v1/projects
  def index
    base_filtering!

    if params[:pinned].present?
      project_ids =
        ProjectUser.where(user_id: @current_user.id, pinned: true)
          .pluck(:project_id)

      @resource = @resource.where(id: project_ids)

      render_resource(
        @resource,
        DashboardSerializer,
        params: { user_id: @current_user.id }
      )
    else
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
  end

  # GET /v1/pinned
  def pinned
    base_filtering!

    project_ids =
      ProjectUser.where(user_id: @current_user.id, pinned: true)
        .pluck(:project_id)

    @resource = @resource.where(id: project_ids)

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
      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { message: 'Project not found' }, status: :not_found
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

  private

  def find_project
    @project = @current_user.projects_with_access.find(params[:id])
    
    head(:no_content) unless @project.present?
  end
  
  def find_project_user
    @project_user = @project.project_users.find_by(user_id: @current_user.id)

    if @project_user.nil?
      render(json: { message: 'Project access is denied' }, status: :forbidden)
    end
  end

  def create_project_params
    params.require(:project).permit(:name, :description, :user_id)
  end

  def update_project_params
    params
      .require(:project)
      .permit(:name, :description, :logo, :status)
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
