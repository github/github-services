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
require 'addressable/uri'
require 'mime/types'
require 'xmlsimple'
require 'active_resource'
require 'tinder'
require 'yajl/json_gem'
require 'basecamp'
require 'mail'
require 'xmpp4r'
require 'xmpp4r/jid'
require 'xmpp4r/presence'
require 'xmpp4r/muc'
require 'xmpp4r/roster'
require 'oauth'
require 'twilio-ruby'

# vendor
require 'basecamp'
require 'softlayer/messaging'

require 'faraday'
require 'faraday_middleware'
require 'ostruct'
require File.expand_path("../service/structs", __FILE__)
require File.expand_path("../service/http_helper", __FILE__)

class Addressable::URI
  attr_accessor :validation_deferred
end

Faraday::Utils.default_uri_parser = lambda do |url|
  uri = if url =~ /^https?\:\/\/?$/
    ::Addressable::URI.new
  else
    ::Addressable::URI.parse(url)
  end

  uri.validation_deferred = true
  uri.port ||= uri.inferred_port
  uri
end

XMLRPC::Config::send(:remove_const, :ENABLE_MARSHALLING)
XMLRPC::Config::ENABLE_MARSHALLING = false

module GitHubServices
  VERSION = '1.0.0'

  # The SHA1 of the commit that was HEAD when the process started. This is
  # used in production to determine which version of the app is deployed.
  #
  # Returns the 40 char commit SHA1 string.
  def self.current_sha
    @current_sha ||=
      `cd #{root}; git rev-parse HEAD 2>/dev/null || echo unknown`.
      chomp.freeze
  end
end

require File.expand_path('../service', __FILE__)
