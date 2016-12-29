class Service::SqsQueue < Service::HttpPost
  self.title = "Amazon SQS"

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
    sqs = sqs_client

    if data['aws_sqs_arn'] && data['aws_sqs_arn'].match(/^http/)
        queue = sqs.queues[data['aws_sqs_arn']]
    else
        queue = sqs.queues.named(queue_name)
    end
    sqs.client.send_message(
      queue_url: queue.url,
      message_body: clean_for_json(payload),
      message_attributes: {
        'X-GitHub-Event' => { string_value: event.to_s, data_type: 'String'}
      }  
    )
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

  def stubbed_requests?
    !!ENV['SQS_STUB_REQUESTS']
  end

  def aws_config
    {
      :region            => region,
      :logger            => stubbed_requests? ? nil : Logger.new(STDOUT),
      :access_key_id     => access_key,
      :secret_access_key => secret_key,
      :stub_requests     => stubbed_requests?,
    }
  end

  def sqs_client
    @sqs_client ||= ::AWS::SQS.new(aws_config)
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
