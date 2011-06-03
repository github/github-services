require File.expand_path('../config/load', __FILE__)

App.set :run   => true,
  :environment => :production,
  :port        => ARGV.first || 8080

HOSTNAME = `hostname`.chomp

begin
  require 'mongrel'
  App.set :server, 'mongrel'
rescue LoadError
  begin
    require 'thin'
    App.set :server, 'thin'
  rescue LoadError
    App.set :server, 'webrick'
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
    App.service(name)
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
end

include GitHub

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each { |service| load service }

App.run!
