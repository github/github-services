require File.expand_path('../helper', __FILE__)

class TogglTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/api/v6/tasks.json"
    @stubs.post url do |env|
      assert_equal 'www.toggl.com', env[:url].host
      assert_equal basic_auth(:a, :api_token), env[:request_headers]['authorization']
      assert_equal 900, JSON.parse(env[:body])['task']['duration']
      [200, {}, '']
    end

    modified = payload.dup
    modified['commits'].first['message'].sub! /f:/, 't:'
    svc = service({'api_token' => 'a'}, modified)
    svc.receive_push
  end

  def service(*args)
    super Service::Toggl, *args
  end
end

