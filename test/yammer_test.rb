require File.expand_path('../helper', __FILE__)

class YammerTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token_from_data
    assert_equal "a4f1200fc99331027ab1239%3D%3D", @svc.token
  end

  def test_strips_whitespace_from_token
    svc = service({'token' => 'a4f1200fc99331027ab1239%3D%3D  '}, payload)
    assert_equal 'a4f1200fc99331027ab1239%3D%3D', svc.token
  end

  def test_posts_payload
    @stubs.post '/a4f1200fc99331027ab1239%3D%3D/notify/push' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'yammer-github.herokuapp.com', env[:url].host
      assert_equal '/a4f1200fc99331027ab1239%3D%3D/notify/push', env[:url].path
      assert_equal payload, JSON.parse(Rack::Utils.parse_query(env[:body])['payload'])
    end

    @svc.receive_push
  end

private

  def service(*args)
    super Service::Yammer, *args
  end

  def data
    { 'token' => 'a4f1200fc99331027ab1239%3D%3D' }
  end

end
