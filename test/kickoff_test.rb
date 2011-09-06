require File.expand_path('../helper', __FILE__)

class KickoffTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/projects/a/chat" do |env|
      assert_equal 'api.kickoffapp.com', env[:url].host
      assert_equal 'token=b', env[:url].query
      [200, {}, '']
    end

    svc = service(
      {'project_id' => 'a', 'project_token' => 'b' },
      payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Kickoff, *args
  end
end

