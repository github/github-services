require File.expand_path('../helper', __FILE__)

class Commandoio < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post "v1/recipes/_______mock_recipe_______/execute" do |env|
      body = Faraday::Utils.parse_query(env[:body])
      payload = JSON.parse(body['payload'])

      assert_equal 'api.commando.io', env[:url].host
      assert_equal 'https', env[:url].scheme
      assert_match 'application/x-www-form-urlencoded', env[:request_headers]['content-type']
      assert_equal payload, JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])
      assert_equal basic_auth('demo', 'skey_abcdsupersecretkey'),
        env[:request_headers]['authorization']
      [200, {}, '']
    end

    svc = service :push, {
      'api_token_secret_key'  => 'skey_abcdsupersecretkey',
      'account_alias'         => 'demo',
      'recipe'                => '_______mock_recipe_______',
      'server'                => '_server_',
      'notes'                 => 'Test the mock recipe!'
    }
    svc.receive_event
  end

  def service(*args)
    super Service::Commandoio, *args
  end
end
