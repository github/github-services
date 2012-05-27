# Jabber::Simple does some insane kind of queueing if it thinks
# we are not in their buddy list (which is always) so messages
# never get sent before we disconnect. This forces the library
# to assume the recipient is a buddy.
class ::Jabber::Simple
  def subscribed_to?(x); true; end
end

# Default implementation of MUCClient uses blocked connection
class ::Jabber::MUC::MUCClient
  def join(jid, password=nil)
    raise "MUCClient already active" if active?

    @jid = (jid.kind_of?(::Jabber::JID) ? jid : ::Jabber::JID.new(jid))
    activate

    pres = ::Jabber::Presence.new
    pres.to = @jid
    pres.from = @my_jid
    xmuc = ::Jabber::MUC::XMUC.new
    xmuc.password = password
    pres.add xmuc

    @stream.send pres

    self
  end
end

class Service::Jabber < Service
  string :user
  white_list :user

  def receive_push
    # Accept any friend request
    im.accept_subscriptions = true

    #Split multiple addresses into array, removing duplicates
    recipients  = data.has_key?('user') ? data['user'].split(',').each(&:strip!).uniq : []
    conferences = data.has_key?('muc') ? data['muc'].split(',').each(&:strip!).uniq : []
    messages = []
    messages << "#{summary_message}: #{summary_url}"
    messages += commit_messages
    message = messages.join("\n")

    deliver_messages(message, recipients)

    # temporarily disabled
    #deliver_muc(message, conferences) if !conferences.empty?
  end

  def deliver_messages(message, recipients)
    recipients.each do |recipient|
      im.deliver_deferred recipient, message, :chat
    end
  end

  def deliver_muc(message, conferences)
    conferences.each do |conference|
      muc = ::Jabber::MUC::MUCClient.new(im.client)
      muc.join(conference)
      im.deliver_deferred conference, message, :groupchat
    end
  end

  def mucs
    @mucs ||= {}
  end

  attr_writer :im
  def im
    @im || @@im ||= begin
      ::Jabber::Simple.new(secrets['jabber']['user'], secrets['jabber']['password'])
    end
  end
end
