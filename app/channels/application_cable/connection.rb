# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    private

    def find_verified_user
      sdk = Clerk::SDK.new
      payout = sdk.decode_token(request.params[:token])

      @current_user = User.find_by!(source_id: payout['sub'])
    rescue StandardError
      reject_unauthorized_connection
    end
  end
end