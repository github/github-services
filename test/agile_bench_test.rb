require File.expand_path('../helper', __FILE__)

class AgileBenchTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @token = "test_token"
    @project_id = "123"
  end

  def test_push
    @stubs.post "/project/#{@project_id}" do |env|
      assert_equal '212.127.65.121', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'token' => 'test_token', 'project_id' => '123'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::AgileBench, *args
  end
end

