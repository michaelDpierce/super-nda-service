# =============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# =============================================================================

class V1::BaseController < ApplicationController
  include ActionController::MimeResponds
  include ApiExceptionHandler
  include VerificationUserConcern
  include HelperConcern
end
