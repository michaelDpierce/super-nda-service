# ==============================================================================
# Copyright 2024, MinuteBook. All rights reserved.
# ==============================================================================

if ENV['SSL_CA_CERT_BASE64']
  decoded_cert = Base64.decode64(ENV['SSL_CA_CERT_BASE64'])
  File.write('tmp/ca_cert.pem', decoded_cert)
  ENV['SSL_CA_CERT_PATH'] = Rails.root.join('tmp', 'ca_cert.pem').to_s
end
