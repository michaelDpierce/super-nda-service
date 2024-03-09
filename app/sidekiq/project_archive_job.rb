# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectArchiveJob
  include Sidekiq::Job

  def perform(project_id)
    project = Project.find_by(id: project_id)

    return unless project

    project.project_users.each do |project_user|
      unless project_user.admin?
        project_user.update(access: false)
      end
    end
  end
end