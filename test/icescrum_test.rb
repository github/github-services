require File.expand_path('../helper', __FILE__)

class IceScrumTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_valid
    @stubs.post "/a/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'www.kagilum.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
      [200, {}, '']
    end

    svc = service({
      'username' => 'u',
      'password' => 'p',
      'project_key' => 'TESTPROJ'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

  def test_push_valid_custom_url
    @stubs.post "/icescrum/ws/p/TESTPROJ/commit" do |env|
      assert_equal 'www.example.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv      
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

  def test_push_lowcase_project_key
    @stubs.post "/a/ws/p/TESTPROJ/commit" do |env|
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv      
      [200, {}, '']
    end

    svc = service({
      'username' => 'u',
      'password' => 'p',
      'project_key' => 'testProj'
    }, payload)

    svc.receive_push
    @stubs.verify_stubbed_calls
  end

def test_push_whitespace_project_key
    @stubs.post "/a/ws/p/TESTPROJ/commit" do |env|
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      body = Faraday::Utils.parse_nested_query(env[:body])
      recv = JSON.parse(body['payload'])
      assert_equal payload, recv
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




