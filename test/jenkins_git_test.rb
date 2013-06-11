require File.expand_path('../helper', __FILE__)

class JenkinsGitTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @options = {'jenkins_url' => 'http://monkey:secret@jenkins.example.com/jenkins/'}
  end

  def test_push
    @stubs.get "/jenkins/git/notifyCommit" do |env|
      assert_equal 'jenkins.example.com', env[:url].host

      assert_equal 'Basic bW9ua2V5OnNlY3JldA==', env[:request_headers]['authorization']

      params = Faraday::Utils.parse_nested_query(env[:url].query)
      expected_params = {
        'url' => 'http://github.com/mojombo/grit',
        'branches' => 'master',
        'from' => 'github'
      }
      assert_equal(expected_params, params)

      [200, {}, '']
    end

    service(@options, payload).receive_push

    @stubs.verify_stubbed_calls
  end

  def test_no_jenkins_hook_url
    assert_raises Service::ConfigurationError do
      service({'jenkins_url' => ''}, payload).receive_push
    end
  end

  def service(*args)
    super Service::JenkinsGit, *args
  end
end
