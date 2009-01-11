$:.unshift *Dir["#{File.dirname(__FILE__)}/vendor/**/lib"]

# stdlib
require 'net/http'
require 'net/https'
require 'net/smtp'
require 'socket'
require 'timeout'
require 'xmlrpc/client'
require 'openssl'
require 'cgi'
#~ require 'date' # This is needed by the CIA service in ruby 1.8.7 or later

# vendor
require 'rack'
require 'sinatra'
require 'tinder'
require 'json'
require 'tinder'
require 'basecamp'
require 'tmail'
require 'xmpp4r'
require 'xmpp4r-simple'
require 'rubyforge'

module GitHub
  def service(name)
    Timeout.timeout(20) do
      post "/#{name}/" do
        data = JSON.parse(params[:data])
        payload = JSON.parse(params[:payload])
        yield data, payload
      end
    end
  rescue Timeout::Error
  end

  def shorten_url(url)
    Timeout::timeout(6) do
      Net::HTTP.get "tinyurl.com", "/api-create.php?url=#{url}"
    end
  rescue Timeout::Error
    url
  end
end
include GitHub

Dir["#{File.dirname(__FILE__)}/services/**/*.rb"].each { |service| load service }
