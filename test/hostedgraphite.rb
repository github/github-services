require File.expand_path('../helper', __FILE__)

class HostedGraphiteTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/integrations/github/"
    @stubs.post url do |env|
      params = Faraday::Utils.parse_query env[:body]
      assert_equal 'payload', JSON.parse(params['payload'])
      assert_equal 'test', params['api_key']
      [200, {}, '']
    end

    svc = service :push, {'api_key' => 'test'}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::Hostedgraphite, *args
  end
end
