require File.expand_path('../helper', __FILE__)

class AMQPTest < Service::TestCase
  def setup
    @stubs = Faraday::Adapter::Test::Stubs.new
  end

  def test_push
    data = { 'host' => 'host', 'exchange' => 'exchange' }
    payload = {
      'repository' => {
        'owner' => {'name' => 'owner'},
        'name'  => 'owner/repo'
      },
      'ref_name' => 'ref',
      'commits' => [{
        'author' => {'email' => 'author@email.com'},
        'sha' => 'sha'
      }]
    }

    svc = service(data, payload)
    svc.amqp_connection = connection_stub
    svc.amqp_exchange   = exchange_stub
    svc.receive_push

    routing_key = "github.push.owner.owner/repo.ref"

    assert msg = svc.amqp_exchange.messages.shift
    assert_equal({
      '_meta' => {
        'routing_key' => routing_key,
        'exchange'    => 'exchange'
      },
      'payload' => payload
    }, msg[:body])
    assert_equal routing_key, msg[:key]

    routing_key = "github.commit.owner.owner/repo.ref.author@email.com"
    assert msg = svc.amqp_exchange.messages.shift
    assert_equal({
      '_meta' => {
        'routing_key' => routing_key,
        'exchange'    => 'exchange'
      },
      'payload' => payload['commits'][0]
    }, msg[:body])
    assert_equal routing_key, msg[:key]

    assert_nil svc.amqp_exchange.messages.shift
  end

  def test_requires_data_host
    svc = service({}, 'payload')
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def test_requires_data_exchange
    svc = service({'data' => 'a'}, 'payload')
    assert_raise Service::ConfigurationError do
      svc.receive_push
    end
  end

  def connection_stub
    conn = Object.new
    def conn.close() end
    conn
  end

  def exchange_stub
    FakeExchange.new
  end

  def service(*args)
    super Service::AMQP, *args
  end

  class FakeExchange
    attr_reader :messages

    def initialize
      @messages = []
    end

    def publish(body, options)
      @messages << options.update(:body => JSON.parse(body))
    end
  end
end


