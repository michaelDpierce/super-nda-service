# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectManagementChannel < ApplicationCable::Channel
  def subscribed
    stream_from "project_management_#{params[:id]}"
  end

  def unsubscribed
  end
end