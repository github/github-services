require 'rubygems'
require 'bundler/setup'
$:.unshift *Dir["#{File.dirname(__FILE__)}/../vendor/internal-gems/**/lib"]

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
require 'twilio-ruby'
require 'right_aws'
require 'right_http_connection'

# vendor
require 'basecamp'
require 'rubyforge'
require 'softlayer/messaging'

require File.expand_path('../../lib/service', __FILE__)
require File.expand_path('../../lib/service/app', __FILE__)

