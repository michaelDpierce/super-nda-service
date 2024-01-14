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
        ProjectUser.where(user_id: @current_user.id, pinned: true).pluck(:project_id)

      @resource = @resource.where(id: project_ids)
    end

    puts @resource.first.inspect

    render_resource(
      @resource,
      ProjectsSerializer,
      params: { user_id: @current_user.id }
    )
  end

  # GET /v1/projects/:id
  def show
    render(json: ProjectSerializer.new(@project).serialized_json, status: :ok)
  end

  # POST /v1/projects
  def create
    service = CreateProjectService.new(@current_user, create_project_params, request&.remote_ip)
    service.call
    render(json: service.result, status: service.status)
  end

  # GET /v1/projects/:hashid
  # def show
  #   authorize(@project, :access?)

  #   options = {
  #     params: {
  #       current_user_id: current_user.id,
  #       group_id: @project_user.group.hashid,
  #       project_user_id: @project_user.hashid,
  #       pinned: @project_user.pinned,
  #       new_files_count: @project_user.new_files_count,
  #       permissions: {
  #         isAdmin: @project_user.admin,
  #         addUsersToGroup: @project_user.add_users_to_group,
  #         removeUserFromGroup: @project_user.remove_user_from_group,
  #         isViewIndex: @project_user.view_index,
  #         paid: @project.paid,
  #         status: @project.status
  #       },
  #       settings: {
  #         filesNotification: @project_user&.files_notification,
  #         projectAccessAdminNotification: @project_user&.project_access_admin_notification
  #       }
  #     },
  #   }

  #   if @project.present?
  #     render json: ProjectSerializer.new(@project, options).serialized_json
  #   else
  #     render json: { message: 'Project not found' }, status: :not_found
  #   end
  # end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  # def update
  #   authorize(@project, :admin?)

  #   options = {
  #     params: {
  #       group_id: @project_user.group.hashid,
  #       project_user_id: @project_user.hashid,
  #       permissions: {
  #         isAdmin: @project_user.admin,
  #         addUsersToGroup: @project_user.add_users_to_group,
  #         removeUserFromGroup: @project_user.remove_user_from_group,
  #         isViewIndex: @project_user.view_index,
  #         paid: @project.paid,
  #         status: @project.status
  #       }
  #     }
  #   }

  #   if @project.update(update_project_params)
  #     render json: ProjectSerializer.new(@project, options).serialized_json
  #   else
  #     render json: { errors: @project.errors.messages },
  #            status: :unprocessable_entity
  #   end
  # end

  # DELETE /v1/projects/:hashid
  def destroy
    # authorize(@project, :admin?)
    
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
    puts "find_project"
    @project = @current_user.projects_with_access.find(params[:id])
    
    head(:no_content) unless @project.present?
  end
  
  def find_project_user
    puts "find_project_user"
    @project_user = @project.project_users.find_by(user_id: @current_user.id)

    render(json: { message: 'Project access is denied' }, status: :forbidden) if @project_user.nil?
  end

  def create_project_params
    params.require(:project).permit(:name, :description, :user_id)
  end

  def update_project_params
    params
      .require(:project)
      .permit(:name, :description, :cover, :logo, :paid, :status)
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
