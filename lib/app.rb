class App < Sinatra::Base
  def self.service(name)
    post "/#{name}/" do
      begin
        data    = JSON.parse(params[:data])
        payload = parse_payload(params[:payload])
        Service::Timeout.timeout(20, Service::TimeoutError) { yield data, payload }
        status 200
        ""
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
