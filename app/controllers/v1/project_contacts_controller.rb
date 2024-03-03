# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::ProjectContactsController < V1::BaseController
  before_action :load_project!, only: %i[index]
  before_action :load_project_user!, only: %i[index]
  before_action :find_project_contact, only: %i[update destroy]

   # GET /v1/projects/:hashid/project_contacts
  def index
    render(
      json:
        ProjectContactsSerializer.new(
          @project.project_contacts,
          includes: :contact
        ).serializable_hash.merge(meta: { admin: @project_user.admin? }),
      status: :ok
    )
  end

  # PUT /v1/project_contacts/:hashid
  def update    
    if @project_contact.update(update_project_contact_params)
      render(
        json: { message: "Success"},
        status: :ok
      )
    else
      render(
        json: { errors: @project_contact.errors.messages },
        status: :unprocessable_entity
      )
    end
  end

  # DELETE /v1/project_contacts/:id/
  def destroy
    @project_contact.destroy!

    head(:no_content)
  end

  private

  def load_project!
    @project = Project.find(params[:project_id])
  end

  def load_project_user!
    @project_user = ProjectUser.find_by(project_id: @project.id, user_id: @current_user.id)
  end

  def find_project_contact
    @project_contact = ProjectContact.find(params[:id])
  end

  def update_project_contact_params
    params
      .require(:project_contact)
      .permit(%i[id project_id contact_id role])
  end
end
