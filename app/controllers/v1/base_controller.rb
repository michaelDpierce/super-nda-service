# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

class V1::BaseController < ApplicationController
  include ApiExceptionHandler
  include VerificationUserConcern
  include TimezoneHandler
  include HelperConcern
  # include ActiveStorage::SetCurrent

  # before_action do
  #   ActiveStorage::Current.url_options = { 
  #     protocol: request.protocol,
  #     host: request.host,
  #     port: request.port
  #   }
  # end
end
