# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

Sidekiq.configure_server do |config|
  config.redis = { url: "redis://localhost:6379/1" }
end

Sidekiq.configure_client do |config|
  config.redis = { url: "redis://localhost:6379/1" }
end
