#
# Code taken from jabber.rb and modified to require the
# sender's JID to be part of the hook configuration
#
# Named this xmpp.rb so it could be deployed without breaking
# anyone who is lucky enough to have the jabber.rb work
#
# By specifying the sender JID we avoid depending on jabber.org's
# public server
#

maintained_by :github => 'bear'

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
    messages = []
    messages << "#{summary_message}: #{summary_url}"
    messages += commit_messages
    message = messages.join("\n")

    deliver_messages(message)
  end

  def receive_issues
    message  = "%s\n" % issue.summary_message
    message += "repo: %s\n" % repo.name
    message += "action: %s\n" % issue.action
    message += "state: %s\n" % issue.state
    message += "title: %s\n" % issue.title
    message += "body: %s\n" % issue.body

    deliver_messages(message)
  end

  def deliver_messages(message)
    # Accept any friend request
    im.accept_subscriptions = true

    #Split multiple addresses into array, removing duplicates
    recipients  = data.has_key?('Recipient') ? data['Recipient'].split(',').each(&:strip!).uniq : []

    recipients.each do |recipient|
      im.deliver_deferred recipient, message, :chat
    end
  end

  attr_writer :im
  def im
    @im || @@im ||= build_jabber_connection
  end

  def build_jabber_connection
    user = data['JID']
    pass = data['Password']

    if user.empty? 
      raise_config_error("Missing JID's Password")
    end
    if  pass.empty?
      raise_config_error("Missing JID")
    end

    ::Jabber::Simple.new(data['JID'], data['Password'])
  rescue
    raise_config_error("Unable to connect to XMPP Server: #{user.inspect}")
  end
end
