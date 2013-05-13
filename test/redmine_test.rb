require File.expand_path('../helper', __FILE__)

class RedmineTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.get "/a/sys/fetch_changesets" do |env|
      assert_equal 'r.com', env[:url].host
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 'a', env[:params]['key']
      assert_equal 'p', env[:params]['id']
      [200, {}, '']
    end

    svc = service({'address' => 'http://r.com/a/',
      'api_key' => 'a', 'project' => 'p', 'fetch_github_commits' => true }, :a => 1)
    svc.receive_push
  end

  def test_update_issue_module
    @stubs.put "/issues/1234.json" do |env|
      assert_equal 'redmine.org', env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-type']
      assert_equal 'API_KEY-654321', env[:request_headers]['X-Redmine-API-Key']
      assert env[:params]['issue']['notes'].include?("Author: Mahmoud")
      [200, {}, '']
    end
    configurations = {
      'address' => "http://redmine.org", 
      'api_key' => "API_KEY-654321",
      'update_redmine_issues_about_commits' => true
    }
    payloads = {
      'commits' => [ 
                    { 'message' => "FIX Issue #1234", 
                       'timestamp' => "2007-10-10T00:11:02-07:00", 
                       'id' => "b44aa57a6c6c52cc20b9e396cfe3cf97bdfc2b33", 
                       'url' => "https://github.com/modsaid/github-services/commit/b44aa57a6c6c52cc20b9e396cfe3cf97bdfc2b33", 
                       'author' => {'name' => "Mahmoud", 'email' => "modsaid@example.com"}, 
                       'added' => [], 'removed' => [], 'modified' => []
                    }
                  ]
    }
    svc = service(configurations, payloads)
    assert svc.receive_push
  end

  def service(*args)
    super Service::Redmine, *args
  end
end

