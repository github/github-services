require File.expand_path("../helper", __FILE__)

class ZendeskTest < Service::TestCase
  def setup
    @stubs   = Faraday::Adapter::Test::Stubs.new
    @data    = { "username" => "user", "password" => "pass", "subdomain" => "igor" }
    @payload = { :message => "My name is zd#12345 what do you say?" }
  end

  def test_subdomain
    post
    svc = service :event, @data, @payload
    svc.receive_event
  end

  def test_domain
    post

    svc = service :event, @data.merge("subdomain" => "igor.zendesk.com"), @payload
    svc.receive_event
  end

  def test_unmatched_ticket
    post

    svc = service :event, @data, { :message => "Nothing to match" }
    svc.receive_event

    begin
      @stubs.verify_stubbed_calls
    rescue RuntimeError
    else
      assert_true false
    end
  end

  def post
    @stubs.post "/api/v2/integrations/github?ticket_id=12345" do |env|
      assert_equal "application/json", env[:request_headers]["Content-Type"]
      assert_equal "igor.zendesk.com", env[:url].host
      assert_equal "12345", env[:params]["ticket_id"]
      assert_equal JSON.generate({ :payload => @payload }), env[:body]
      [ 201, {}, "" ]
    end
  end

  def service(*args)
    super Service::Zendesk, *args
  end
end
