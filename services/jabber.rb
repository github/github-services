# Jabber::Simple does some insane kind of queueing if it thinks
# we are not in their buddy list (which is always) so messages
# never get sent before we disconnect. This forces the library
# to assume the recipient is a buddy.
class Jabber::Simple
  def subscribed_to?(x); true; end
end

service :jabber do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  im         = Jabber::Simple.new(jabber_user, jabber_password)


  # Accept any friend request
  im.accept_subscriptions = true

  #Split multiple addresses into array
  recipients  = data['user'].split(',')

  #Send message to each member in array 
  recipients.each do |recipient|
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

  im.disconnect
end
