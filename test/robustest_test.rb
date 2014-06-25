require File.expand_path('../helper', __FILE__)

class RobusTestTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/github_web_hook/KEY" do |env|
      assert_equal 'www.robustest.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      [200, {}, '']
    end
    svc = service :push, {'project_key' => 'KEY'}, payload
    svc.receive_push
  end

  def test_issue_comment
    @stubs.post "/github_web_hook/KEY" do |env|
      assert_equal 'www.robustest.com', env[:url].host
      assert_equal 'application/json',
        env[:request_headers]['content-type']
      [200, {}, '']
    end

    svc = service :push, {'project_key' => 'KEY'}, payload
    svc.receive_push
  end

  def test_commit
    configurations = {
      'project_key' => "5773638368231424",
    }
    payloads = {
      'commits' => [
                    { 'message' => "Fixed an annoying bug [#210 transition:31 resolution:1]",
                       'timestamp' => "2007-10-10T00:11:02-07:00",
                       'id' => "b44aa57a6c6c52cc20b9e396cfe3cf97bdfc2b33",
                       'url' => "https://github.com/modsaid/github-services/commit/b44aa57a6c6c52cc20b9e396cfe3cf97bdfc2b33",
                       'author' => {'name' => "Mahmoud", 'email' => "demo@robustest.com"},
                       'added' => [], 'removed' => [], 'modified' => []
                    }
                  ]
    }
    svc = service(configurations, payloads)
    assert svc.receive_push
  end

  def service(*args)
    super Service::RobusTest, *args
  end
end

