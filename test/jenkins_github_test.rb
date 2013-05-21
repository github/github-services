require File.expand_path('../helper', __FILE__)

class JenkinsGitHubTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_single_endpoint
    @stubs.post "/github-webhook/" do |env|
      assert_equal 'jenkins.example.com', env[:url].host
      assert_equal 'Basic bW9ua2V5OnNlY3JldA==',
        env[:request_headers]['authorization']
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push,
      {'jenkins_hook_urls' => 'http://monkey:secret@jenkins.example.com/github-webhook/'}, payload
    svc.receive_push
  end

  def test_push_with_multiple_endpoints
    svc = service :push,
      {'jenkins_hook_urls' => 
      'http://monkey:secret@jenkins.example1.com/github-webhook/ http://monkey:secret@jenkins.example2.com/github-webhook/'}, payload

    (1..2).each do |endpoint|
      @stubs.post "/github-webhook/" do |env|
        assert_equal "jenkins.example#{endpoint}.com", env[:url].host
        assert_equal 'Basic bW9ua2V5OnNlY3JldA==',
          env[:request_headers]['authorization']
        assert_equal 'application/x-www-form-urlencoded',
          env[:request_headers]['content-type']
        [200, {}, '']
      end
    end
    svc.receive_push
  end

  def test_no_jenkins_hook_url
    assert_raises Service::ConfigurationError do
      svc = service :push,
        {'jenkins_hook_urls' => ''}, payload
      svc.receive_push
    end
  end

  def service(*args)
    super Service::JenkinsGitHub, *args
  end
end
