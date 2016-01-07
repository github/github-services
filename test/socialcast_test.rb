require File.expand_path('../helper', __FILE__)

class SocialcastTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/api/messages.xml" do |env|
      assert_equal 'd', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      data = Faraday::Utils.parse_nested_query(env[:body])
      msg  = data['message']
      assert_match 'Tom Preston-Werner', msg['body']
      assert_match '3 commits', msg['title']
      assert_equal 'g', msg['group_id']
      [200, {}, '']
    end

    svc = service({'username' => 'u', 'password' => 'p',
      'group_id' => 'g', 'api_domain' => 'd'}, payload)
    svc.receive_push
  end

  def service(*args)
    super Service::Socialcast, *args
  end
end

