require 'forwardable'
require 'rubygems'
require 'date'
require 'yaml'
require 'open-uri'

gem 'json', '>= 1.1.7'
require 'json'

gem 'oauth', '>=0.3.5'
require 'oauth'

gem 'mash', '>=0.0.3'
require 'mash'

$:.unshift(File.dirname(__FILE__))
require 'ext/core_ext'
require 'yammer/client'
require 'yammer/message'
require 'yammer/message_list'
require 'yammer/user'
