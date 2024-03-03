# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ProjectUsersController < V1::BaseController
  before_action :load_project!, only: %i[index create]
  before_action :load_project_user, only: %i[index]
  before_action :find_project_user, only: %i[update destroy]

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

  def update_project_user_params
    params
      .require(:project_user)
      .permit(%i[id access admin])
  end
end
