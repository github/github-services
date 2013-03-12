require File.expand_path('../helper', __FILE__)

class LingohubTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_http_call
    @stubs.post "/github_callback" do |env|
      assert_equal 'lingohub.com', env[:url].host
      assert_equal 'a27f34', env[:params]['auth_token']

      [200, {}, '']
    end

    svc = service({'project_token' => 'a27f34'}, :a => 1)
    svc.receive_push
  end

  def test_payload
    @stubs.post "/github_callback" do |env|

      body = Faraday::Utils.parse_nested_query(env[:body])
      received_payload =  JSON.parse(body['payload'])

      assert_equal payload['after'], received_payload['after']

      [200, {}, '']
    end

    svc = service({'project_token' => 'a27f34'}, payload)
    svc.receive_push
  end



  def service(*args)
    super Service::Lingohub, *args
  end
end

