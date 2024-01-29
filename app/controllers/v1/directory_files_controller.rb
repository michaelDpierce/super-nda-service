# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::DirectoryFilesController < V1::BaseController
  before_action :find_project!, only: %i[upload]
  before_action :find_directory!, only: %i[upload]

  # POST /v1/upload
  def upload
    if params[:files]
      params[:files].each do |file|
        directory_file =
          DirectoryFile.new(
            directory_id: @directory.id,
            project_id: @project.id,
            user_id: @current_user.id,
            filename: file.original_filename
          )

        directory_file.file.attach(file)
        directory_file.save!
      end

      render json: { message: "Success" }, status: :ok
    else
      render json: { message: 'Failure' }, status: :bad_request
    end
  end

  private

  def find_project!
    @project = Project.find(params[:project_id])
  end

  def find_directory!
    @directory = Directory.find(params[:directory_id])
  end
end