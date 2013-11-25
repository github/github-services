require File.expand_path('../helper', __FILE__)

class Hash
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end

class AmazonSNSTest < Service::TestCase

  def data
    {
      'aws_key' => 'k',
      'aws_secret' => 's',
      'sns_topic' => 't',
      'sns_region' => 'us-east-1'
    }
  end

  def test_event
    svc = service :push, data, payload
    svc.aws_sns = aws_sns_stub

    svc.receive_event

    assert_nil svc.aws_sns.topics.topic_by_arn
    assert_equal 1, svc.aws_sns.topics.topic.messages.size
    assert_equal 'fakearn:t', svc.aws_sns.topics.topic.arn

    assert_equal data['aws_key'], svc.data['aws_key']
    assert_equal data['aws_secret'], svc.data['aws_secret']
    assert_equal data['sns_topic'], svc.data['sns_topic']
    assert_equal data['sns_region'], svc.data['sns_region']

  end

  def test_event_with_topic_arn
    data_copy = data.merge('sns_topic' => 'arn:aws:sns:us-east-1:111222333444:t')
    svc = service :push, data_copy, payload
    svc.aws_sns = aws_sns_stub

    svc.receive_event

    assert_nil svc.aws_sns.topics.topic
    assert_equal 1, svc.aws_sns.topics.topic_by_arn.messages.size
    
    assert_equal 'arn:aws:sns:us-east-1:111222333444:t', svc.aws_sns.topics.topic_by_arn.arn
    assert_equal data_copy['aws_key'], svc.data['aws_key']
    assert_equal data_copy['aws_secret'], svc.data['aws_secret']
    assert_equal data_copy['sns_topic'], svc.data['sns_topic']
    assert_equal data_copy['sns_region'], svc.data['sns_region']

  end

  def test_require(svc)
    assert_raise Service::ConfigurationError do
      svc.receive_event
    end
  end

  def test_requires_aws_key
    test_require(service :push, data.except!(:aws_key), payload)
  end

  def test_requires_aws_secret
    test_require(service :push, data.except!(:aws_secret), payload)
  end

  def test_requires_sns_topic
    test_require(service :push, data.except!(:sns_topic), payload)
  end

  def test_requires_sns_topic
    test_require(service :push, data.except!(:sns_topic), payload)
  end

  def test_defaults_sns_region
    svc = service :push, data.except!(:sns_region), payload
    svc.validate_data

    assert_equal svc.data['sns_region'], data[:sns_region]
  end

  def test_stubs
    topicName = "stub_topic"
    queueName = "stub_queue"
    message = "this is a test message"
    sns = FakeSNS.new
    topic = sns.topics.create(topicName)
    topic.publish(message)
    assert_equal 1, topic.messages.size
  end

  def aws_sns_stub
    FakeSNS.new
  end

  class FakeSNS
    attr_reader :topics
    def initialize
      @topics ||= FakeTopicCollection.new
    end
  end

  class FakeTopicCollection
    attr_reader :topic, :topic_by_arn
    def create(name)
      @topic ||= FakeTopic.new("fakearn:" + name)
    end
    # Refer by topic ARN (see AWS::SNS::TopicCollection):
    def [](topic_arn)
      @topic_by_arn ||= FakeTopic.new(topic_arn)
    end
  end

  class FakeTopic
    attr_reader :arn
    attr_reader :messages
    attr_reader :subscribers

    def initialize arn
      @arn = arn
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
