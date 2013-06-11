require File.expand_path('../helper', __FILE__)

class HumbugTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def post_checker(event)
    return lambda { |env|
      assert_equal "https", env[:url].scheme
      assert_equal "humbughq.com", env[:url].host
      assert_match "payload=%7B%22test%22%3A%22payload%22%7D", env[:body]
      assert_match "email=e", env[:body]
      assert_match "api-key=a", env[:body]
      assert_match "event=" + event, env[:body]
      assert_match "stream=commits", env[:body]
      assert_match "branches=b1%2Cb2", env[:body]
      return [200, {}, ''] }
  end

  def test_push
    checker = post_checker "push"
    @stubs.post "/api/v1/external/github", &checker

    svc = service(:push,
        {'email' => 'e', 'api_key' => 'a', 'stream' => 'commits', 'branches' => 'b1,b2'},
        {'test' => 'payload'})
    svc.receive_event
  end

  def test_pull_request
    checker = post_checker "pull_request"
    @stubs.post "/api/v1/external/github", &checker

    svc = service(:pull_request,
        {'email' => 'e', 'api_key' => 'a', 'stream' => 'commits', 'branches' => 'b1,b2'},
        {'test' => 'payload'})
    svc.receive_event
  end

  def service(*args)
    super Service::Humbug, *args
  end
end

