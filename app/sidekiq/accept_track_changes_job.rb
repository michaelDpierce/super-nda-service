
# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

require "tempfile"

class AcceptTrackChangesJob
  include Sidekiq::Job

  def perform(directory_file_id)
    directory_file = DirectoryFile.find(directory_file_id)
    token = obtain_bearer_token

    file_blob = directory_file.file.blob
    file_path = download_blob_to_tempfile(file_blob)
    processed_file_path = upload_and_process_file(file_path, token)

    attach_processed_file(directory_file, processed_file_path)

    # RepairDocxJob.perform_async(directory_file_id)

    File.delete(file_path) if File.exist?(file_path)
    File.delete(processed_file_path) if File.exist?(processed_file_path)
  end

  private

  def obtain_bearer_token
    client_id = "1523ba84-557d-4eb7-b5f0-e841c4d93baf"
    client_secret = "5b23faa0a9812c607b2d82b03aecc578"

    auth_url = "https://api.aspose.cloud/connect/token"

    response = Faraday.post(auth_url) do |req|
      req.headers["Content-Type"] = "application/x-www-form-urlencoded"
      req.body = {
        grant_type: "client_credentials",
        client_id: client_id,
        client_secret: client_secret
      }
    end

    if response.success?
      JSON.parse(response.body)["access_token"]
    else
      raise "Failed to obtain access token"
    end
  end

  def download_blob_to_tempfile(blob)
    tempfile = Tempfile.new(blob.filename.to_s)
    tempfile.binmode
    tempfile.write(blob.download)
    tempfile.close
    tempfile.path
  end

  def upload_and_process_file(file_path, token)
    url = "https://api.aspose.cloud/v4.0/words/online/put/revisions/acceptAll?destfilename=result.docx"
    
    conn = Faraday.new do |faraday|
      faraday.request :multipart
      faraday.adapter Faraday.default_adapter
    end

    payload = { 
      file: Faraday::UploadIO.new(
        file_path,
        "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
      )
    }
    
    response = conn.put(url, payload) do |req|
      req.headers["Authorization"] = "Bearer #{token}"
      req.headers["Content-Type"] = "multipart/form-data"
    end

    if response.success?
      processed_tempfile = Tempfile.new(["result", ".docx"])
      processed_tempfile.binmode
      processed_tempfile.write(response.body)
      processed_tempfile.close
      processed_tempfile.path
    else
      raise "Failed to process file"
    end
  end

  def attach_processed_file(directory_file, file_path)
    directory_file.accepted_changes_file.attach(
      io: File.open(file_path),
      filename: "processed_#{directory_file.file.filename}",
      content_type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'
    )
  end
end