require File.expand_path('../helper', __FILE__)

class CodeClimateTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token_from_data
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.token
  end

  def test_strips_whitespace_from_token
    svc = service({'token' => '5373dd4a3648b88fa9acb8e46ebc188a  '}, payload)
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
  end

  def test_posts_payload
    @stubs.post '/github_pushes' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'codeclimate.com', env[:url].host
      assert_equal basic_auth('github', '5373dd4a3648b88fa9acb8e46ebc188a'),
        env[:request_headers]['authorization']
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
    end

    @svc.receive_push
  end

private

  def service(*args)
    super Service::CodeClimate, *args
  end

  def data
    { 'token' => '5373dd4a3648b88fa9acb8e46ebc188a' }
  end

end
