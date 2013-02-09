require File.expand_path('../helper', __FILE__)

class GenericNotifierTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @url = 'http://example.com/github_notification'
  end

  def test_posts_payload
    @stubs.post '/github_notification' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'example.com', env[:url].host
      assert_equal payload, JSON.parse(Rack::Utils.parse_query(env[:body])['payload'])
    end

    svc = service(
      {'url' => @url, 'push' => true}, payload)
    svc.receive_event

    @stubs.verify_stubbed_calls
  end

  def test_push_post_skipped
    @stubs.post '/github_notification' do |env|
      fail "Did not expect post!"
    end

    svc = service(
      {'url' => @url}, payload)
    svc.receive_event
  end

  def test_event_added_to_payload
    @stubs.post '/github_notification' do |env|
      event = Rack::Utils.parse_query(env[:body])['event']

      assert_equal 'pull_request', event
    end

    svc = service(
      :pull_request, {'url' => @url, 'pull_request' => true}, pull_payload)
    svc.receive_event
  end

  def test_pull_request_post
    @stubs.post '/github_notification' do |env|
      parsed = Rack::Utils.parse_query(env[:body])

      event = parsed['event']
      payload = JSON.parse(parsed['payload'])

      assert_equal 'pull_request', event
      assert payload['pull_request']
    end

    svc = service(
      :pull_request, {'url' => @url, 'pull_request' => true}, pull_payload)
    svc.receive_event
  end

  def test_pull_request_post_skipped
    @stubs.post '/github_notification' do |env|
      fail "Did not expect post!"
    end

    svc = service(
      :pull_request, {'url' => @url}, pull_payload)
    svc.receive_event
  end

private

  def service(*args)
    super Service::GenericNotifier, *args
  end
end
