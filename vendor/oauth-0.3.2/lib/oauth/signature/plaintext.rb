require 'oauth/signature/base'

module OAuth::Signature
  class PLAINTEXT < Base
    implements 'plaintext'

    def signature
      signature_base_string
    end

    def ==(cmp_signature)
      signature == escape(cmp_signature)
    end

    def signature_base_string
      secret
    end

    def secret
      escape(super)
    end
  end
end
