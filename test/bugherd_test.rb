require File.expand_path('../helper', __FILE__)

class BugHerdTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/github_web_hook/KEY" do |env|
      assert_equal 'www.bugherd.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, {'project_key' => 'KEY'}, payload
    svc.receive_push
  end

  def test_issues
    @stubs.post "/github_web_hook/KEY" do |env|
      assert_equal 'www.bugherd.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, {'project_key' => 'KEY'}, payload
    svc.receive_issues
  end

  def test_issue_comment
    @stubs.post "/github_web_hook/KEY" do |env|
      assert_equal 'www.bugherd.com', env[:url].host
      assert_equal 'application/x-www-form-urlencoded',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, {'project_key' => 'KEY'}, payload
    svc.receive_issue_comment
  end

  def service(*args)
    super Service::BugHerd, *args
  end
end
