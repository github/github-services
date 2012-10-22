require File.expand_path('../helper', __FILE__)

class TrajectoryTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_raise_config_error_without_api_key
    assert_raise Service::ConfigurationError do
      svc = service({}, payload)
      svc.receive_push
    end

    assert_raise Service::ConfigurationError do
      svc = service({}, payload)
      svc.receive_pull_request
    end
  end

  def test_push
    @stubs.post '/api/payloads?api_key=test_api_key' do |env|
      confirm_trajectory_receives_request(env)
      [200, {}, '']
    end

    svc = service({'api_key' => 'test_api_key'}, payload)
    svc.receive_push

    @stubs.verify_stubbed_calls
  end

  def test_pull_request
    @stubs.post '/api/payloads?api_key=test_api_key' do |env|
      confirm_trajectory_receives_request(env)
      [200, {}, '']
    end

    svc = service({'api_key' => 'test_api_key'}, payload)
    svc.receive_pull_request

    @stubs.verify_stubbed_calls
  end

  def service(*args)
    super Service::Trajectory, *args
  end

  def confirm_trajectory_receives_request(env)
    assert_equal 'application/json', env[:request_headers]['Content-Type']
    assert_equal 'https://www.apptrajectory.com/api/payloads?api_key=test_api_key', env[:url].to_s
  end
end
