require File.expand_path('../helper', __FILE__)

class Hash
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end

class AmazonSNSTest < Service::TestCase

  # SNS maximum message size is 256 kilobytes.
  SNS_MAX_MESSAGE_SIZE = 256 * 1024

  # Use completely locked down IAM resource.
  def data
    {
      'aws_key' => 'AKIAJV3OTFPCKNH53IBQ',
      'aws_secret' => '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',
      'sns_topic' => 'arn:aws:sns:us-east-1:718656560584:github-service-hook-test',
      'sns_region' => 'us-east-1'
    }
  end

  def payload
    {
      "test" => "true"
    }
  end

  def large_payload
    {
      "test" => 0.to_s * (SNS_MAX_MESSAGE_SIZE + 1)
    }
  end

  def xtest_event
    svc = service :push, data, payload
    sns = svc.receive_event

    assert_equal data['aws_key'], svc.data['aws_key']
    assert_equal data['aws_secret'], svc.data['aws_secret']
    assert_equal data['sns_topic'], svc.data['sns_topic']
    assert_equal data['sns_region'], svc.data['sns_region']
  end

  def verify_requires(svc)
    assert_raises Service::ConfigurationError do
      svc.receive_event
    end
  end

  def verify_nothing_raised(svc)
    assert_nothing_raised do
      svc.receive_event
    end
  end

  def test_requires_aws_key
    verify_requires(service :push, data.except!('aws_key'), payload)
  end

  def test_requires_aws_secret
    verify_requires(service :push, data.except!('aws_secret'), payload)
  end

  def test_requires_sns_topic
    verify_requires(service :push, data.except!('sns_topic'), payload)
  end

  def test_requires_sns_topic
    verify_requires(service :push, data.except!('sns_topic'), payload)
  end

  def test_defaults_sns_region
    svc = service :push, data.except!('sns_region'), payload
    svc.validate_data

    assert_equal svc.data['sns_region'], data['sns_region']
  end

  def test_publish_to_sns
    skip 'aws_key is outdated, and this test will fail. Consider updating/refactoring out aws credentials to re-enable this test'
    verify_nothing_raised(service :push, data, payload)
  end

  def test_payload_exceeds_256K
    skip 'aws_key is outdated, and this test will fail. Consider updating/refactoring out aws credentials to re-enable this test'
    verify_nothing_raised(service :push, data, large_payload)
  end

  def service(*args)
    super Service::AmazonSNS, *args
  end
end
