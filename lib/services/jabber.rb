# Jabber::Simple does some insane kind of queueing if it thinks
# we are not in their buddy list (which is always) so messages
# never get sent before we disconnect. This forces the library
# to assume the recipient is a buddy.
class ::Jabber::Simple
  def subscribed_to?(x); true; end
end

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
      im.deliver_deferred recipient, message, :chat
    end
  end

  attr_writer :im
  def im
    @im || @@im ||= build_jabber_connection
  end

  def build_jabber_connection
    user = secrets['jabber']['user'].to_s
    pass = secrets['jabber']['password'].to_s

    if user.empty? || pass.empty?
      raise_config_error("Missing Jabber user/pass: #{user.inspect}")
    end

    ::Jabber::Simple.new(secrets['jabber']['user'], secrets['jabber']['password'])
  rescue
    raise_config_error("Troubles connecting to Jabber: #{user.inspect}")
  end
end
