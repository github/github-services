require File.expand_path('../helper', __FILE__)

class SimperiumTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @test_app_id = "sample-app-name"
    @test_token = "0123456789abcde"
  end

  def test_push
    payload = {'commits'=>[{'id'=>'test'}]}
    @stubs.post "/1/#{@test_app_id}/push/i/test" do |env|
      commit = JSON.parse(env[:body])

      assert_equal env[:url].host, "api.simperium.com"
      assert_equal env[:request_headers]['X-Simperium-Token'], @test_token
      assert_equal 'test', commit['id']
      [200, {}, '']
    end

    svc = service( {
      'app_id' => @test_app_id,
      'token' => @test_token
    }, payload)
    svc.receive_event
  end

  def service(*args)
    super Service::Simperium, *args
  end
end

