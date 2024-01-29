# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

require 'clerk'

Clerk.configure do |c|
  c.api_key =ENV['CLERK_API_KEY']
  c.logger = Logger.new(STDOUT) # if omitted, no logging
  c.middleware_cache_store = ActiveSupport::Cache::FileStore.new("/tmp/clerk_middleware_cache") # if omitted: no caching
end