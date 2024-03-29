# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class UserSerializer < ApplicationSerializer
  set_id :hashid
  set_type :user

  attribute :email

  belongs_to :project_user, serializer: ProjectUsersSerializer
end 
