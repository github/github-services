require File.expand_path('../helper', __FILE__)

class AgileBenchTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/services/v1/github" do |env|
      assert_equal 'agilebench.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['Content-type']
      [200, {}, '']
    end

    svc = service({'token' => 'test_token', 'project_id' => '123'},
                  payload)
    svc.receive_push
  end

  def test_missing_token
    @stubs.post "/services/v1/github"
    svc = service({'token' => '', 'project_id' => '123'},
                  payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_missing_project_id
    @stubs.post "/services/v1/github"
    svc = service({'token' => 'test_token', 'project_id' => ''},
                  payload)
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def service(*args)
    super Service::AgileBench, *args
  end
end

