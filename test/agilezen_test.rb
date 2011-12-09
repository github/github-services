require File.expand_path('../helper', __FILE__)

class AgileZenTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post '/api/v1/projects/123/changesets/github' do |env|
      assert_equal %({"answer":42}),   env[:body]
      assert_equal 'test_api_key',     env[:request_headers]['X-Zen-ApiKey']
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service({'api_key' => 'test_api_key', 'project_id' => '123'}, 'answer' => 42)
    svc.receive_push
  end

  def service(*args)
    super Service::AgileZen, *args
  end
end
