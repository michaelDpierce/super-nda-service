# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class MetaDataJob
  include Sidekiq::Job

  def perform(directory_file_id, user_id)
    puts "MetaDataJob is running..."
    puts "directory_file_id: #{directory_file_id}"
    puts "user_id: #{user_id}"
  end
end