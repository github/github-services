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

    svc = Service::Trajectory.new(:push, {'api_key' => 'test_api_key'})
    svc.receive_push
  end
end
