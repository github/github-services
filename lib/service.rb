class Service
  # Raised when an unexpected error occurs during service hook execution.
  class Error < StandardError
    attr_reader :original_exception
    def initialize(message, original_exception=nil)
      original_exception = message if message.kind_of?(Exception)
      @original_exception = original_exception
      super(message)
    end
  end

  class TimeoutError < Timeout::Error
  end
  #
  # Raised when a service hook fails due to bad configuration. Services that
  # fail with this exception may be automatically disabled.
  class ConfigurationError < Error
  end
end
