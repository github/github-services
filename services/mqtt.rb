class Service::MQTT < Service
  string :broker, :port, :topic

  self.title = 'MQTT'

  def receive_push
    if !data['broker']
      raise_config_error 'Invalid broker URL.'
    end

    if !data['port']
      raise_config_error 'Invalid port. Try 1883.'
    end
    
    if !data['topic']
      raise_config_error 'Invalid topic. Try github/<github_username>/<repo_name>'
    end
    
    # Connect to the broker, publish the payload!
    MQTT::Client.connect(data['broker'], data['port'].to_i) do |client|
      client.publish(data['topic'], payload)
      # Disconnect (don't send last will and testament)
      client.disconnect(false)
    end

  end
  

end
