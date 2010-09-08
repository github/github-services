module OAuth
  module Signature
    def self.available_methods
      @available_methods ||= {}
    end

    def self.build(request, options = {}, &block)
      request = OAuth::RequestProxy.proxy(request, options)
      klass = available_methods[(request.signature_method || "").downcase]
      raise UnknownSignatureMethod, request.signature_method unless klass
      klass.new(request, options, &block)
    end

    def self.sign(request, options = {}, &block)
      self.build(request, options, &block).signature
    end

    def self.verify(request, options = {}, &block)
      self.build(request, options, &block).verify
    end

    def self.signature_base_string(request, options = {}, &block)
      self.build(request, options, &block).signature_base_string
    end

    class UnknownSignatureMethod < Exception; end
  end
end
