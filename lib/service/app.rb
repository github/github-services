Dir["#{File.dirname(__FILE__)}/../../services/**/*.rb"].each { |service| load service }

# The Sinatra App that handles incoming events.
class Service::App < Sinatra::Base
  JSON_TYPE = "application/vnd.github-services+json"

  set :hostname, lambda { %x{hostname} }
  set :runner, Service::Runner.new

  # Hooks the given Service to a Sinatra route.
  #
  # svc_class - Service class.
  #
  # Returns nothing.
  def self.service(svc_class)
    runner = self.runner

    get "/#{svc_class.hook_name}" do
      svc_class.title
    end

    post "/#{svc_class.hook_name}/:event" do
      boom = nil
      time = Time.now.to_f
      data = nil
      begin
        event, data, payload = parse_request
        resp = runner.call(svc_class, event, data, payload)

        log_service_request(resp.service, resp.status)

        if resp.exception?
          report_exception(svc_class, data, resp.exception,
            :event => event, :payload => payload.inspect)
        end

        resp.message
      ensure
        if svc_class != Service::Web && resp.duration > 9
          boom = resp.exception ||
            Service::TimeoutError.new("Long Service Hook")

          report_exception svc_class, data, boom,
            :event => event, :payload => payload.inspect,
            :duration => "#{resp.duration}s"
        end
      end
    end
  end

  Service.services.each do |svc|
    service(svc)
  end

  get "/" do
    "ok"
  end

  # Parses the request data into Service properties.
  #
  # Returns a Tuple of a String event, a data Hash, and a payload Hash.
  def parse_request
    case request.content_type
    when JSON_TYPE then parse_json_request
    else parse_http_request
    end
  end

  def parse_json_request
    req = JSON.parse(request.body.read)
    [params[:event], req['data'], req['payload']]
  end

  def parse_http_request
    data = JSON.parse(params[:data])
    payload = JSON.parse(params[:payload])
    [params[:event], data, payload]
  end

  def log_service_request(svc, code)
    status code
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
      'rollup'    => Digest::MD5.hexdigest("#{error.class}#{backtrace[0]}"),
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

