require File.expand_path('../helper', __FILE__)

class CodefreshTest < Service::TestCase
  include Service::HttpTestMethods

  def test_push_event
    svc = service(:push, {}, payload)

    @stubs.post "/github/PROJECT_ID" do |env|
      body = Faraday::Utils.parse_query env[:body]
      assert_equal "https://g.codefresh.io/api/providers/github/hook", env[:url].to_s
      assert_match 'application/x-www-form-urlencoded', env[:request_headers]['Content-Type']
      assert_equal 'push', env[:request_headers]['X-GitHub-Event']
      assert_equal payload, JSON.parse(body["payload"].to_s)
    end

    svc.receive_event
  end

  private

  def service_class
    Service::Codefresh
  end
end
