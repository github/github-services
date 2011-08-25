require File.expand_path('../config/load', __FILE__)

Service::App.set :environment => :production,
  :port        => ARGV.first || 8080,
  :logging     => true

run Service::App
