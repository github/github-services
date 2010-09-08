require 'oauth/signature/hmac/base'
require 'hmac-sha1'

module OAuth::Signature::HMAC
  class SHA1 < Base
    implements 'hmac-sha1'
    digest_class ::HMAC::SHA1
  end
end
