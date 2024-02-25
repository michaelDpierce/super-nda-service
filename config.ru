# =============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# =============================================================================

# This file is used by Rack-based servers to start the application.

require_relative "config/environment"

run Rails.application
Rails.application.load_server
