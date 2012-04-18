# The Sinatra App that handles incoming events.
class Service::App < Sinatra::Base
  set :hostname, lambda { %x{hostname} }

  # Hooks the given Service to a Sinatra route.
  #
  # svc - Service class.
  #
  # Returns nothing.
  def self.service(svc)
    post "/#{svc.hook_name}/:event" do
      boom = nil
      time = Time.now.to_f
      data = nil
      begin
        event, meta, data, payload = parse_request
        if svc.receive(event, data, payload, meta)
          status 200
          ""
        else
          status 404
          status "#{svc.hook_name} Service does not respond to 'push' events"
        end
      rescue Faraday::Error::ConnectionFailed => boom
        status 503
        boom.message
      rescue Service::ConfigurationError => boom
        status 400
        boom.message
      rescue Timeout::Error, Service::TimeoutError => boom
        status 504
        "Service Timeout"
      rescue Service::MissingError => boom
        status 404
        boom.message
      rescue Object => boom
        report_exception svc, data, boom,
          :event => event, :payload => payload.inspect
        status 500
        "ERROR"
      ensure
        duration = Time.now.to_f - time
        if svc != Service::Web && duration > 9
          boom ||= Service::TimeoutError.new("Long Service Hook")
          report_exception svc, data, boom, 
            :event => event, :payload => payload.inspect,
            :duration => "#{duration}s" 
        end
      end
    end
  end

  get "/" do
    "ok"
  end

  # Parses the request data into Service properties.
  #
  # Returns a Tuple of a String event, a Service::Meta, a data Hash, and a
  # payload Hash.
  def parse_request
    data = JSON.parse(params[:data])
    payload = JSON.parse(params[:payload])
    [params[:event], nil, data, payload]
  end

  # Reports the given exception to Haystack.
  #
  # exception - An Exception instance.
  #
  # Returns nothing.
  def report_exception(service_class, service_data, exception, options = {})
    error = (exception.respond_to?(:original_exception) &&
      exception.original_exception) || exception
    backtrace = Array(error.backtrace)[0..500]

    data = {
      'app'       => 'github-services',
      'type'      => 'exception',
      'class'     => error.class.to_s,
      'server'    => settings.hostname,
      'message'   => error.message[0..254],
      'backtrace' => backtrace.join("\n"),
      'rollup'    => Digest::MD5.hexdigest(error.class.to_s + backtrace[0]),
      'service'   => service_class.to_s,
    }.update(options)

    if service_class == Service::Web
      data['service_data'] = service_data.inspect
    end

    if settings.hostname =~ /^sh1\.(rs|stg)\.github\.com$/
      # run only in github's production environment
      Net::HTTP.new('haystack', 80).
        post('/async', "json=#{Rack::Utils.escape(data.to_json)}")
    else
      $stderr.puts data[ 'message' ]
      $stderr.puts data[ 'backtrace' ]
    end

  rescue => boom
    $stderr.puts "reporting exception failed:"
    $stderr.puts "#{boom.class}: #{boom}"
    $stderr.puts "#{boom.backtrace.join("\n")}"
    # swallow errors
  end
end

Dir["#{File.dirname(__FILE__)}/../services/**/*.rb"].each { |service| load service }
