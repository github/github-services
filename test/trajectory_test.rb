require File.expand_path('../helper', __FILE__)

class TrajectoryTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post '/api/payloads?api_key=test_api_key' do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      [200, {}, '']
    end

    svc = service({'api_key' => 'test_api_key'}, payload)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Trajectory, *args
  end
end
