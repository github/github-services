require 'oauth/signature/base'

module OAuth::Signature::HMAC
  class Base < OAuth::Signature::Base

  private

    def digest
      self.class.digest_class.digest(secret, signature_base_string)
    end
  end
end
