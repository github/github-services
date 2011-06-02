require File.expand_path('../config/load', __FILE__)

set :run, true
set :environment, :production
set :port, ARGV.first || 8080

HOSTNAME = `hostname`.chomp

begin
  require 'mongrel'
  set :server, 'mongrel'
rescue LoadError
  begin
    require 'thin'
    set :server, 'thin'
  rescue LoadError
    set :server, 'webrick'
  end
end

begin
  require 'system_timer'
  ServiceTimeout = SystemTimer
rescue LoadError
  require 'timeout'
  ServiceTimeout = Timeout
end

module GitHub
  # backwards compatibility
  ServiceError = Service::Error
  ServiceTimeoutError = Service::TimeoutError
  ServiceConfigurationError = Service::ConfigurationError

  def service(name)
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
        # redact sensitive info in hook_data hash
        hook_data = data || params[:data]
        hook_payload = payload || params[:payload]
        #%w[password token].each { |key| hook_data[key] &&= '<redacted>' }
        owner = hook_payload['repository']['owner']['name'] rescue nil
        repo  = hook_payload['repository']['name'] rescue nil
        report_exception boom,
          :hook_name    => name,
          :hook_data    => hook_data.inspect,
          :hook_payload => hook_payload.inspect,
          :user         => owner,
          :repo         => "#{owner}/#{repo}"

        status 500
        "ERROR"
      end
    end
  end

  def parse_payload(json)
    payload = JSON.parse(json)
    payload['ref_name'] = payload['ref'].to_s.sub(/\Arefs\/(heads|tags)\//, '')
    payload
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

  def report_exception(exception, other)

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

    # optional
    other.each { |key, value| data[key.to_s] = value.to_s }

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
include GitHub

get "/" do
  "ok"
end

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each { |service| load service }
