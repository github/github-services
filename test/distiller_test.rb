require File.expand_path('../helper', __FILE__)
class DistillerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  # currently supported events

  # push

  def test_push
    post_to_service(:push)
  end

  def test_supported_events
    assert_equal Service::Distiller.supported_events.sort , Service::ALL_EVENTS.sort
    assert_equal Service::Distiller.default_events.sort , [:push].sort
  end

  private

  def service(*args)
    super Service::Distiller, *args
  end

  def post_to_service(event_name)
    assert Service::ALL_EVENTS.include? event_name.to_s
    svc = service(event_name, {'token' => 'abc'}, payload)

    @stubs.post "/hooks/github" do |env|
      body = Faraday::Utils.parse_query env[:body]
      assert_match "https://www.distiller.io/hooks/github", env[:url].to_s
      assert_match 'application/x-www-form-urlencoded', env[:request_headers]['content-type']
      assert_equal payload, JSON.parse(body["payload"].to_s)
      assert_equal event_name.to_s, JSON.parse(body["event_type"].to_s)["event_type"]
    end

    svc.receive_event
  end
end
