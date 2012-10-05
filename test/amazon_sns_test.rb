require File.expand_path('../helper', __FILE__)

class AmazonSNSTest < Service::TestCase

  def data
    {
      'aws_key' => 'k',
      'aws_secret' => 's',
      'sns_topic' => 't'
     }
  end


  def test_push
    svc = service :push, data, payload
    svc.aws_sdk_sns = aws_sns_stub
    svc.aws_sdk_sqs = aws_sqs_stub

    svc.receive_push

    assert_equal 1, svc.aws_sdk_sns.topics.topic.messages.size
    assert_equal data['aws_key'], svc.data['aws_key']
    assert_equal data['aws_secret'], svc.data['aws_secret']
    assert_equal data['sns_topic'], svc.data['sns_topic']

  end

  def test_push_with_sqs_subscriber

    data_copy = data.clone
    data_copy['sqs_queue'] = 'q'

    svc = service :push, data_copy, payload
    svc.aws_sdk_sns = aws_sns_stub
    svc.aws_sdk_sqs = aws_sqs_stub

    svc.receive_push

    assert_equal 1, svc.aws_sdk_sns.topics.topic.messages.size
    assert_equal data_copy['sqs_queue'], svc.aws_sdk_sns.topics.topic.subscribers[0].name
    assert_equal data_copy['aws_key'], svc.data['aws_key']
    assert_equal data_copy['aws_secret'], svc.data['aws_secret']
    assert_equal data_copy['sns_topic'], svc.data['sns_topic']
    assert_equal data_copy['sqs_queue'], svc.data['sqs_queue']

  end

  def test_requires_aws_key
      data =  {
                'aws_secret' => 's',
                'sns_topic' => 't'
              }
      svc = service :push, data, payload

      assert_raise Service::ConfigurationError do
        svc.receive
      end
  end

  def test_requires_aws_secret
      data =  {
                'aws_key' => 'k',
                'sns_topic' => 't'
              }
      svc = service :push, data, payload

      assert_raise Service::ConfigurationError do
        svc.receive
      end
  end

  def test_requires_sns_topic
      data =  {
                'aws_key' => 'k',
                'aws_secret' => 's'
              }
      svc = service :push, data, payload

      assert_raise Service::ConfigurationError do
        svc.receive
      end
  end

  def test_stubs
    topicName = "stub_topic"
    queueName = "stub_queue"
    message = "this is a test message"
    sns = FakeSNS.new
    topic = sns.topics.create(topicName)
    queue = FakeQueue.new(queueName)
    topic.subscribe(queue)
    topic.publish(message)
    assert_equal 1, topic.messages.size
    assert_equal queueName, topic.subscribers[0].name
  end

  def aws_sns_stub
    FakeSNS.new
  end

  def aws_sqs_stub
    FakeSQS.new
  end

  class FakeSQS
    attr_reader :queues
    def initialize
      @queues ||= FakeQueueCollection.new
    end
  end

  class FakeQueueCollection
    def create(queueName)
         FakeQueue.new(queueName)
    end
  end

  class FakeQueue
    attr_reader :name
    def initialize(name)
      @name = name
    end
  end

  class FakeSNS
    attr_reader :topics
    def initialize
      @topics ||= FakeTopicCollection.new
    end
  end

  class FakeTopicCollection
    attr_reader :topic
    def create(name)
      @topic ||= FakeTopic.new("fakearn:" + name)
    end
  end

  class FakeTopic
    attr_reader :messages
    attr_reader :subscribers

    def initialize arn
      @messages = []
      @subscribers = []
    end
    def subscribe(queue)
      @subscribers << queue
    end
    def publish(message)
      @messages << message
    end
  end

  def service(*args)
    super Service::AmazonSNS, *args
  end
end
