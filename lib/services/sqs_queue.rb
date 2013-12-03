class Service::SqsQueue < Service::HttpPost
  string :aws_access_key, :aws_sqs_arn
  password :aws_secret_key
  # NOTE: at some point, sqs_queue_name needs to be deprecated and removed
  white_list :aws_access_key, :sqs_queue_name, :aws_sqs_arn

  maintained_by github: 'brycem',
                twitter: 'brycemcd'

  def receive_event
    return unless data && payload

    if data['aws_access_key'].to_s.empty?
      raise_config_error "You must define an AWS access key."
    end

    if data['aws_secret_key'].to_s.empty?
      raise_config_error "You must define an AWS secret key."
    end

    if data['sqs_queue_name'].to_s.empty? && data['aws_sqs_arn'].to_s.empty?
      raise_config_error "You must define an SQS queue name or SQS queue ARN."
    end

    # Encode payload to JSON
    payload_json_data = generate_json(payload)

    # Send payload to SQS queue
    notify_sqs( access_key, secret_key, payload_json_data )
  end

  def notify_sqs(aws_access_key, aws_secret_key, payload)
    sqs = AWS::SQS.new(
        access_key_id: access_key,
        secret_access_key: secret_key,
        region: region)
    if data['aws_sqs_arn'] && data['aws_sqs_arn'].match(/^http/)
        queue = sqs.queues[data['aws_sqs_arn']]
    else
        queue = sqs.queues.named(queue_name)
    end
    queue.send_message(clean_for_json(payload))
  end

  def access_key
    data['aws_access_key'].strip
  end

  def secret_key
    data['aws_secret_key'].strip
  end

  def queue_name
    arn[:queue_name] || data['sqs_queue_name'].strip
  end

  def region
    arn[:region] || 'us-east-1'
  end

  private

  def arn
    @arn ||= parse_arn
  end

  def parse_arn
    return {} unless data['aws_sqs_arn'] && !data['aws_sqs_arn'].match(/^http/)
    _,_,service,region,id,queue_name = data['aws_sqs_arn'].split(":")
    {service:  service.strip,
     region:   region.strip,
     id:       id.strip,
     queue_name: queue_name.strip
    }
  end
end
