# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::SharingController < V1::BaseController
  skip_before_action :authenticate_request!

  before_action :verify_group, only: %i[verify_code upload reclaim signing sign]
  before_action :validate_file_presence, only: :upload

  before_action :verify_project, only: %i[verify_project_code create_group]

  # POST /v1/verify_code
  def verify_code
    render json: SharingSerializer.new(@group)
  end

  # POST /v1/verify_project_code
  def verify_project_code
    render json: ProjectSerializer.new(@project)
  end

  # POST /v1/upload
  def upload
    document = create_document_from_file(params[:file])

    update_group_status_if_negotiating(document)
    
    render json: SharingSerializer.new(@group)
  end

  # POST /v1/reclaim
  def reclaim
    last_document_id = @group.last_document_id

    document = @group.documents.create!(
      owner: params["owner"],
      project_id: @group.project_id,
      group_status_at_creation: @group.status
    )

    filename = document.generate_reclaimed_filename(last_document_id)
  
    new_blob = @group.project.duplicate_version_blob(last_document_id, filename)
    
    document.file.attach(new_blob)
    document.save!
  
    update_group_status_if_negotiating(document)

    render json: SharingSerializer.new(@group)
  end

  # POST /v1/signing
  def signing
    last_document_id = @group.last_document_id

    new_document =
      @group.documents.create!(
        owner:      nil, # No owner until Party or Counterparty signs
        project_id: @group.project_id,
        group_status_at_creation: :signing
      )

    # filename = document.generate_sanitized_filename
    # new_blob = project.create_template_blob(filename)
  
    # document.file.attach(new_blob)
    # document.save!

    ConvertFileJob.perform_async(last_document_id, new_document.id)

    @group.update!(status: :signing) # Tracking the lifecycle of the group

    render json: SharingSerializer.new(@group)
  end

  def sign
    last_document = @group.last_document
  
    last_document.update!(
      counter_party_full_name: params["full_name"],
      counter_party_email:     params["email"],
      counter_party_date:      params["date"],
      counter_party_ip:        request.remote_ip,
      counter_party_user_agent: request.user_agent
    )

    signature_data    = params[:signature]
    decoded_signature = Base64.decode64(signature_data.split(',')[1])

    temp_file = Tempfile.new(["signature", ".png"])
    temp_file.binmode
    temp_file.write(decoded_signature)
    temp_file.rewind

    last_document.counter_party_signature.attach(
      io: temp_file,
      filename: "signature.png",
      content_type: "image/png"
    )

    # Mark as complete if both parties have signed
    if last_document.party_date.present? && last_document.counter_party_date.present?
      last_document.update!(owner: nil)
      @group.update!(status: :complete) # Tracking the lifecycle of the group
    else
      last_document.update!(owner: :party) # Assign back to party if counterparty signs or party needs to sign
      @group.update!(status: :signing) # Tracking the lifecycle of the group
    end

    render json: SharingSerializer.new(@group)
  end

  # POST /v1/create_group
  def create_group
    email      = params["email"]
    domain     = email.split('@').last
    group_name = domain.gsub(/\s+/, "").downcase

    existing_group = @project.groups.find_by(name: group_name)
  
    if existing_group
      render json: {
        message: "Group already exists.",
        group: GroupsSerializer.new(existing_group, {})
      }, status: :ok
    else
      new_group = @project.groups.create(
        name:       group_name,
        project_id: @project.id,
        user_id:    nil, # Anonymous user
        code:       SecureRandom.random_number(100000..999999).to_s,
        status:     :queued
      )

      new_group.update!(status: :sent) # Tracking the lifecycle of the group

      document =
        new_group.documents.create!(
          owner:      :counter_party,
          project_id: new_group.project_id,
          group_status_at_creation: new_group.status
        )

      filename = document.generate_sanitized_filename
      new_blob = @project.create_template_blob(filename)
    
      document.file.attach(new_blob)
      document.save!

      new_group.update!(status: :negotiating) # Tracking the lifecycle of the group

      if new_group.persisted?
        render json: {
          message: "Group created successfull.",
          group: GroupsSerializer.new(new_group, {})
        }, status: :created
      else
        render json: {
          error: "Failed to create group: #{new_group.errors.full_messages.join(", ")}"
        }, status: :unprocessable_entity
      end
    end
  end

  def create_analytic
    render_unauthorized_access unless params[:id].present?

    group    = Group.find(params[:id])
    document = Document.find(params[:document_id])

    DocumentAnalytic.create!(
      project_id: group.project_id,
      group_id: group.id,
      document_id: document.id,
      version_number: document.version_number,
      action_type: params[:action_type],
      counter_party_ip: request.remote_ip,
      counter_party_user_agent: request.user_agent
    )

    render json: { message: "Success", action: params[:action_type] }, status: :ok
  end

  private

  def verify_group
    render_unauthorized_access unless params[:id].present? && params[:code].present?

    numeric_id = Group.decode_id(params[:id])
    @group = Group.find_by!(id: numeric_id, code: params[:code])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized_access
  end

  def verify_project
    render_unauthorized_access unless params[:id].present? && params[:code].present?
    numeric_id = Project.decode_id(params[:id])

    @project = Project.find_by!(id: numeric_id, code: params[:code])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized_access
  end

  def validate_file_presence
    render json: { message: "Failure" }, status: :bad_request unless params[:file].present?
  end

  def create_document_from_file(file)
    document =
      @group.documents.create!(
        owner: :party,
        project_id: @group.project_id,
        group_status_at_creation: @group.status
      )

    filename = document.generate_sanitized_filename
    new_blob = @group.project.create_template_blob(filename)
  
    document.file.attach(new_blob)
    document.save!
    document
  end

  def update_group_status_if_negotiating(document)
    @group.update!(status: :negotiating) if document.version_number > 1
  end

  def render_success(data)
    render json: { data: data, message: "Success" }, status: :ok
  end

  def render_unauthorized_access
    render json: { error: "Unauthorized Access." }, status: :unauthorized
  end
end