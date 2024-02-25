# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ProjectUsersController < V1::BaseController
  before_action :load_project!, only: %i[index create]
  before_action :load_project_user, only: %i[index]
  before_action :find_project_user, only: %i[update destroy toggle_pinned]

   # GET /v1/projects/:hashid/project_users
  def index
    render(
      json:
        ProjectUsersSerializer.new(
          @project.project_users,
          includes: :user
        ).serializable_hash.merge(meta: { current_user_id: @current_user.hashid, admin: @project_user.admin? }),
      status: :ok
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
        json: { message: "Success"},
        status: :ok
      )
    else
      render(
        json: { errors: @project_user.errors.messages },
        status: :unprocessable_entity
      )
    end
  end

  # DESTROY /v1/project_users/:id/
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

  private

  def load_project!
    @project = Project.find(params[:project_id])
  end

  def load_project_user
    @project_user = ProjectUser.find_by(project_id: @project.id, user_id: @current_user.id)
  end

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
      .permit(%i[id access admin])
  end
end
