# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::DirectoriesController < V1::BaseController
  before_action :find_directory!, only: [:create, :update, :destroy]

  # POST /v1/projects/:project_id/directories
  def create
    service =
      CreateDirectoryService.new(
        @project,
        @directory,
        directory_params,
        @current_user
      )
    
    service.call

    render(json: service.result, status: service.status)
  end

  # PUT /v1/projects/:project_id/directories/:hashid
  def update
    service =
      UpdateDirectoryService.new(
        @directory,
        directory_params,
        @current_user
      )

    service.call

    render(json: service.result, status: service.status)
  end

  # DELETE /v1/projects/:project_id/directories/:hashid
  def destroy
    service = DestroyDirectoryService.new(@directory.id)
    service.call

    render(json: service.result, status: service.status)
  end

  private

  def find_project!
    @project = Project.find(params[:project_id])
  end

  def find_directory!
    @directory = Directory.includes([:project]).find(params[:id])
    @project = @directory.project
  end

  def directory_params
    params.require(:directory).permit(:name)
  end
end
