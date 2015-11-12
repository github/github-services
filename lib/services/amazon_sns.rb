require 'aws-sdk-core'
require 'digest'

class Service::AmazonSNS < Service
  self.title = "Amazon SNS"

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

  # Maximum SNS message size is 256 kilobytes.
  MAX_MESSAGE_SIZE = 256 * 1024

  # Size in bytes of each partial message.
  PARTIAL_MESSAGE_SIZE = 128 * 1024

  # Create a new SNS object using the AWS Ruby SDK and publish to it.
  # cfg - Configuration hash of key, secret, etc.
  # json - THe valid JSON payload to send.
  #
  # Returns the instantiated Amazon SNS Object
  def publish_to_sns(cfg, json)
    begin
      sns = Aws::SNS::Client.new({
        :region            => cfg['sns_region'],
        :access_key_id     => cfg['aws_key'],
        :secret_access_key => cfg['aws_secret']
      })

      if json.bytesize <= MAX_MESSAGE_SIZE
        sns.publish({
          :message            => json,
          :topic_arn          => cfg['sns_topic'],
          :message_attributes => message_attributes
        })
      end

      md5_digest = Digest::MD5.hexdigest(json)

      payloads = split_bytes(json, PARTIAL_MESSAGE_SIZE)

      messages = []
      payloads.each_with_index do |payload, i|
        messages << generate_json({
          :error       => "Message exceeds the maximum SNS size limit of 256k",
          :page_total  => payloads.length,
          :page_number => i + 1,
          :md5_digest  => md5_digest,
          :message     => payload
        })
      end

      messages.each do |message|
        sns.publish({
          :message            => message,
          :topic_arn          => cfg['sns_topic'],
          :message_attributes => message_attributes
        })
      end

      rescue Aws::SNS::Errors::AuthorizationErrorException => e
        raise_config_error e.message
      rescue Aws::SNS::Errors::NotFoundException => e
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

  # Build a valid set of message attributes for this message.
  #
  # Returns a valid Hash of message attributes.
  def message_attributes
    {
      "X-Github-Event" => {
        :data_type    => "String",
        :string_value => event.to_s
      }
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

    if data['sns_topic'].to_s.empty? || !data['sns_topic'].downcase[0..3] == 'arn'
      raise_config_error "You need to provide a full SNS Topic ARN"
    end

    data['sns_region'] = "us-east-1" if data['sns_region'].to_s.empty?
  end

  private

  # Split the string into chunks of n bytes.
  #
  # Returns an array of strings.
  def split_bytes(string, n)
    string.bytes.each_slice(n).collect { |bytes| bytes.pack("C*") }
  end

end
