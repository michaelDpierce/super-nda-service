# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class LastLoginJob
  include Sidekiq::Job

  def perform(user_id)
    Rails.logger.info "user_id: #{user_id}"

    user = User.find(user_id)
    user.last_login = Time.now
    user.save!
  end
end