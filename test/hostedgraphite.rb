require File.expand_path('../helper', __FILE__)

class HostedGraphiteTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    url = "/integrations/github/"
    @stubs.post url do |env|
      assert_equal "payload=%22payload%22&api_key=test", env[:body]
      [200, {}, '']
    end

    svc = service :push, {'api_key' => 'test'}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::Hostedgraphite, *args
  end
end
