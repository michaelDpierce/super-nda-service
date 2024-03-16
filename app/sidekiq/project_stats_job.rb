# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectStatsJob
  include Sidekiq::Job

  def perform(project_id)
    Rails.logger.info "ProjectStatsJob: #{project_id}"

    project = Project.find_by(id: project_id)

    return unless project

    counts =
      Document.joins(group: :project)
        .where(groups: {project_id: project.id})
        .group(:owner)
        .count

    project.update(
      party_count: counts.fetch('party', 0),
      counter_party_count: counts.fetch('counter_party', 0)
    )
  end
end