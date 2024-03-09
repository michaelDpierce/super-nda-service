# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@supernda .com"
  layout "mailer"
end
