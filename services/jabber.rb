# Jabber::Simple does some insane kind of queueing if it thinks
# we are not in their buddy list (which is always) so messages
# never get sent before we disconnect. This forces the library
# to assume the recipient is a buddy.
class ::Jabber::Simple
  def subscribed_to?(x); true; end
end

class Service::Jabber < Service
  def receive_push
    raise_config_error "jabber hook temporarily disabled"

    repository = payload['repository']['name']
    branch     = payload['ref_name']

    # Accept any friend request
    im.accept_subscriptions = true

    #Split multiple addresses into array, removing duplicates
    recipients  = data['user'].split(',').uniq.collect(&:strip)

    #Send message to each member in array (Limit to 25 members to prevent overloading something, if this is not and issue, just remove the [0..24] from recipients
    recipients[0..24].each do |recipient|
      # Ask recipient to be our buddy if need be
      im.add(recipient)

      payload['commits'].each do |commit|
        sha1 = commit['id']
        im.deliver recipient, <<EOM
#{repository}: #{commit['author']['name']} #{branch} SHA1-#{sha1[0..6]}"

#{commit['message']}
#{commit['url']}
EOM
      end
    end
  end

  attr_writer :im
  def im
    @im ||= Jabber::Simple.new(secrets['jabber']['user'], secrets['jabber']['password'])
  end
end
