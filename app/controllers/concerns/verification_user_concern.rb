# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

module VerificationUserConcern
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_request!

    def current_user
      @current_user
    end

    def token_payload
      @token_payload
    end
  end

  private

  def authenticate_request!
    return head(:unauthorized) if token.nil?
    sdk = Clerk::SDK.new
    payout = sdk.decode_token(token)

    user = User.find_by(source_id: payout['sub'])

    @current_user =
      if user
        user
      else
        Rails.logger.info "User Not Found: #{payout['sub']}"

        service = AuthService.new
        service.find_or_create_user_by(token: token, ip: request&.remote_ip)
        service.result
      end
        
    Current.user = @current_user

    head(:unauthorized) if @current_user.nil?
  end

  def token
    @token ||= request.headers['Authorization']&.split(' ')&.last
  end
end
