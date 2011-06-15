# Jabber::Simple does some insane kind of queueing if it thinks
# we are not in their buddy list (which is always) so messages
# never get sent before we disconnect. This forces the library
# to assume the recipient is a buddy.
class ::Jabber::Simple
  def subscribed_to?(x); true; end
end

class Service::Jabber < Service
  def receive_push
    repository = payload['repository']['name']
    branch     = payload['ref_name']

    # Accept any friend request
    im.accept_subscriptions = true

    #Split multiple addresses into array, removing duplicates
    recipients  = data['user'].split(',').uniq.collect(&:strip)
	messages = []
	messages << "#{summary_message}: #{summary_url}"
	messages += commit_messages
    message = messages.join("\n")

    recipients.each do |recipient|
      im.deliver_deferred recipient, message, :chat
    end
  end

#  attr_writer :im
  def im
    @im ||= begin
	  ::Jabber::Simple.new(secrets['jabber']['user'], secrets['jabber']['password'])
	end
  end
end
