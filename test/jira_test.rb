require File.expand_path('../helper', __FILE__)

class JIRATest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/a/rest/api/a/issue/1/transitions" do |env|
      assert_equal 'application/json', env[:request_headers]['Content-Type']
      assert_equal 'foo.com', env[:url].host
      [200, {}, '']
    end

    svc = service(
      {'server_url' => 'http://foo.com/a', 'username' => 'u', 'password' => 'p',
       'api_version' => 'a'},
      payload)
    svc.receive_push
  end

  def service(*args)
    super Service::JIRA, *args
  end
end
