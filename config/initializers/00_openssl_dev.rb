# DEVELOPMENT ONLY: Disable SSL verification for self-signed certificates
# This must load before OmniAuth (hence 00_ prefix)
if Rails.env.development?
  require "openssl"
  
  # Store original verify mode
  OpenSSL::SSL::ORIGINAL_VERIFY_PEER = OpenSSL::SSL::VERIFY_PEER unless defined?(OpenSSL::SSL::ORIGINAL_VERIFY_PEER)
  
  # Disable SSL verification
  OpenSSL::SSL.send(:remove_const, :VERIFY_PEER)
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE
  
  Rails.logger.info "⚠️  SSL verification disabled for development"
end
