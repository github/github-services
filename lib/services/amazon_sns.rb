require 'aws/sns'
require 'aws/sqs'

class Service::AmazonSNS < Service
  string :aws_key, :aws_secret, :sns_topic, :sqs_queue
  white_list :aws_key, :sns_topic, :sqs_queue
  password :aws_secret

  def receive_event
    raise_config_error "Missing 'aws_key'"    if data['aws_key'].to_s == ''
    raise_config_error "Missing 'aws_secret'" if data['aws_secret'].to_s == ''
    raise_config_error "Missing 'sns_topic'" if data['sns_topic'].to_s == ''

    t = get_topic(data['sns_topic'])

    if(data['sqs_queue'].to_s != '')
      q = aws_sdk_sqs.queues.create(data['sqs_queue'])
      t.subscribe(q)
    end

    t.publish(generate_json(payload))
  end

  attr_writer :aws_sdk_sqs
  def aws_sdk_sqs
    @aws_sdk_sqs ||= AWS::SQS.new(aws_config)
  end

  attr_writer :aws_sdk_sns
  def aws_sdk_sns
    @aws_sdk_sns ||= AWS::SNS.new(aws_config)
  end

  def aws_config
    {:access_key_id=>data['aws_key'], :secret_access_key=>data['aws_secret']}
  end

  def get_topic(name_or_arn)
    if name_or_arn =~ /^arn:aws:sns:/
      aws_sdk_sns.topics[name_or_arn]
    else
      aws_sdk_sns.topics.create(name_or_arn)
    end
  end
end
