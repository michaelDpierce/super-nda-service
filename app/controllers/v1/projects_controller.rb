# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require "csv"

class V1::ProjectsController < V1::BaseController
  before_action :find_project,
    only: %i[
      show
      update
      destroy
      folder
      tags
      export
      create_project_user
      create_project_contact
      check_admin
    ]

  before_action :find_project_user,
    only: %i[
      show
      update
      destroy
      folder
      tags
      export
      create_project_user
      create_project_contact
      check_admin
    ]

  # GET /v1/projects
  def index
    base_filtering!

    project_ids =
      ProjectUser.where(user_id: @current_user.id)
        .pluck(:project_id)

    @resource = @resource.where(id: project_ids)

    render_resource(
      @resource,
      ProjectsSerializer,
      {}
    )
  end

  # POST /v1/projects
  def create
    service =
      CreateProjectService.new(
        @current_user,
        create_project_params,
        request&.remote_ip
      )

    service.call
    render(json: service.result, status: service.status)
  end

  # GET /v1/projects/:hashid
  def show
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

    if @project.present?
      LastViewedAtJob.perform_async(@project_user.id)

      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { message: "Project not found." }, status: :not_found
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    was_not_archived = !@project.archived?

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

      render json: ProjectSerializer.new(@project, options).serialized_json
    else
      render json: { errors: @project.errors.messages },
             status: :unprocessable_entity
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
      if params[:project_id].present?
        project = @current_user.projects_with_access.find(params[:project_id])

         ProjectSearchService.new(
          params[:q],
          project.id
        )
      else
        SearchService.new(
          @current_user.id,
          { q: params[:q] },
          params[:limit] || 10
        )
      end
  
    render(json: { result: service.result, status: service.status })
  end

  # GET /v1/projects/:hashid/folder/:directory_id
  def folder
    directory_id = if params[:directory_id].present?
      params[:directory_id]
    else
      @project.directories.root.id
    end

    service =
      ProjectFolderService.new(@project, directory_id, @current_user)
      
    render(json: { data: service.data })
  end

  # GET /v1/projects/:hashid/tags
  def tags
    directory_file_ids = @project.directory_files.pluck(:id)

    tag_list = ActsAsTaggableOn::Tag.joins(:taggings)
      .where(taggings: { taggable_id: directory_file_ids, taggable_type: "DirectoryFile" })
      .pluck(Arel.sql("DISTINCT tags.name"))

    render(json: { data: tag_list })
  end

  # GET /v1/projects/:hashid/export
  def export
    dfs = @project.directory_files
    directories = Directory.where(project_id: @project.id)

    data = CSV.generate(headers: true) do |csv|
      csv << [
        "Name",
        "Directory",
        "Created At",
        "Updated At",
        "Date",
        "User",
        "Published?",
        "Tags",
        "Committee"
      ]

      dfs.each do |df|
        csv << [
          df.filename,
          directories.find(df.directory_id)&.try(:name),
          df.created_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.updated_at.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.display_date.strftime("%Y-%m-%d %H:%M:%S %Z"),
          df.user.try(:email),
          df.published ? "Y" : "N",
          df.tag_list.join(", ").to_s,
          df.committee
        ]
      end
    end

    send_data data, filename: "report.csv", type: "text/csv"
  end

  # POST /v1/projects/:hashid/create_project_user
  def create_project_user
    ActiveRecord::Base.transaction do
      email = params["data"]["email"]
  
      existing_project_user = ProjectUser.joins(:user).find_by(users: {email: email}, project_id: @project.id)
      if existing_project_user.present?
        render(json: { error: 'A user with that email already exists in this project.' }, status: :unprocessable_entity)
        return
      end
  
      user = User.find_or_create_by!(email: email) do |user|
        user.first_name = params["data"]["firstName"]
        user.last_name = params["data"]["lastName"]
      end
    
      project_user = ProjectUser.create!(user_id: user.id, project_id: @project.id)
  
      render(json: { data: project_user }, status: :created)
    end
  rescue ActiveRecord::RecordInvalid => e
    render(json: { error: e.message }, status: :unprocessable_entity)
  end

  # POST /v1/projects/:hashid/create_project_contact
  def create_project_contact
    ActiveRecord::Base.transaction do
      full_name_lookup = "#{params["data"]["firstName"]}#{params["data"]["lastName"]}"
                          .gsub(/[^A-Za-z0-9]/, '')
                          .downcase
    
      contact = Contact.find_or_create_by!(full_name_lookup: full_name_lookup) do |c|
        c.prefix = params["data"]["prefix"]
        c.first_name = params["data"]["firstName"]
        c.last_name = params["data"]["lastName"]
      end
    
      existing_project_contact =
        ProjectContact.find_by(contact_id: contact.id, project_id: @project.id)
    
      if existing_project_contact.nil?
        role = params["data"]["role"] || nil

        project_contact =
          ProjectContact.create!(
            contact_id: contact.id,
            project_id: @project.id,
            role: role
          )
    
        render(json: { data: project_contact }, status: :created)
      else
        render(json: { error: 'This contact is already associated with the project.' }, status: :unprocessable_entity)
      end
    end
  end

  # GET /v1/projects/:hashid/check_admin
  def check_admin
    render(json: { admin: @project_user.admin? }, status: :ok)
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
    params.require(:project).permit(:name, :description, :user_id)
  end

  def update_project_params
    params
      .require(:project)
      .permit(:name, :description, :logo, :status)
      .select { |x,v| v.present? }
  end

  def forbidden
    head(:forbidden)
  end

  def base_filtering!
    load_resource!

    basic_search_resource_by!
    filter_resource_by_created!

    order_resource!

    @resource = @resource.includes(:project_users)
  end

  def load_resource!
    @resource = @current_user.projects_with_access
  end

  def order_resource!
    return if params[:sort_by].present?

    @resource = @resource.order(created_at: :desc)
  end
end
