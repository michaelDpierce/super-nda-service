# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::DirectoryFilesController < V1::BaseController
  before_action :find_directory_file!, only: %i[update destroy]
  before_action :find_project!, only: %i[upload]
  before_action :find_directory!, only: %i[upload]

  # POST /v1/upload
  def upload
    if params[:files]
      records = Array.new

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

        records.push(format_file(directory_file))

        MetaDataJob.perform_async(directory_file.try(:id), @current_user.id)

        if directory_file.docx_file?
          ConvertFileJob.perform_async(directory_file.try(:id), @current_user.id)
        end
      end

      render json: { data: records, message: 'Success' }, status: :ok
    else
      render json: { message: 'Failure' }, status: :bad_request
    end
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    if @directory_file.update(directory_file_params)
      render json: @directory_file.to_json, status: :ok
      # Render JSON that matches record model
    else
      render json: { errors: @directory_file.errors.messages },
             status: :unprocessable_entity
    end
  end

  def destroy
    @directory_file.destroy!
    head(:no_content)
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

  def format_file(record)
    filename = record.filename.to_s 
    extension = File.extname(filename).to_s
    clean_filename = File.basename(filename, extension).to_s

    url = if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(
        record.file,
        host: 'http://localhost:3001'
      )
    else
      record.file.url(expires_in: 60.minutes)
    end

    {
      hashid: record.hashid,
      key: "file-#{record.hashid}",
      name: filename,
      cleanFilename: clean_filename,
      date: record.try(:display_date),
      extension: extension,
      type: 'file',
      url: url,
      tags: []
    }
  end
end
