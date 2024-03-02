# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::DirectoryFilesController < V1::BaseController
  before_action :find_directory_file!, only: %i[show update destroy analyze download]
  before_action :find_project!, only: %i[upload download]
  before_action :find_directory!, only: %i[upload]
  before_action :find_project_user!, only: %i[download]

  # GET /v1/directory_file/:hashid
  def show
    render json: format_file(@directory_file).to_json, status: :ok
  end

  # PUT /v1/projects/:hashid
  # PATCH /v1/projects/:hashid
  def update
    if @directory_file.update(directory_file_params)
      new_file = params[:file] if params[:file].present?

      if @directory_file.file.attached? && new_file.present?
        @directory_file.file.attach(new_file)
        @directory_file.save!
  
        MetaDataJob.perform_async(@directory_file.try(:id), @current_user.id)

        if @directory_file.docx_file?
          ConvertFileJob.perform_async(@directory_file.try(:id), @current_user.id)
        end
      end

      render json: @directory_file.to_json, status: :ok
    else
      render json: { errors: @directory_file.errors.messages },
             status: :unprocessable_entity
    end
  end

  # DELETE /v1/directory_file/:hashid
  def destroy
    @directory_file.destroy!
    head(:no_content)
  end

  # GET /v1/directory_files/:hashid/analyze
  def analyze
    AnalyzeMeetingMinutesJob.perform_async(@directory_file.try(:id))
    render json: { message: "Success" }, status: :ok
  end

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

      render json: { data: records, message: "Success" }, status: :ok
    else
      render json: { message: "Failure" }, status: :bad_request
    end
  end

  # GET /v1/directory_file/:hashid/download
  def download
    if @project_user.present?
     file =
      @project_user.admin? ? @directory_file.file : @directory_file.converted_file

      url = if Rails.env.development?
        Rails.application.routes.url_helpers.rails_blob_url(
          file,
          disposition: "attachment",
          host: "http://localhost:3001"
        )
      else
        file.url(disposition: "attachment", expires_in: 60.minutes)
      end

      render json: { url: url }, status: :ok
    else
      render json: { message: "Unauthorized" }, status: :unauthorized
    end
  end

  private

  def directory_file_params
    params.require(:directory_file)
      .permit(:directory_id, :filename, :display_date, :committee, :published,
              :tag_list, :tag_list => [])
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

  def find_project_user!
    @project_user = ProjectUser.find_by(project_id: @project.id, user_id: @current_user.id)
  end

  def format_file(record)
    filename = record.filename.to_s 
    extension = File.extname(filename).to_s
    clean_filename = File.basename(filename, extension).to_s

    url = if Rails.env.development?
      Rails.application.routes.url_helpers.rails_blob_url(
        record.file,
        host: "http://localhost:3001"
      )
    else
      record.file.url(expires_in: 60.minutes)
    end

    {
      hashid: record.hashid,
      key: "file-#{record.hashid}",
      name: filename,
      cleanFilename: clean_filename,
      conversionStatus: record.conversion_status,
      convertedFile: false,
      convertedFileUrl: nil,
      convertedFilename: "",
      date: record.try(:display_date),
      extension: extension,
      type: "file",
      url: url,
      tags: [],
      committee: record.committee,
      supported: record.docx_file? || record.pdf_file?
    }
  end
end
