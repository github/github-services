require 'aws/sns'
require 'aws/sqs'

class Service::AmazonSNS < Service

  string :aws_key, :sns_topic, :sns_region

  password :aws_secret

  white_list :aws_key, :sns_topic, :sns_region

  url "http://aws.amazon.com/console"

  maintained_by :github => "davidkelley"

  # Manage an event. Validate the data that has been received
  # and then publish to SNS.
  #
  # Returns nothing.
  def receive_event
    validate_data
    publish_to_sns(data, generate_json(payload))
  end

  # Create a new SNS object using the AWS Ruby SDK and publish to it.
  # cfg - Configuration hash of key, secret, etc.
  # json - THe valid JSON payload to send.
  #
  # Returns the instantiated Amazon SNS Object
  def publish_to_sns(cfg, json)
    begin
      # older version of AWS SDK does not support region configuration
      # http://ruby.awsblog.com/post/TxVOTODBPHAEP9/Working-with-Regions
      AWS.config(sns_endpoint: "sns.#{cfg['sns_region']}.amazonaws.com")
      sns = AWS::SNS.new(config(cfg['aws_key'], cfg['aws_secret']))
      topic = sns.topics[cfg['sns_topic']]
      topic.publish(json)
      return sns

    rescue AWS::SNS::Errors::AuthorizationError,
           AWS::SNS::Errors::InvalidClientTokenId,
           AWS::SNS::Errors::SignatureDoesNotMatch => e
      raise_config_error e.message
    rescue AWS::SNS::Errors::NotFound => e
      raise_missing_error e.message
    rescue SocketError
      raise_missing_error
    end
  end

  # Build a valid AWS Configuration hash using the supplied
  # parameters.
  #
  # Returns a valid AWS Config Hash.
  def config(key, secret)
    {
      access_key_id: key,
      secret_access_key: secret,
    }
  end

  # Validate the data that has been passed to the event. 
  # An AWS Key & Secret are required. As well as the ARN of an SNS topic.
  # Defaults region to us-east-1 if not set.
  #
  # Returns nothing
  def validate_data
    if data['aws_key'].to_s.empty? || data['aws_secret'].to_s.empty?
      raise_config_error "You need to provide an AWS Key and Secret Access Key"
    end

    if data['sns_topic'].to_s.empty? || !data['sns_topic'].downcase.starts_with?('arn')
      raise_config_error "You need to provide a full SNS Topic ARN"
    end

    data['sns_region'] = "us-east-1" if data['sns_region'].to_s.empty?
  end

end
