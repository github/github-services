require File.expand_path('../helper', __FILE__)

class IceScrumTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end
  
  def test_push_valid
    @stubs.post "/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'cloud.icescrum.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'username'   => 'u',
      'password'   => 'p',
      'project_key' => 'TESTPROJ'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_valid_token
    @stubs.post "/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'cloud.icescrum.com', env[:url].host
      assert_equal 'token', env[:request_headers]['x-icescrum-token']
      [200, {}, '']
    end

    svc = service({
      'access_token' => 'token',
      'project_key' => 'TESTPROJ'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_valid_custom_url
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
  
  def test_push_valid_custom_url_token
    @stubs.post "/icescrum/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'www.example.com', env[:url].host
      assert_equal 'token', env[:request_headers]['x-icescrum-token']
      assert_equal 'application/json', env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service({
      'access_token'   => 'token',
      'project_key' => 'TESTPROJ',
      'base_url'   => 'http://www.example.com/icescrum'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

def test_push_whitespace_project_key
    @stubs.post "/ws/p/TESTPROJ/commit" do |env|
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service({
      'username' => ' u ',
      'password' => ' p ',
      'project_key' => ' TEST PROJ  '
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_missing_username
    svc = service({
      'password' => 'p',
      'project_key' => 'TESTPROJ'
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
      'project_key' => 'TESTPROJ'
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_push_missing_project_key 
    svc = service({
      'username' => 'u',
      'password' => 'p',
    }, payload)

    assert_raises Service::ConfigurationError do
      svc.receive_push
    end
  end

  def service(*args)
    super Service::IceScrum, *args
  end
end
