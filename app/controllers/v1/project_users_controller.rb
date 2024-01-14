# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ProjectUsersController < V1::BaseController
  before_action :find_project_user, only: %i[update destroy toggle_pinned]

  def index
    project_ids = @current_user.projects_with_access.pluck(:project_id)

    @resource = Project.where(id: project_ids)

    render_resource(
      @resource,
      ProjectsSerializer,
      {}
    )
  end

  # POST /v1/project_users
  def create    
    service = ImportUsersService.new(
      @current_user, @project, [create_project_user_params], request&.remote_ip
    )

    service.call

    render(
      json: service.result,
      status: service.result[:errors] ? :unprocessable_entity : :created
    )
  end

  # PUT /v1/project_users/:hashid/pinned
  def toggle_pinned
    if params[:pinned] == true
      @project_user.pinned = true
      @project_user.pinned_at = Time.now
    else
      @project_user.pinned = false
      @project_user.pinned_at = nil
    end

    @project_user.save(validate: false)

    render(json: { pinned: @project_user.pinned }, status: :ok)
  end

  # PUT /v1/project_users/:hashid
  def update    
    if @project_user.update(update_project_user_params)
      render(
        json: @project_user.to_serialized_json,
        status: :ok
      )
    else
      render(
        json: { errors: @project_user.errors.messages },
        status: :unprocessable_entity
      )
    end
  end

  # DESTROY /v1/projects/:project_id/project_users/:id/
  def destroy
    @project_user.destroy!

    head(:no_content)
  end

  # GET /v1/project_users/pinned
  def pinned
    user_id = @current_user.try(:id)

    options = {params: {user_id: user_id}}
    resource = paginate(@projects, options)

    render(json: PinnedProjectsSerializer.new(resource, options).serialized_json)
  end

  # GET /v1/project_users/stats
  def stats
    render(json: DashboardStats.new(@current_user).run)
  end

  # GET /v1/projects/:project_id/project_users/email
  # def email
  #   authorize(@project, :access?)
    
  #   email = (params[:email] || '').strip.downcase
  #   exists = false
  #   if email.present?
  #     exists =
  #       @project.project_users
  #         .includes(:user)
  #         .references(:user)
  #         .where('LOWER(users.email) = ?', email)
  #         .exists?
  #   end

  #   render(json: { exists: exists })
  # end

  private

  def find_project_user
    @project_user = ProjectUser.find(params[:id])
  end

  def create_project_user_params
    params
      .require(:project_user)
      .permit(%i[email name])
  end

  def update_project_user_params
    params
      .require(:project_user)
      .permit(%i[id access])
  end
end
