require File.expand_path('../helper', __FILE__)

class NotifoTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    subscribed = %w(a b)
    notified   = %w(a b)
    @stubs.post "/v1/subscribe_user" do |env|
      assert_equal 'api.notifo.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal subscribed.shift, data['username']
      [200, {}, '']
    end

    @stubs.post "/v1/send_notification" do |env|
      assert_equal 'api.notifo.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal notified.shift, data['to']
      [200, {}, '']
    end

    svc = service({'subscribers' => 'a,b'}, payload)
    svc.secrets = {'notifo' => {'apikey' => 'a'}}
    svc.receive_push
  end

  def test_push_with_empty_commits
    data = payload
    data['commits'] = []

    svc = service({'subscribers' => 'a,b'}, data)
    svc.secrets = {'notifo' => {'apikey' => 'a'}}
    svc.receive_push
  end

  def service(*args)
    super Service::Notifo, *args
  end
end

