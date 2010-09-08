require 'oauth/signature/hmac/base'
require 'hmac-md5'

module OAuth::Signature::HMAC
  class MD5 < Base
    implements 'hmac-md5'
    digest_class ::HMAC::MD5
  end
end
