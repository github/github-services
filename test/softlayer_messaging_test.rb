require File.expand_path('../helper', __FILE__)

class SoftLayerMessagingTest < Service::TestCase
  include Service::PushHelpers

  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push_topic
    svc = service({"user"=>"test_user", "key"=>"test_apikey",
        "name"=>"test_topic", "account" => "test_account", "topic"=>true}, payload)
    svc.client = fake_client

    svc.receive_push

    payload_json_data = JSON.generate(payload)
    auth = [ "test_user", "test_apikey" ]
    options = {
      :fields => {
        :repository => payload['repository']['name'],
        :owner => payload['repository']['owner']['name'],
        :email => payload['repository']['owner']['email'],
        :ref => payload['ref'],
        :created => payload['created'],
        :forced => payload['forced'],
        :deleted => payload['deleted']
      }
    }
    assert_equal auth, fake_client.called['client.authenticate']
    assert_equal ['test_topic'], fake_client.called['client.topic']
    assert_equal ['test_topic', payload_json_data], fake_client.called['queue.publish'][0,2]
    assert_equal options, fake_client.called['queue.publish'][2]
  end

  def test_push_queue
    svc = service({"user"=>"test_user", "key"=>"test_apikey",
        "name"=>"test_queue", "account" => "test_account", "topic"=>false}, payload)
    svc.client = fake_client

    svc.receive_push

    payload_json_data = JSON.generate(payload)
    auth = [ "test_user", "test_apikey" ]
    options = {
      :fields => {
        :repository => payload['repository']['name'],
        :owner => payload['repository']['owner']['name'],
        :email => payload['repository']['owner']['email'],
        :ref => payload['ref'],
        :created => payload['created'],
        :forced => payload['forced'],
        :deleted => payload['deleted']
      }
    }

    assert_equal auth, fake_client.called['client.authenticate']
    assert_equal ['test_queue'], fake_client.called['client.queue']
    assert_equal ['test_queue', payload_json_data], fake_client.called['queue.push'][0,2]
    assert_equal options, fake_client.called['queue.push'][2]
  end

  def service(*args)
    super Service::SoftLayerMessaging, *args
  end

  def fake_client
    @fake_client ||= FakeSoftLayerClient.new
  end

  class FakeSoftLayerClient
    attr_reader :called

    def initialize
        @called = {}
    end

    def record_call(name, args)
      @called[name] = args
    end

    def queue(name)
      record_call('client.queue', [name])
      FakeTopicQueue.new(name, self) 
    end

    def topic(name)
      record_call('client.topic', [name])
      FakeTopicQueue.new(name, self)
    end

    def authenticate(user, key)
      record_call('client.authenticate', [user, key])
    end

  end

  class FakeTopicQueue
    
    def initialize(name, client)
      @name = name
      @client = client
    end

    def push(payload, options)
      @client.record_call('queue.push', [@name, payload, options]) 
    end

    def publish(payload, options)
      @client.record_call('queue.publish', [@name, payload, options]) 
    end
  end

end
