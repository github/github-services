require File.expand_path('../helper', __FILE__)

class Hash
  def except!(*keys)
    keys.each { |key| delete(key) }
    self
  end
end

class AmazonSNSTest < Service::TestCase

  #Use completely locked down IAM resource.
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

  def xtest_event
    svc = service :push, data, payload
    sns = svc.receive_event

    assert_equal data['aws_key'], svc.data['aws_key']
    assert_equal data['aws_secret'], svc.data['aws_secret']
    assert_equal data['sns_topic'], svc.data['sns_topic']
    assert_equal data['sns_region'], svc.data['sns_region']
  end

  def verify_requires(svc)
    assert_raise Service::ConfigurationError do
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

  def service(*args)
    super Service::AmazonSNS, *args
  end
end
