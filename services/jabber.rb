class Service::Jabber < Service
  string :user
  white_list :user

  def receive_push
    # Accept any friend request
    im.accept_subscriptions = true

    #Split multiple addresses into array, removing duplicates
    recipients  = data.has_key?('user') ? data['user'].split(',').each(&:strip!).uniq : []
    messages = []
    messages << "#{summary_message}: #{summary_url}"
    messages += commit_messages
    message = messages.join("\n")

    deliver_messages(message, recipients)
  end

  def deliver_messages(message, recipients)
    recipients.each do |recipient|
      im.write ::Blather::Stanza::Message.new(recipient, message, :chat)
    end
  end

  attr_writer :im
  def im
    @im || @@im ||= begin
      ::Blather::Client.setup(secrets['jabber']['user'], secrets['jabber']['password']))
    end
  end
end
