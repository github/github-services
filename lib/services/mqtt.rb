class Service::MqttPub < Service
  self.title = 'MQTT publish'

  string   :broker, :port, :topic, :clientid, :user
  password :pass
  boolean  :retain

  require 'mqtt'

  def receive_push

    # Optional - use m2m.io public broker if not specified
    broker = data['broker'].to_s
    if broker == ''
      broker = 'q.m2m.io'
    end

    # Optional - use standard MQTT port if not specified
    port = data['port'].to_i
    if data['port'].to_s == ''
      port = 1883
    end

    if data['topic'].to_s == ''
      raise_config_error "Invalid topic. Try github/<github_username>/<repo_name> ."
    end

    # Optional - generate random epoch for ID if not specified
    clientid = data['clientid'].to_s
    if clientid == ''
      # Random ID doesn't make sense, but use prefix like MQTT::generate_client_id
      clientid = 'github_' + Time.now.to_i.to_s
    end

    # Optional, specify nil if not specified (per http://rubydoc.info/gems/mqtt/MQTT/Client)
    user = data['user'].to_s
    if user == ''
      user = nil
    end

    # Optional, specify nil if not specified
    pass = data['pass'].to_s
    if pass == ''
      pass = nil
    end

    # Handle specifying a username or a password, but not both
    if user != nil and pass == nil
       raise_config_error "You specified a username without a password."
    end

    if pass != nil and user == nil
       raise_config_error "You specified a password without a username."
    end

    begin
      # Connect to the broker, publish the payload!
      MQTT::Client.connect(
        :remote_host => broker,
        :remote_port => port,
        :client_id => clientid,
        :username => user,
        :password => pass
      ) do |client|
          client.publish(data['topic'].to_s, generate_json(payload), retain=data['retain'])
          # Disconnect (don't send last will and testament)
          client.disconnect(false)
        end
    rescue SocketError => e
      warn "SocketError occurred: " + e
    end

  end
end

