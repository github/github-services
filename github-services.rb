require File.expand_path('../config/load', __FILE__)

Service::App.set :run => true,
  :environment => :production,
  :port        => ARGV.first || 8080

HOSTNAME = `hostname`.chomp

begin
  require 'mongrel'
  Service::App.set :server, 'mongrel'
rescue LoadError
  begin
    require 'thin'
    Service::App.set :server, 'thin'
  rescue LoadError
    Service::App.set :server, 'webrick'
  end
end

Service::App.run!

