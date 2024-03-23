# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectStatsJob
  include Sidekiq::Job

  def perform(project_id)
    Rails.logger.info "ProjectStatsJob: #{project_id}"

    project = Project.find_by(id: project_id)

    return unless project

    last_document_ids = Document.joins(:group)
                            .where(groups: {project_id: project.id})
                            .select('MAX(documents.id) as last_document_id')
                            .group('groups.id')
                            .pluck(:last_document_id)

    counts = Document.where(id: last_document_ids)
                    .group(:owner)
                    .count

    project.update(
      party_count: counts.fetch('party', 0),
      counter_party_count: counts.fetch('counter_party', 0)
    )
  end
end