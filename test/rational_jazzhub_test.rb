require File.expand_path('../helper', __FILE__)

class RationalJazzhubTest < Service::TestCase
  def setup
    @stubs= Faraday::Adapter::Test::Stubs.new
    @Pushes= 0
  end

  def test_push
    svc = service(
      {'username' => username,
       'password' => password},
        payload)

    @stubs.post "/manage/processGitHubPayload" do |env|
       assert_equal 'hub.jazz.net', env[:url].host
       params = Faraday::Utils.parse_nested_query(env[:url].query)
       assert_equal({'jazzhubUsername' => username,'jazzhubPassword' => password}, params)
       @Pushes += 1
       [200, {}, '']
    end
    svc.receive_push
    assert_equal 1, @Pushes
  end

  def test_push_empty_server_override
    svc = service(
      {'username' => username,
       'password' => password,
        'override_server_url' => ""},
        payload)

    @stubs.post "/manage/processGitHubPayload" do |env|
       assert_equal 'hub.jazz.net', env[:url].host
       params = Faraday::Utils.parse_nested_query(env[:url].query)
       assert_equal({'jazzhubUsername' => username,'jazzhubPassword' => password}, params)
       @Pushes += 1
       [200, {}, '']
    end
    svc.receive_push
    assert_equal 1, @Pushes
  end

  def test_push_override
    svc = service(
      {'username' => username,
       'password' => password,
       'override_server_url' => "https://test.example.org/foo"},
        payload)

    @stubs.post "/foo/processGitHubPayload" do |env|
       assert_equal 'test.example.org', env[:url].host
       params = Faraday::Utils.parse_nested_query(env[:url].query)
       assert_equal({'jazzhubUsername' => username,'jazzhubPassword' => password}, params)
       @Pushes += 1
       [200, {}, '']
    end
    svc.receive_push
    assert_equal 1, @Pushes
  end

  def username
    return 'test_user'
  end

  def password
    return 'test_pass'
  end

  def service(*args)
    super Service::RationalJazzHub, *args
  end
end
