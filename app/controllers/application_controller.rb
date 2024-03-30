# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ApplicationController < ActionController::API
  before_action :set_paper_trail_whodunnit

  def info_for_paper_trail
    super.merge({
      ip_address: request&.remote_ip,
      user_agent: request&.user_agent
    })
  end

  def sanitize_filename(filename)
    sanitized = filename.gsub(ALLOWED_FILENAME_CHARS, '')
  
    raise ArgumentError, "Filename is not valid or becomes empty after sanitization." if sanitized.empty?
  
    sanitized
  end
end
