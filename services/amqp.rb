class Service::AMQP < Service
  string   :server, :port, :vhost, :exchange, :username
  password :password

  def receive_push
    # Support for specifying as host or server
    data['host'] ||= data['server']

    if !data['host']
      raise_config_error "Invalid server host."
    end

    if !data['exchange']
      raise_config_error "Invalid exchange."
    end

    # Modify the commits a bit
    payload['commits'].each do |commit|
      commit['files'] = {
          'added'    => commit['added'],
          'modified' => commit['modified'],
          'removed'  => commit['removed'],
      }
      commit.delete('added')
      commit.delete('modified')
      commit.delete('removed')
    end

    # Generate the push routing key
    owner = payload['repository']['owner']['name']
    repo  = payload['repository']['name']
    ref   = ref_name
    routing_key = "github.push.#{owner}.#{repo}.#{ref}"

    # Assemble the push message
    msg = {}
    msg['_meta'] = {
      'routing_key' => routing_key,
      'exchange'    => data['exchange'],
    }
    msg['payload'] = payload

    # Publish the push message to the exchange
    amqp_exchange.publish(msg.to_json,
                          :key => routing_key,
                          :content_type => 'application/json')

    # Publish individual commit messages
    payload['commits'].each do |commit|
      # Generate the commit routing key
      author = commit['author']['email']
      routing_key = "github.commit.#{owner}.#{repo}.#{ref}.#{author}"

      # Assemble the commit message
      msg = {}
      msg['_meta'] = {
          'routing_key' => routing_key,
          'exchange'    => data['exchange'],
      }
      msg['payload'] = commit

      # Publish the commit message to the exchange
      amqp_exchange.publish(msg.to_json,
                            :key => routing_key,
                            :content_type => 'application/json')
    end

    amqp_connection.close
  end

  attr_writer :amqp_connection
  attr_writer :amqp_exchange

  def amqp_exchange
    @amqp_exchange ||= MQ::Exchange.new(amqp_channel,
                                        :topic,
                                        data['exchange'],
                                        :durable => true)
  end

  def amqp_channel
    @amqp_channel ||= MQ.new(amqp_connection)
  end

  def amqp_connection
    @amqp_connection ||= ::AMQP.connect(:host    => data['host'],
                                      :port    => data['port']     || 5672,
                                      :user    => data['username'] || 'guest',
                                      :pass    => data['password'] || 'guest',
                                      :vhost   => data['vhost']    || '/',
                                      :logging => false)
  end
end
