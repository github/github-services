# The Sinatra App that handles incoming events.
class Service::App < Sinatra::Base

  set :hostname, lambda { %x{hostname} }

  # Hooks the given Service to a Sinatra route.
  #
  # svc - Service instance.
  #
  # Returns nothing.
  def self.service(svc)
    post "/#{svc.hook_name}/:event" do
      boom = nil
      time = Time.now.to_f
      data = nil
      begin
        data    = JSON.parse(params[:data])
        payload = parse_payload(params[:payload])
        if svc.receive(params[:event], data, payload)
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
      rescue Service::TimeoutError => boom
        status 504
        "Service Timeout"
      rescue Object => boom
        report_exception svc, data, boom, 
          :event => params[:event], :payload => payload.inspect
        status 500
        "ERROR"
      ensure
        duration = Time.now.to_f - time
        if duration > 9
          boom ||= RuntimeError.new("Long Service Hook")
          report_exception svc, data, boom, 
            :event => params[:event], :payload => payload.inspect,
            :duration => "#{duration}s" 
        end
      end
    end
  end

  get "/" do
    "ok"
  end

  # Parses the incoming payload and massages any properties.
  #
  # json - JSON String.
  #
  # Returns a Hash payload.
  def parse_payload(json)
    JSON.parse(json)
  end

  # Reports the given exception to Haystack.
  #
  # exception - An Exception instance.
  #
  # Returns nothing.
  def report_exception(service_class, service_data, exception, options = {})
    backtrace = Array(exception.backtrace)[0..500]

    data = {
      'app'       => 'github-services',
      'type'      => 'exception',
      'class'     => exception.class.to_s,
      'server'    => settings.hostname,
      'message'   => exception.message[0..254],
      'backtrace' => backtrace.join("\n"),
      'rollup'    => Digest::MD5.hexdigest(exception.class.to_s + backtrace[0]),
      'service'   => service_class.to_s,
    }.update(options)

    if exception.kind_of?(Service::Error)
      if exception.original_exception
        data['original_class'] = exception.original_exception.to_s
        data['backtrace'] = exception.original_exception.backtrace.join("\n")
        data['message'] = exception.original_exception.message[0..254]
      end
    elsif !exception.kind_of?(Service::TimeoutError)
      data['original_class'] = data['class']
      data['class'] = 'Service::Error'
    end

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
