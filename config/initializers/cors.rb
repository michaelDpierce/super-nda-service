# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      '127.0.0.1',
      'localhost:3000',
      'minutesbyminutes.com',
      'app.minutesbyminutes.com',
      'https://minutesbyminutes.com',
      'https://app.minutesbyminutes.com',
      'https://www.minutesbyminutes.com',
    ]

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
