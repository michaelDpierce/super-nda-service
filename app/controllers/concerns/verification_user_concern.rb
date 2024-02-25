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

    @current_user = User.find_by!(source_id: payout["sub"])

    Current.user = @current_user

    LastLoginJob.perform_async(@current_user.id) if @current_user.present?

    head(:unauthorized) if @current_user.nil?
  end

  def token
    @token ||= request.headers["Authorization"]&.split(" ")&.last
  end
end
