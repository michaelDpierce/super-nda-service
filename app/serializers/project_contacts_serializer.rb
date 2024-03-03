# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class ProjectContactsSerializer < ApplicationSerializer
  set_id :hashid
  set_type :project_contact

  attribute :role,
            :created_at,
            :updated_at

  attribute :contact_id do |object|
    object.contact.hashid
  end

  attribute :prefix do |object|
    object.contact.prefix || "-"
  end

  attribute :first_name do |object|
    object.contact.first_name || "-"
  end

  attribute :last_name do |object|
    object.contact.last_name || "-"
  end

  attribute :email do |object|
    object.contact.email || "-"
  end

  attribute :phone do |object|
    object.contact.phone || "-"
  end
end