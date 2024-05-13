# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ProjectsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project

  attribute :name,
            :description,
            :status,
            :start_date,
            :end_date,
            :party_count,
            :counter_party_count

  attribute :user do |object|
    {
      full_name: object.user.try(:full_name_reverse) || '-',
    }
  end
end 