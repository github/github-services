class Service::Runner
  class Response < Struct.new(:service, :status, :message, :exception)
    attr_reader :duration

    def exception?
      status == 500 && exception
    end

    def set_duration(start_time)
      @duration = Time.now - start_time
    end
  end

  def call(svc_class, event, data, payload)
    time = Time.now
    resp = nil
    boom = nil

    if svc = svc_class.receive(event, data, payload)
      resp = respond(svc, 200, 'OK')
    else
      resp = respond(svc, 200,
        "#{svc_class.hook_name} Service does not respond to #{event.inspect} events")
    end

  rescue Faraday::Error::ConnectionFailed => boom
    resp = error(svc, 503, boom)
  rescue Service::ConfigurationError => boom
    resp = error(svc, 400, boom)
  rescue Timeout::Error, Service::TimeoutError => boom
    resp = error(svc, 504, boom, "Service Timeout")
  rescue Service::MissingError => boom
    resp = error(svc, 404, boom)
  rescue Exception => boom
    resp = error(svc, 500, boom, "ERROR")
  ensure
    resp.set_duration(time) if resp
  end

  def respond(service, status, message)
    Response.new(service, status, message)
  end

  def error(service, status, exception, message = nil)
    Response.new(service, status, message || exception.message, exceptoin)
  end
end
