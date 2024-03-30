# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class DocumentAnalytic < ApplicationRecord
  enum action_type: {
    share_link: 0,
    view: 1,
    download: 2,
    signing_link: 3
  }
end
