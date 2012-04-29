require File.expand_path('../helper', __FILE__)

class JenkinsTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/github-webhook/" do |env|
      assert_equal 'jenkins.example.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push,
      {'jenkins_hook_url' => 'http://jenkins.example.com/github-webhook/'}, payload
    svc.receive_push
  end

  def test_no_jenkins_hook_url
    assert_raises Service::ConfigurationError do
      svc = service :push,
        {'jenkins_hook_url' => ''}, payload
      svc.receive_push
    end
  end

  def service(*args)
    super Service::Jenkins, *args
  end
end
