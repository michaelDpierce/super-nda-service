# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class LastLoginJob
  include Sidekiq::Job

  def perform(user_id)
    Rails.logger.info "user_id: #{user_id}"

    user = User.find(user_id)

    if user.blank?
      Rails.logger.info "User not found"
      return
    end

    if user.last_login.nil? || Time.now - user.last_login >= 5.minutes
      user.last_login = Time.now
      user.save!
      
      Rails.logger.info "User #{user_id} last_login updated"
    else
      Rails.logger.info "User #{user_id} last_login not updated as it was updated less than 5 minutes ago"
    end
  end
end