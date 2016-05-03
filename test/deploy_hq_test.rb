require File.expand_path('../helper', __FILE__)

class DeployHqTest < Service::TestCase

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    @stubs.post '/deploy/projectname/to/servername/serverkey' do |env|
      assert_equal 'test.deployhq.com', env[:url].host
      assert_equal 'https', env[:url].scheme
      post_payload = JSON.parse(Faraday::Utils.parse_query(env[:body])['payload'])

      refute_nil payload['after']
      assert_equal post_payload['after'], post_payload['after']
      refute_nil post_payload['ref']
      assert_equal payload['ref'], post_payload['ref']
      refute_nil post_payload['repository']['url']
      assert_equal payload['repository']['url'], post_payload['repository']['url']
      assert_equal payload['pusher']['email'], post_payload['pusher']['email']

      [201, [], '']
    end

    svc = service :push, { 'deploy_hook_url' => 'https://test.deployhq.com/deploy/projectname/to/servername/serverkey' }, payload
    svc.receive_push
  end

  def service(*args)
    super Service::DeployHq, *args
  end

end
