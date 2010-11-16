service :amqp do |data, payload|

    EM.run do

        # Connect to the AMQP server
        connection = AMQP.connect(:host    => data['host']     || nil,
                                  :port    => data['port']     || 5672,
                                  :user    => data['username'] || 'guest',
                                  :pass    => data['password'] || 'guest',
                                  :vhost   => data['vhost']    || '/',
                                  :logging => false)

        if !data['host']
            raise GitHub::ServiceConfigurationError, "Invalid server host."
        end

        if !data['exchange']
            raise GitHub::ServiceConfigurationError, "Invalid exchange."
        end

        # Open a channel on the AMQP connection
        channel = MQ.new(connection)

        # Create a topic exchange
        exchange = MQ::Exchange.new(channel,
                                    :topic,
                                    data['exchange'],
                                    :durable => true)

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
        ref   = payload['ref_name']
        routing_key = "github.push.#{owner}.#{repo}.#{ref}"

        # Assemble the push message
        msg = {}
        msg['_meta'] = {
            'routing_key' => routing_key,
            'exchange' => data['exchange'],
        }
        msg['payload'] = payload

        # Publish the push message to the exchange
        exchange.publish(msg.to_json,
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
                'exchange' => data['exchange'],
            }
            msg['payload'] = commit

            # Publish the commit message to the exchange
            exchange.publish(msg.to_json,
                             :key => routing_key,
                             :content_type => 'application/json')
        end
        
        connection.close{ EM.stop_event_loop }

    end

end
