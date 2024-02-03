# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::DirectoryFilesController < V1::BaseController
  before_action :find_directory_file!, only: %i[update]
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
            filename: file.original_filename,
            created_at: Time.now,
            updated_at: Time.now,
            display_date: Time.now
          )

        directory_file.file.attach(file)
        directory_file.save!

        MetaDataJob.perform_async(directory_file.try(:id), @current_user.id)
      end

      render json: { message: "Success" }, status: :ok
    else
      render json: { message: 'Failure' }, status: :bad_request
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    if @directory_file.update(directory_file_params)
      render json: @directory_file.to_json, status: :ok
    else
      render json: { errors: @directory_file.errors.messages },
             status: :unprocessable_entity
    end
  end

  private

  def directory_file_params
    params.require(:directory_file)
      .permit(:directory_id, :filename, :display_date, :tag_list, :tag_list => [])
  end

  def find_directory_file!
    @directory_file = DirectoryFile.find(params[:id])
  end

  def find_project!
    @project = Project.find(params[:project_id])
  end

  def find_directory!
    @directory = Directory.find(params[:directory_id])
  end
end
