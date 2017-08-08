require File.expand_path('../helper', __FILE__)

class IceScrumTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
  
  def test_push_only_access_token_cloud 
    svc = service({
      'username' => 'u',
      'password' => 'p',
      'project_key' => ' TEST PROJ  '
  }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end
  
  def test_push_valid_old
    @stubs.post "/icescrum/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'www.example.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'username'   => 'u',
      'password'   => 'p',
      'project_key' => 'TESTPROJ',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end
  
  def test_push_valid_new
    @stubs.post "/icescrum/ws/project/TESTPROJ/commit/github" do |env|
      assert_equal 'www.example.com', env[:url].host
      assert_equal 'token', env[:request_headers]['x-icescrum-token']
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service({
      'token'   => 'token',
      'project_key' => 'TESTPROJ',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_valid_new_cloud
    @stubs.post "/ws/project/TESTPROJ/commit/github" do |env|
      assert_equal 'cloud.icescrum.com', env[:url].host
      assert_equal 'token', env[:request_headers]['x-icescrum-token']
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service({
      'access_token' => 'token',
      'project_key' => 'TESTPROJ'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

def test_push_whitespace_project_key
    @stubs.post "/ws/project/TESTPROJ/commit/github" do |env|
      assert_equal 'cloud.icescrum.com', env[:url].host
      assert_equal 'token', env[:request_headers]['x-icescrum-token']
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service({
      'access_token' => 'token',
      'project_key' => ' TEST PROJ  '
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_missing_username
    svc = service({
      'password' => 'p',
      'project_key' => 'TESTPROJ',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end
  
  def test_push_missing_access_token_or_username_password
    svc = service({
      'project_key' => 'TESTPROJ'
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_push_missing_password
    svc = service({
      'username' => 'u',
      'project_key' => 'TESTPROJ',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_push_missing_project_key 
    svc = service({
      'username' => 'u',
      'password' => 'p',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def service(*args)
    super Service::IceScrum, *args
  end
end
