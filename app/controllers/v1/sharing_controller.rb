class V1::SharingController < V1::BaseController
  skip_before_action :authenticate_request!
  before_action :verify_group, only: %i[verify_code upload reclaim]
  before_action :validate_file_presence, only: :upload

  # POST /v1/verify_code
  def verify_code
    render json: SharingSerializer.new(@group)
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

    document = @group.documents.create!(owner: params['owner'], project_id: @group.project_id)
    filename = document.generate_reclaimed_filename(last_document_id)
  
    new_blob = @group.project.duplicate_version_blob(last_document_id, filename)
    
    document.file.attach(new_blob)
    document.save!
  
    update_group_status_if_negotiating(document)

    render json: SharingSerializer.new(@group)
  end

  private

  def verify_group
    render_unauthorized_access unless params[:id].present? && params[:code].present?

    numeric_id = Group.decode_id(params[:id])
    @group = Group.find_by!(id: numeric_id, code: params[:code])
  rescue ActiveRecord::RecordNotFound
    render_unauthorized_access
  end

  def validate_file_presence
    render json: { message: "Failure" }, status: :bad_request unless params[:file].present?
  end

  def create_document_from_file(file)
    document =
      @group.documents.create!(owner: :party, project_id: @group.project_id)

    filename = document.generate_sanitized_filename
    new_blob = @group.project.create_template_blob(filename)
  
    document.file.attach(new_blob)
    document.save!
    document
  end

  def update_group_status_if_negotiating(document)
    @group.update!(status: :negotiating) if document.version_number > 1
  end

  def render_success(document)
    render json: { data: document, message: "Success" }, status: :ok
  end

  def render_unauthorized_access
    render json: { error: "Unauthorized Access." }, status: :unauthorized
  end
end