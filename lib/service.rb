class Service
  class << self
    attr_reader :hook_name

    def hook_name=(value)
      @hook_name = value
      Service::App.service(self)
    end

    def receive(event_type, data, payload)
      svc = new(event_type, data, payload)
      event_method = "receive_#{event_type}"
      if svc.respond_to?(event_method)
        Service::Timeout.timeout(20, TimeoutError) do
          svc.send(event_method)
        end

        true
      else
        false
      end
    end
  end

  attr_reader :event_type
  attr_reader :data
  attr_reader :payload

  def initialize(event_type)
    @event_type = event_type
  end

  def shorten_url(url)
    Service::Timeout.timeout(6, Service::TimeoutError) do
      short = Net::HTTP.get("api.bit.ly", "/shorten?version=2.0.1&longUrl=#{url}&login=github&apiKey=R_261d14760f4938f0cda9bea984b212e4")
      short = JSON.parse(short)
      short["errorCode"].zero? ? short["results"][url]["shortUrl"] : url
    end
  rescue Service::TimeoutError
    url
  end

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
