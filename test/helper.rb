require 'test/unit'
require File.expand_path('../../config/load', __FILE__)

class Service::TestCase < Test::Unit::TestCase
  def test_default
  end

  def service(klass, event, data, payload)
    service = klass.new(event, data, payload)
    service.faraday = Faraday.new { |b| b.adapter(:test, @stubs) }
    service
  end
end
