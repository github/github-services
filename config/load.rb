is_production = ENV['RACK_ENV'] == 'production' || !!ENV['GEM_STRICT']
services_root = File.expand_path('../../', __FILE__)

if is_production
  # Verify the environment has been bootstrapped by checking that the
  # .bundle/loadpath file exists.
  if !File.exist?("#{services_root}/.bundle/loadpath")
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Run script/bootstrap to remedy this situation."
    fail "gem environment not configued"
  end
else
  # Run a more exhaustive bootstrap check in non-production environments by making
  # sure the Gemfile matches the .bundle/loadpath file checksum.
  #
  # Verify the environment has been bootstrapped by checking that the
  # .bundle/loadpath file exists.
  if !File.exist?("#{services_root}/.bundle/loadpath")
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning script/bootstrap to remedy this situation..."
    system "#{services_root}/script/bootstrap --local"

    if !File.exist?("#{services_root}/.bundle/loadpath")
      warn "WARN The gem environment is STILL out-of-date."
      warn "     Please contact your network administrator."
      fail "gem environment not configued"
    end
  end

  checksum = File.read("#{services_root}/.bundle/checksum").to_i rescue nil
  if `cksum <'#{services_root}/Gemfile'`.to_i != checksum
    warn "WARN The gem environment is out-of-date or has yet to be bootstrapped."
    warn "     Runnning script/bootstrap to remedy this situation..."
    system "#{services_root}/script/bootstrap --local"

    checksum = File.read("#{services_root}/.bundle/checksum").to_i rescue nil
    if `cksum <'#{services_root}/Gemfile'`.to_i != checksum
      warn "WARN The gem environment is STILL out-of-date."
      warn "     Please contact your network administrator."
      fail "gem environment not configued"
    end
  end
end

# Disallow use of system gems by default in staging and production environments
# or when the GEM_STRICT environment variable is set. This ensures the gem
# environment is totally isolated to only stuff specified in the Gemfile.
if is_production
  ENV['GEM_PATH'] = "#{services_root}/vendor/gems"
  ENV['GEM_HOME'] = "#{services_root}/vendor/gems"
elsif !ENV['GEM_PATH'].to_s.include?("#{services_root}/vendor/gems")
  ENV['GEM_PATH'] =
    ["#{services_root}/vendor/gems", ENV['GEM_PATH']].compact.join(':')
end

# put RAILS_ROOT/bin on PATH
binpath = "#{services_root}/bin"
ENV['PATH'] = "#{binpath}:#{ENV['PATH']}" if !ENV['PATH'].include?(binpath)

# Setup bundled gem load path.
paths = File.read("#{services_root}/.bundle/loadpath").split("\n")
paths.each do |path|
  next if path =~ /^[ \t]*(?:#|$)/
  path = File.join(services_root, path)
  $: << path if !$:.include?(path)
end

# Add RAILS_ROOT to load path so you can require config/initializers/file
# and stuff like that.
$:.unshift services_root if !$:.include?(services_root)

$:.unshift *Dir["#{File.dirname(__FILE__)}/../vendor/internal-gems/**/lib"]

# Child processes inherit our load path.
ENV['RUBYLIB'] = $:.compact.join(':')

# stdlib
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'socket'
require 'xmlrpc/client'
require 'openssl'
require 'cgi'
#~ require 'date' # This is needed by the CIA service in ruby 1.8.7 or later

# bundled
require 'mime/types'
require 'xmlsimple'
require 'active_resource'
require 'rack'
require 'sinatra/base'
require 'tinder'
require 'yajl/json_gem'
require 'basecamp'
require 'mail'
require 'xmpp4r'
require 'xmpp4r/jid.rb'
require 'xmpp4r/presence.rb'
require 'xmpp4r/muc.rb'
require 'xmpp4r-simple'
require 'rubyforge'
require 'oauth'
require 'yammer4r'
require 'mq'
require 'statsd'
require 'twilio-ruby'

# vendor
require 'basecamp'
require 'rubyforge'

require File.expand_path('../../lib/service', __FILE__)
require File.expand_path('../../lib/app', __FILE__)
