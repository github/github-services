require 'rubygems'
require 'active_support'
require 'uri'
require 'net/http'
require 'net/https'
require 'open-uri'
require 'hpricot'

Dir[File.join(File.dirname(__FILE__), 'tinder/**/*.rb')].sort.each { |lib| require lib }

module Tinder
  class Error < StandardError; end
end