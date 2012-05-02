require 'test/unit'
require File.expand_path('../../config/load', __FILE__)

class Service::TestCase < Test::Unit::TestCase
  ALL_SERVICES = Service.services.dup

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

  def push_payload
    Service::PushHelpers.sample_payload
  end
  alias payload push_payload

  def pull_payload
    Service::PullRequestHelpers.sample_payload
  end

  def issues_payload
    Service::IssueHelpers.sample_payload
  end

  def basic_payload
    Service::HelpersWithMeta.sample_payload
  end
end

