# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::GroupsController < V1::BaseController
  before_action :find_group, only: %i[update destroy]
  before_action :load_project!, only: %i[update destroy]

  # POST /v1/projects
  def create
    @group            = Group.new(create_group_params)
    @group.project_id = @project.id
    @group.user_id    = @current_user.id

    if @group.save
      render json: GroupsSerializer.new(@group)
    else
      render json: { errors: @group.errors.messages },
             status: :unprocessable_entity
    end
  end

  # PUT /v1/groups/:hashid
  # PATCH /v1/groups/:hashid
  def update
    if @group.update(update_group_params)
      render json: GroupsSerializer.new(@group)
    else
      render json: { errors: @group.errors.messages },
             status: :unprocessable_entity
    end
  end

  # DELETE /v1/groups/:hashid
  def destroy    
    @group.destroy!
    head(:no_content)
  end

  private

  def find_group
    @group = Group.find(params[:id])
    head(:no_content) unless @group.present?
  end

  def load_project!
    @project = Project.find(@group.project_id)
  end

  def update_group_params
    params
      .require(:group)
      .permit(:name, :status, :notes)
      .select { |x,v| v.present? }
  end
end
