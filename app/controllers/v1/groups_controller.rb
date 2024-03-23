# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::GroupsController < V1::BaseController
  before_action :find_group, only: %i[show update destroy upload]
  before_action :load_project!, only: %i[update destroy upload]

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
    current_status = @group.status

    if @project.template.attached?  
      if @group.update(update_group_params)
        # Changing from one Status to another
        if current_status == 'queued' && @group.status == 'sent'
          Rails.logger.info "Group status change from Queued to Sent"
          handle_status_change_to_sent(@group)
        elsif current_status == 'sent' && @group.status == 'queued'
          render json: { 
            errors: 'You cannot change the status from Sent back to Queued.'
          }, status: :unprocessable_entity

          return
        end

        # On Status Change
        if @group.status === 'sent'
          Rails.logger.info "Group status change to Sent"

          if @group.last_document.owner === nil
            last_document = @group.last_document.update!(owner: :party)
          end
        elsif @group.status === 'complete' # Manual override to completed vs doing in signing flow
          Rails.logger.info "Group status change to Complete"

          last_document = @group.last_document.update!(owner: nil)
          # last_document.owner = nil
          # last_document.save!
        end 

        ProjectStatsJob.perform_async(@group.project_id) # Rerun counts have party is set to nil

    
        render json: GroupsSerializer.new(@group)
      else
        render json: { errors: @group.errors.messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'A NDA template must be associated with the Project to send to Groups!' },
             status: :unprocessable_entity
    end
  end

  # GET /v1/groups/:hashid/
  def show
    if @group.present?
      render json: GroupSerializer.new(@group, include: [:documents])
    else
      render json: { errors: 'Group not found' }, status: :not_found
    end
  end

  # DELETE /v1/groups/:hashid
  def destroy    
    @group.documents.destroy_all
    @group.destroy!
    head(:no_content)
  end

  # POST /v1/groups/:hashid/upload
  def upload
    document =
      @group.documents.create!(owner: :counter_party, project_id: @group.project_id)

    filename = document.generate_sanitized_filename
    new_blob = @project.create_template_blob(filename)
  
    document.file.attach(new_blob)
    document.save!

    # Ensure that if the party manually uploaded the first document the status is set to negotiating
    @group.update!(status: :negotiating)

    render json: { data: document, message: "Success" }, status: :ok
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

  def handle_status_change_to_sent(group)
    Rails.logger.info "Handling status change to 'sent' for group: #{group.hashid}"
  
    document =
      group.documents.create!(owner: :counter_party, project_id: group.project_id)
  
    filename = document.generate_sanitized_filename
    new_blob = @project.create_template_blob(filename)

    document.file.attach(new_blob)
    document.save!
  end
end
