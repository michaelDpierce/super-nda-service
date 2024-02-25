# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

ConvertApi.configure do |config|
  config.api_secret = ENV["CONVERT_API_SECRET"]
end