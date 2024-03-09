# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ApplicationController < ActionController::API
  before_action :set_paper_trail_whodunnit

  def info_for_paper_trail
    super.merge({ ip_address: request&.remote_ip, user_agent: request&.user_agent })
  end

  def user_for_paper_trail
    Current.user ? Current.user.try(:id)&.to_s : "Guest"
  end
end
