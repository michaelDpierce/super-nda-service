# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

class V1::AuthController < V1::BaseController
  skip_before_action :authenticate_request!

  # GET /v1/auth
  def create
    service = AuthService.new
    service.find_or_create_user_by(token: params[:token], ip: request&.remote_ip)

    render(json: service.result, status: service.status)
  end
end
