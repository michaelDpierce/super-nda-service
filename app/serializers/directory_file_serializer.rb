# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class DirectoryFileSerializer < ApplicationSerializer
  set_id :hashid
  set_type :directory_file

  attribute :directory_id,
            :user_id,
            :project_id,
            :filename,
            :created_at,
            :updated_at,
            :display_date,
            :conversion_status,
            :committee,
            :published

  attribute :tags do |object|
    object.tag_list
  end

  attribute :present_attendees do |object|
      object.meeting_attendances
        .where.not(status: 0) # Present (either), remote, in-person
        .includes(:contact)
        .map do |ma|
          {
            label: ma.contact.full_name,
            value: ma.contact.full_name_lookup
          }
        end
  end
end 