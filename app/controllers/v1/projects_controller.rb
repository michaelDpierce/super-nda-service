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
    ]

  # GET /v1/projects[.json/.csv]
  def index
    base_filtering!
  
    project_ids =
      ProjectUser.where(user_id: @current_user.id)
        .pluck(:project_id)
  
    @projects = @resource.where(id: project_ids).includes(:user)
  
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
    groups = @project.groups.includes(:user)

    data = CSV.generate(headers: true) do |csv|
      base_url = "#{ENV['SERVER_PROTOCOL']}://#{ENV['SERVER_HOST']}/sharing"

      csv << [
        "Name",
        "Status",
        "Owner Name",
        "Owner Email",
        "Code",
        "URL",
        "Share Link",
        "ID",
        "Created At",
        "Updated At",
        "Notes"
      ]

      groups.each do |group|
        share_link = "#{base_url}/#{group.hashid}?code=#{group.code}"

        csv << [
          group.name,
          group.status&.titleize,
          group.user.try(:full_name),
          group.user.try(:email),
          group.code.to_s,
          "#{base_url}/#{group.hashid}",
          share_link,
          group.hashid,
          group.created_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          group.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          group.notes
        ]
      end
    end

    send_data data, filename: "Groups.csv", type: "text/csv"
  end

  # POST /v1/projects/:hashid/create_project_user
  def create_project_user
    ActiveRecord::Base.transaction do
      email = params["data"]["email"]
  
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
    existing_count = existing_group_names.length
  
    new_group_names = group_names - existing_group_names
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
  
    begin
      @project.groups.insert_all(new_groups) if new_groups.any?
      created_count = new_groups.length
  
      total_count = @project.groups.count
  
      render json: {
        total_groups: total_count,
        new_groups_created: created_count,
        existing_groups: existing_count,
        groups:
          GroupsSerializer.new(
            @project.groups.includes(:user), {}
          )
      }, status: :created
    rescue => e
      render json: { 
        error: "Failed to create groups: #{e.message}"
      }, status: :unprocessable_entity
    end
  end

  def groups
    groups =
      @project.groups.eager_load(:last_document)

    sorted_groups = groups.sort_by do |g|
      g.last_document&.created_at || Time.now
    end

    serialized_groups = GroupsSerializer.new(sorted_groups).serializable_hash
    stats             = @project.stats
    
    render json: serialized_groups.merge(stats: stats), status: :ok
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
      .permit(:name, :description, :status, :action, :logo, :template)
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

    @resource = @resource.includes(:project_users, :users)
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
        'Updated At'
      ]

      projects.each do |project|
        start_date = project.start_date.strftime("%Y-%m-%d %H:%M:%S %Z")
        end_date   = project.end_date ? project.end_date.strftime("%Y-%m-%d %H:%M:%S %Z") : 'Current'

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
          project.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z")
        ]
      end
    end
  end
end
