# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      '127.0.0.1',
      'localhost:3000',
      'mins4mins.com',
      'app.mins4mins.com',
      'https://mins4mins.com',
      'https://app.mins4mins.com',
      'https://www.mins4mins.com',
    ]

    resource '*',
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]
  end
end
