require File.expand_path('../helper', __FILE__)

class MqttPubTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = service :push, {'broker' => 'q.m2m.io','port' => '1883', 'id' => 'github', 'topic' => 'github/franklovecchio/github-services'}, 'payload'
    svc.receive
  end

  def service(*args)
    super Service::MqttPub, *args
  end
end
