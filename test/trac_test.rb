require File.expand_path('../helper', __FILE__)

class TracTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "/s/github/t" do |env|
      assert_equal 's.trac.com', env[:url].host
      assert_equal basic_auth(:u, :p), env[:request_headers]['authorization']
      data = Faraday::Utils.parse_nested_query(env[:body])
      assert_equal 1, JSON.parse(data['payload'])['a']
      [200, {}, '']
    end

    svc = service({'url' => 'http://u:p@s.trac.com/s', 'token' => 't'}, :a => 1)
    svc.receive_push
  end

  def service(*args)
    super Service::Trac, *args
  end
end

