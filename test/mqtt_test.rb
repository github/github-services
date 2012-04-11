require File.expand_path('../helper', __FILE__)

class MQTTTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    svc = Service::MyService.new(:push, {'broker' => 'q.m2m.io', 'port' => '1883', 'topic' => 'github/myusername/github-services'})
    svc.receive_push
  end
end


