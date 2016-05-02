require File.expand_path('../helper', __FILE__)

class CodeClimateTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, {'commits'=>[{'id'=>'test'}]})
  end

  def test_reads_token_from_data
    assert_equal "5373dd4a3648b88fa9acb8e46ebc188a", @svc.token
  end

  def test_strips_whitespace_from_token
    svc = service({'token' => '5373dd4a3648b88fa9acb8e46ebc188a  '}, payload)
    assert_equal '5373dd4a3648b88fa9acb8e46ebc188a', svc.token
  end

  def test_posts_payload
    @stubs.post '/github_events' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'codeclimate.com', env[:url].host
      assert_equal basic_auth('github', '5373dd4a3648b88fa9acb8e46ebc188a'),
        env[:request_headers]['authorization']
      assert JSON.parse(env[:body]).keys.include?("payload")
      assert_equal "test", JSON.parse(env[:body])["payload"]["commits"][0]["id"]
    end

    @svc.receive_event
  end

private

  def service(*args)
    super Service::CodeClimate, *args
  end

  def data
    { 'token' => '5373dd4a3648b88fa9acb8e46ebc188a' }
  end

end
