class Service::Jabber < Service
  string :user
  white_list :user

  def receive_push
    #Split multiple addresses into array, removing duplicates
    recipients  = data.has_key?('user') ? data['user'].split(',').each(&:strip!).uniq : []
    messages = []
    messages << "#{summary_message}: #{summary_url}"
    messages += commit_messages
    message = messages.join("\n")

    deliver_messages(message, recipients)
  end

  def deliver_messages(message, recipients)
    m = ::Jabber::Message.new(nil, message).set_type(:chat)
    recipients.each do |recipient|
      m.set_to(recipient)
      client.send(m)
    end
    disconnect
  end

  def client
    @client ||= begin
      user = secrets['jabber']['user'].to_s
      pass = secrets['jabber']['password'].to_s

      if user.empty? || pass.empty?
        raise_config_error("Missing Jabber user/pass: #{user.inspect}")
      end

      jid = ::Jabber::JID.new(user)
      client = ::Jabber::Client.new(jid)
      client.connect
      client.auth(pass)

      roster = ::Jabber::Roster::Helper.new(client, false)
      roster.add_subscription_request_callback do |roster_item, presence|
        roster.accept_subscription(presence.from)
      end

      presence = ::Jabber::Presence.new(nil, "Available")
      client.send(presence)
      client.send_with_id(::Jabber::Iq.new_rosterget)
      client
    end
  end

  def disconnect
    client.close
    @client = nil
  end

end
