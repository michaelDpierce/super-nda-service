# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::GroupsController < V1::BaseController
  before_action :find_group, only: %i[show update destroy upload change_owner sign]
  before_action :load_project!, only: %i[update destroy upload change_owner sign]

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
  # TODO do we want to be able to push to signing from here?
  def update
    current_status = @group.status

    if @project.template.attached?  
      if @group.update(update_group_params)
        # Changing from one Status to another
        if current_status == 'queued' && @group.status == 'sent'
          Rails.logger.info "Group status change from Queued to Sent"
          create_new_document(@group, :counter_party)
        elsif current_status == 'signing' && @group.status == 'negotiating'
          Rails.logger.info "Group status change from Signing to Negotiating"
          create_new_document(@group, :party)
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
        end 
    
        render json: GroupsSerializer.new(@group)
      else
        render json: { errors: @group.errors.messages }, status: :unprocessable_entity
      end
    else
      render json: { errors: 'A NDA template must be associated with the Project to send NDA to Groups. Please add a template in Project Settings.' },
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

  # POST /v1/groups/:hashid/change_owner?owner=party/counter_party&status=negotiating/signing
  def change_owner
    last_document_id = @group.last_document_id

    document = @group.documents.create!(owner: params['owner'], project_id: @group.project_id)
    filename = document.generate_reclaimed_filename(last_document_id)
  
    new_blob = @project.duplicate_version_blob(last_document_id, filename)
    
    document.file.attach(new_blob)
    document.save!
  
    @group.update!(status: params['status'])
  
    render json: { message: "Success" }, status: :ok
  end

  # GET /v1/groups/:hashid/sign
  def sign
    last_document = @group.last_document
  
    last_document.update!(
      party_full_name: @current_user.full_name,
      party_email: @current_user.email,
      party_date: Time.now,
      party_ip: request.remote_ip,
      party_user_agent: request.user_agent
    )

    @group.update!(status: :signing) # Tracking the lifecycle of the group

    if last_document.party_date && last_document.counter_party_date
      @group.update!(status: :complete)
      last_document.update!(owner: nil) # Both parties have signed

      job_id = CompleteNdaJob.perform_async(last_document.id, @current_user.id)
      Rails.logger.info "Queued CompleteNDAJob for document_id: #{last_document.id} with job_id: #{job_id}"
    elsif last_document.party_date && !last_document.counter_party_date
      last_document.update!(owner: :counter_party) # Set back to Counter Party Owned
    end

    render json: GroupsSerializer.new(@group)
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

  def create_new_document(group, owner)
    document =
      group.documents.create!(owner: owner, project_id: group.project_id)
  
    filename = document.generate_sanitized_filename
    new_blob = @project.create_template_blob(filename)

    document.file.attach(new_blob)
    document.save!
  end
end
