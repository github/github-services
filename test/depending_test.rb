require File.expand_path('../helper', __FILE__)

class DependingTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token_from_config
    assert_equal "bf215181b5140522137b3d4f6b73544a", @svc.token
  end

  def test_strips_whitespace_from_config
    svc = service({'token' => 'bf215181b5140522137b3d4f6b73544a  '}, payload)
    assert_equal 'bf215181b5140522137b3d4f6b73544a', svc.token
  end

  def test_post_payload
    @stubs.post '/hook' do |env|
      assert_equal 'http', env[:url].scheme
      assert_equal 'depending.in', env[:url].host
      assert_equal basic_auth('github', 'bf215181b5140522137b3d4f6b73544a'),
        env[:request_headers]['authorization']
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end

    @svc.receive_push
  end

private

  def service(*args)
    super Service::Depending, *args
  end

  def data
    { 'token' => 'bf215181b5140522137b3d4f6b73544a' }
  end

end
