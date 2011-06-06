class Service::App < Sinatra::Base
  def self.service(svc)
    app = lambda do
      begin
        data    = JSON.parse(params[:data])
        payload = parse_payload(params[:payload])
        if svc.receive(:push, data, payload)
          status 200
          ""
        else
          status 404
          status "#{svc.hook_name} Service does not respond to 'push' events"
        end
      rescue Service::ConfigurationError => boom
        status 400
        boom.message
      rescue Service::TimeoutError => boom
        status 504
        "Service Timeout"
      rescue Object => boom
        report_exception boom
        status 500
        "ERROR"
      end
    end
    post "/#{svc.legacy_hook_name}/", &app
    post "/#{svc.hook_name}/:event", &app
  end

  get "/" do
    "ok"
  end

  def parse_payload(json)
    payload = JSON.parse(json)
    payload['ref_name'] = payload['ref'].to_s.sub(/\Arefs\/(heads|tags)\//, '')
    payload
  end

  def report_exception(exception)
    backtrace = Array(exception.backtrace)[0..500]

    data = {
      'app'       => 'github-services',
      'type'      => 'exception',
      'class'     => exception.class.to_s,
      'server'    => HOSTNAME,
      'message'   => exception.message[0..254],
      'backtrace' => backtrace.join("\n"),
      'rollup'    => Digest::MD5.hexdigest(exception.class.to_s + backtrace[0])
    }

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

    if HOSTNAME =~ /^sh1\.(rs|stg)\.github\.com$/
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

module GitHub
  # backwards compatibility
  ServiceError = Service::Error
  ServiceTimeoutError = Service::TimeoutError
  ServiceConfigurationError = Service::ConfigurationError

  def service(name)
  end
end

include GitHub

Dir["#{File.dirname(__FILE__)}/../services/**/*.rb"].each { |service| load service }
