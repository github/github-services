class Service::SqsQueue < Service::HttpPost
  string :aws_access_key, :sqs_queue_name, :aws_sqs_arn
  password :aws_secret_key
  white_list :aws_access_key, :sqs_queue_name, :aws_sqs_arn

  # receive_event()
  def receive_event
    return unless data && payload

    if data['aws_access_key'].to_s.empty?
      raise_config_error "You must define an AWS access key."
    end

    if data['aws_secret_key'].to_s.empty?
      raise_config_error "You must define an AWS secret key."
    end

    if data['sqs_queue_name'].to_s.empty?
      raise_config_error "You must define an SQS queue."
    end

    # Encode payload to JSON
    payload_json_data = generate_json(payload)

    # Send payload to SQS queue
    notify_sqs( access_key(), secret_key(), queue_name(), payload_json_data )
  end

  # notify_sqs()
  # Note: If the queue does not exist, it is automatically created
  def notify_sqs(aws_access_key, aws_secret_key, queue_name, payload)
    sqs = RightAws::SqsGen2.new(aws_access_key, aws_secret_key)
    queue = sqs.queue(queue_name)
    queue.send_message(clean_for_json(payload))
  end

  def access_key
    data['aws_access_key'].strip
  end

  def secret_key
    data['aws_secret_key'].strip
  end

  def queue_name
    has_arn? ? arn[:queue_name] : data['sqs_queue_name'].strip
  end

  def region
    has_arn? ? arn[:region] : 'us-east-1'
  end

  private

  def has_arn?
    data['aws_sqs_arn'].present?
  end

  def arn
    @arn ||= parse_arn
  end

  def parse_arn
    _,_,service,region,id,queue_name = data['aws_sqs_arn'].split(":")
    {service:  service.strip,
     region:   region.strip,
     id:       id.strip,
     queue_name: queue_name.strip
    }
  end
end
