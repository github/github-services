require File.expand_path('../helper', __FILE__)

class PushalotTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
    @svc   = service(data, payload)
  end

  def test_reads_token_from_data
    assert_equal "be82304d88d74eb884e384a98a282b8a", @svc.authorization_token
  end

  def test_strips_whitespace_from_token
    svc = service({'authorization_token' => 'be82304d88d74eb884e384a98a282b8a  '}, payload)
    assert_equal 'be82304d88d74eb884e384a98a282b8a', svc.authorization_token
  end

  def test_posts_payload
    @stubs.post '/api/githubhook' do |env|
      assert_equal 'https', env[:url].scheme
      assert_equal 'pushalot.com', env[:url].host
      data = Faraday::Utils.parse_query(env[:body])
      assert_equal "be82304d88d74eb884e384a98a282b8a", data["authorizationToken"]
      assert_equal payload, JSON.parse(data['payload'])
      [200, {}, 'ok']
    end

    @svc.receive_push
  end

private

  def service(*args)
    super Service::Pushalot, *args
  end

  def data
    { 'authorization_token' => 'be82304d88d74eb884e384a98a282b8a' }
  end

end 

