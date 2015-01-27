require File.expand_path('../helper', __FILE__)

class TenxerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def post_checker(event)
    return lambda { |env|
      assert_equal "https", env[:url].scheme
      assert_equal "www.tenxer.com", env[:url].host
      assert_match "payload=%7B%22test%22%3A%22payload%22%7D", env[:body]
      assert_equal event, env[:request_headers]["X_GITHUB_EVENT"]
      return [200, {}, ''] }
  end

  def test_push
    checker = post_checker "push"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:push, {}, {'test' => 'payload'})
    svc.receive_event
  end

  def test_pull_request
    checker = post_checker "pull_request"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:pull_request, {}, {'test' => 'payload'})
    svc.receive_event
  end


  def test_issues
    checker = post_checker "issues"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:issues, {}, {'test' => 'payload'})
    svc.receive_event
  end

  def service(*args)
    super Service::Tenxer, *args
  end
end
