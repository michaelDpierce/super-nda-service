# ==============================================================================
# Copyright 2024, SuperNDA. All rights reserved.
# ==============================================================================

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins [
      "127.0.0.1",
      "localhost:4000",
      "http://localhost:4000",
      "supernda.com",
      "app.supernda.com",
      "https://supernda.com",
      "https://app.supernda.com",
      "https://www.supernda.com",
      "super-nda-production.nyc3.digitaloceanspaces.com",
      "https://super-nda-production.nyc3.digitaloceanspaces.com"
    ]

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head]

    resource "/cable",
      headers: :any,
      methods: [:get, :post, :options]
  end
end
