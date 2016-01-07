class Service::SoftLayerMessaging < Service
  string :account, :user, :name
  password :key
  boolean :topic
  white_list :account, :user, :name

  attr_writer :client

  # receive_push
  def receive_push
    return unless data && payload

    if data['account'].to_s.empty?
      raise_config_error "You must define an publishing account."
    end

    if data['user'].to_s.empty?
      raise_config_error "You must define an authorized user."
    end

    if data['name'].to_s.empty?
      raise_config_error "You must define a queue/topic name."
    end

    if data['key'].to_s.empty?
      raise_config_error "You must provide the api key."
    end

    publish_message(account, user, apikey, name, data['topic'], payload)

  end

  # publish_message
  def publish_message(account, user, key, name, topic, payload)
    client.authenticate(user, key)
    # mungle
    options = {
      :fields => {
        :repository => payload['repository']['name'],
        :owner => payload['repository']['owner']['name'],
        :email => payload['repository']['owner']['email'],
        :ref => payload['ref'],
        :created => payload['created'],
        :forced => payload['forced'],
        :deleted => payload['deleted']
      }
    }

    # Encode payload to JSON
    # hopefully not bigger than 64K
    payload_json_data = generate_json(payload)

  begin
   if topic
        push_to_topic(name, payload_json_data, options)
    else
        push_to_queue(name, payload_json_data, options)
    end

    rescue RestClient::ServerBrokeConnection => broken
      raise_config_error "Disconnected #{broken.to_s}"
    rescue RestClient::ExceptionWithResponse => req
      case req.http_code
      when 404
        raise_config_error 'Topic or Queue not created prior to publishing'
      when 401
        raise_config_error 'Bad SoftLayer messaging authentication information'
      else
        raise_config_error "Unhandled SoftLayer response: #{req}"
      end
    end
  end

  def push_to_topic(name, payload, options={})
    topic = client.topic(name)
    topic.publish(payload, options)
  end

  def push_to_queue(name, payload, options={})
    queue = client.queue(name)
    queue.push(payload, options)
  end

  def client
    @client ||= SL::Messaging::Client.new(data['account'])
  end

  def account
    data['account'].strip
  end

  def apikey
    data['key'].strip
  end

  def user
    data['user'].strip
  end

  def name
    data['name'].strip
  end

end
