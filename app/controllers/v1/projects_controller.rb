# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

require "csv"
require "securerandom"

class V1::ProjectsController < V1::BaseController
  before_action :find_project,
    only: %i[
      show
      update
      destroy
      export_groups
      create_project_user
      create_groups
      groups
      stats
    ]

  before_action :find_project_user,
    only: %i[
      show
      update
      destroy
      export_groups
      create_project_user
      create_groups
      groups
      stats
    ]

  # GET /v1/projects[.json/.csv]
  def index
    base_filtering!
  
    project_ids =
      ProjectUser.where(user_id: @current_user.id)
        .pluck(:project_id)
  
    @projects =
      @resource.where(id: project_ids)
        .includes(:project_users, :users, :groups)
        .with_attached_template

    respond_to do |format|
      format.json do
        render json:
          ProjectsSerializer.new(@projects, {}).serializable_hash,
          status: :ok
      end

      format.csv do
        send_projects_csv(@projects)
      end
    end
  end

  # POST /v1/projects
  def create
    service =
      CreateProjectService.new(
        @current_user,
        create_project_params
      )

    service.call
    render(json: service.result, status: service.status)
  end

  # GET /v1/projects/:hashid
  def show
    options = {
      params: {
        permissions: {
          admin: @project_user.try(:admin)
        },
        meta: {
          current_user_id: @current_user.try(:id),
          project_user_id: @project_user.try(:hashid),
          status: @project.try(:status)
        }
      },
    }

    if @project.present?
      LastViewedAtJob.perform_async(@project_user.id)

      render json: ProjectSerializer.new(@project, options)
    else
      render json: { message: "Project not found." }, status: :not_found
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    was_not_archived  = !@project.archived?
    was_not_completed = !@project.completed?

    options = {
      params: {
        permissions: {
          isAdmin: @project_user.try(:admin)
        },
        meta: {
          current_user_id: @current_user.try(:id),
          project_user_id: @project_user.try(:hashid),
          status: @project.try(:status)
        }
      },
    }

    if params[:project][:logo] === 'null'
      @project.logo.purge
      params[:project].delete(:logo)
    else
      @project.logo.attach(params[:project][:logo])
    end

    if @project.update(update_project_params)
      if was_not_archived && @project.archived?
        ProjectArchiveJob.perform_async(@project.id)
      end

      if was_not_completed && @project.completed?
        @project.end_date = Time.current
      elsif !@project.completed?
        @project.end_date = nil
      end

      @project.save!

      render json: ProjectSerializer.new(@project, options)
    else
      render json: { errors: @project.errors.messages }, status: :unprocessable_entity
    end
  end

  # DELETE /v1/projects/:hashid
  def destroy
    @project.destroy!
    head(:no_content)
  end

  # GET /v1/search
  def search
    service = 
      SearchService.new(
        @current_user.id,
        { q: params[:q] },
        params[:limit] || 10
      )
  
    render(json: { result: service.result, status: service.status })
  end

  # GET /v1/projects/:hashid/export_groups.csv
  def export_groups
    groups            = @project.groups.includes(:user).order(:passed, :name)
    last_document_ids = groups.pluck(:last_document_id).compact
    last_documents    = Document.where(id: last_document_ids)

    data = CSV.generate(headers: true) do |csv|
      base_url = "#{ENV['SERVER_PROTOCOL']}://#{ENV['SERVER_HOST']}/sharing"

      csv << [
        "Counterparty Name",
        "Status",
        "Process Status",
        "Passed",
        "Last Interaction",
        "Version",
        "Share Link",
        "URL",
        "Code",
        "ID",
        "Document Unique ID",
        "Created At",
        "Updated At",
        "Owner Name",
        "Owner Email",
        "Notes"
      ]

      groups.each do |group|
        last_document = last_documents.find_by(id: group.last_document_id)
        share_link = "#{base_url}/#{group.hashid}?code=#{group.code}"
        
        status         = group.status
        process_status = group.process_status.present? ? group.process_status : '-'
        passed         = group.passed ? "Passed" : "Active"

        owner          = last_document&.owner

        formatted_status =
          if status === 'queued'
            'Queued'
          elsif status === 'sent'
            'NDA Sent'
          elsif status === 'negotiating' && owner === 'party'
            'Redline Returned'
          elsif status === 'negotiating' && owner === 'counter_party'
            'Redline Sent'
          elsif status === 'signing' && owner === nil
            'Ready to Sign'
          elsif status === 'signing' && owner === 'party'
            'Sign NDA'
          elsif status === 'signing' && owner === 'counter_party'
            'Awaiting Signature'
          elsif status === 'complete'
            'Signed/Complete'
          else
            '-'
          end

        version = 
          if last_document&.version_number.present?
            "V#{last_document&.version_number}"
          else
            "V0"
          end

        csv << [
          group.name,
          formatted_status,
          process_status,
          passed,
          last_document&.created_at&.strftime("%Y-%m-%d %H:%M:%S %Z") || '-',
          version,
          share_link,
          "#{base_url}/#{group.hashid}",
          group.code.to_s,
          group.hashid,
          last_document&.hashid || '-',
          group.created_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          group.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          group.user.try(:full_name),
          group.user.try(:email),
          group.notes
        ]
      end
    end

    send_data data, filename: "Groups.csv", type: "text/csv"
  end

  # POST /v1/projects/:hashid/create_project_user
  def create_project_user
    ActiveRecord::Base.transaction do
      email = params["data"]["email"].downcase
  
      existing_project_user =
        ProjectUser.joins(:user)
          .find_by(users: {email: email}, project_id: @project.id)
      
        if existing_project_user.present?
          render(
            json: {
              error: 'A user with that email already exists in this project.'
            },
            status: :unprocessable_entity
          )
          
          return
        end
      user = User.find_or_create_by!(email: email) do |user|
        user.first_name = params["data"]["first_name"] if params["data"]["first_name"].present?
        user.last_name  = params["data"]["last_name"]  if params["data"]["last_name"].present?
      end
    
      project_user =
        ProjectUser.create!(
          user_id: user.id,
          project_id: @project.id,
          admin: params["data"]["admin"],
          access: params["data"]["access"]
        )
  
      render(
        json: ProjectUsersSerializer.new(project_user, includes: :user),
        status: :created
      )
    end
  rescue ActiveRecord::RecordInvalid => e
    render(json: { error: e.message }, status: :unprocessable_entity)
  end

  # POST /v1/projects/:hashid/create_groups
  def create_groups
    group_names = params["data"]["group_names"].split(",")
    existing_group_names = @project.groups.where(name: group_names).pluck(:name)
    new_group_names = group_names - existing_group_names
  
    # Step 1: Prepare data for new groups, assuming each has a unique name or other unique attributes
    new_groups = new_group_names.map do |name|
      {
        name: name,
        project_id: @project.id,
        user_id: @current_user.id,
        code: SecureRandom.random_number(100000..999999).to_s,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  
    # Bulk Insert Groups
    @project.groups.insert_all(new_groups)
  
    # Step 2: Retrieve newly inserted groups to capture their IDs
    # This assumes 'name' is unique enough to identify them; adjust as needed for your case
    inserted_groups = @project.groups.where(name: new_group_names).pluck(:id, :name)
  
    # Step 3: Prepare version data for each inserted group
    version_data = inserted_groups.map do |id, name|
      {
        item_type: 'Group',
        item_id: id,
        event: 'create',
        whodunnit: @current_user.id.to_s,
        object: nil,
        created_at: Time.current,
        ip_address: request.remote_ip,
        user_agent: request.user_agent
      }
    end
  
    # Bulk Insert Version Records
    # PaperTrail::Version.insert_all(version_data)
    Version.insert_all(version_data)

    total_count = @project.groups.count
    created_count = new_group_names.length
  
    render json: {
      total_groups: total_count,
      new_groups_created: created_count,
      existing_groups: existing_group_names.length,
      groups: GroupsSerializer.new(@project.groups.includes(:user), {}).serializable_hash
    }, status: :created
  rescue => e
    render json: { 
      error: "Failed to create groups: #{e.message}"
    }, status: :unprocessable_entity
  end

  def groups
    # Separate groups into passed: false and passed: true
    groups_not_passed = @project.groups.eager_load(:last_document)
                      .where(passed: false)
                      .sort_by { |g| g.last_document&.created_at || Time.now }

    groups_passed = @project.groups.eager_load(:last_document)
                    .where(passed: true)
                    .sort_by { |g| g.last_document&.created_at || Time.now }

    # Combine the two sorted sets of groups
    sorted_groups = groups_not_passed + groups_passed

    serialized_groups = GroupsSerializer.new(sorted_groups).serializable_hash

    stats             = @project.stats
    
    render json: serialized_groups.merge(stats: stats), status: :ok
  end

  def stats
    render json: @project.stats, status: :ok
  end

  private

  def find_project
    @project = @current_user.projects_with_access.find(params[:id])
    head(:no_content) unless @project.present?
  end
  
  def find_project_user
    @project_user = @project.project_users.find_by(user_id: @current_user.id)

    if @project_user.nil?
      render(json: { message: "Project access is denied." }, status: :forbidden)
    end
  end

  def create_project_params
    params.require(:project).permit(:name, :description, :user_id, :template)
  end

  def update_project_params
    params
      .require(:project)
      .permit(:name, :description, :status, :action, :logo, :template,
              :authorized_agent_of_signatory_user_id)
      .select { |x,v| v.present? }
  end

  def forbidden
    head(:forbidden)
  end

  def base_filtering!
    load_resource!

    if params[:active].present?
      @resource = @resource.where(status: :active)
    end

    basic_search_resource_by!
    order_resource!

    @resource
  end

  def load_resource!
    @resource = @current_user.projects_with_access
  end

  def order_resource!
    @resource = @resource.order(status: :asc, name: :asc)
  end

  def send_projects_csv(projects)
    csv_data = generate_csv_for(projects)
    send_data csv_data,
              type: 'text/csv; charset=utf-8; header=present',
              filename: "Projects.csv"
  end

  def generate_csv_for(projects)
    CSV.generate(headers: true) do |csv|
      csv << [
        'Name',
        'Description',
        'Owner Name',
        'Owner Email',
        'Status',
        'Start Date',
        'End Date',
        'ID',
        'Created At',
        'Updated At',
        'Total Users',
        'Total Admin Users',
        'Total Groups',
        'Template Attached'
      ]

      projects.each do |project|
        start_date        = project.start_date.strftime("%Y-%m-%d %H:%M:%S %Z")
        end_date          = project.end_date ? project.end_date.strftime("%Y-%m-%d %H:%M:%S %Z") : 'Current'
        total_users       = project.users.count
        total_admin_users = project.admin_users.count
        total_groups      = project.groups.count
        template_attached = project.template.attached? ? 'Y' : 'N'

        csv << [
          project.name,
          project.description.present? ? project.description : '-',
          project.user.try(:full_name),
          project.user.try(:email),
          project.status&.titleize,
          start_date,
          end_date,
          project.hashid,
          project.created_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          project.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          total_users,
          total_admin_users,
          total_groups,
          template_attached
        ]
      end
    end
  end
end
