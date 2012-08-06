require File.expand_path('../helper', __FILE__)

class RedmineIssueUpdateTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @payloads = {
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
  end

  def test_push
    @stubs.put "/issues/1234.json" do |env|
      assert_equal 'redmine.org', env[:url].host
      assert_equal 'application/json', env[:request_headers]['Content-type']
      assert_equal 'API_KEY-654321', env[:request_headers]['X-Redmine-API-Key']
      assert_equal '1234', env[:params]['id']
      form = Rack::Utils.parse_query(env[:body])
      assert_equal 'text', form['issue[notes]']
      [200, {}, '']
    end
    configurations = {
      'redmine_url' => "http://redmine.org", 
      'api_key' => "API_KEY-654321"
    }
    svc = service(configurations, @payloads)
    assert svc.receive_push
  end

  def test_invalid_redmine_url
   
    configurations = {
      'redmine_url' => "https://www.invaliddd.ok", 
      'api_key' => "API_KEY-654321"
    }

    svc = service(configurations, @payloads)
    assert !svc.receive_push
  end

  def service(*args)
    super Service::RedmineIssueUpdate, *args
  end
end