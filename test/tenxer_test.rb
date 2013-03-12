require File.expand_path('../helper', __FILE__)

class TenxerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def post_checker(event)
    payload = {'test' => 'payload'}
    return lambda { |env|
      assert_equal "https", env[:url].scheme
      assert_equal "www.tenxer.com", env[:url].host
      assert_equal event, env[:request_headers]["X_GITHUB_EVENT"]
      form = Rack::Utils.parse_query(env[:body])
      assert_equal payload, JSON.parse(form['payload'])
      assert_equal 'API KEY', form['api_key']
      return [200, {}, ''] }
  end

  def test_push
    checker = post_checker "push"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:push, {'api_key' => 'API KEY'}, {'test' => 'payload'})
    svc.receive_event
  end

  def test_pull_request
    checker = post_checker "pull_request"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:pull_request, {'api_key' => 'API KEY'},
      {'test' => 'payload'})
    svc.receive_event
  end


  def test_issues
    checker = post_checker "issues"
    @stubs.post "/updater/githubpubsubhubbub/", &checker

    svc = service(:issues, {'api_key' => 'API KEY'}, {'test' => 'payload'})
    svc.receive_event
  end

  def service(*args)
    super Service::Tenxer, *args
  end
end
