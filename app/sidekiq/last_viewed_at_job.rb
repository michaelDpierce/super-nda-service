# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class LastViewedAtJob
  include Sidekiq::Job

  def perform(project_user_id)
    Rails.logger.info "project_user_id: #{project_user_id}"

    project_user = ProjectUser.find(project_user_id)

    if project_user.blank?
      Rails.logger.info "ProjectUser not found"
      return
    end

    if project_user.last_viewed_at.nil? || Time.now - project_user.last_viewed_at >= 5.minutes
      project_user.last_viewed_at = Time.now
      project_user.save!

      Rails.logger.info "ProjectUser #{project_user_id} last_viewed_at updated"
    else
      Rails.logger.info "ProjectUser #{project_user_id} last_viewed_at not updated as it was updated less than 5 minutes ago"
    end
  end
end