require 'test/unit'
require File.expand_path('../../config/load', __FILE__)

class Service::TestCase < Test::Unit::TestCase
  def test_default
  end

  def service(klass, event_or_data, data, payload=nil)
    event = nil
    if event_or_data.is_a?(Symbol)
      event = event_or_data
    else
      payload = data
      data    = event_or_data
      event   = :push
    end

    service = klass.new(event, data, payload)
    service.http = Faraday.new do |b|
      b.request :url_encoded
      b.adapter :test, @stubs
    end
    service
  end

  def basic_auth(user, pass)
    "Basic " + ["#{user}:#{pass}"].pack("m*").strip
  end

  def payload
    Service::PushHelpers.sample_payload
  end
end

