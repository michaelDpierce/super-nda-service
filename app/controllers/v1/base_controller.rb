# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::BaseController < ApplicationController
  include ApiExceptionHandler
  include VerificationUserConcern
  include HelperConcern
end
