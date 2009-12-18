require 'rubygems'
require 'active_support'
require 'uri'
require 'net/http'
require 'net/https'
require 'open-uri'

require 'tinder/connection'
require 'tinder/multipart'
require 'tinder/campfire'
require 'tinder/room'

module Tinder
  class Error < StandardError; end
  class SSLRequiredError < Error; end
end
