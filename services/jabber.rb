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
  recipient  = data['user']
  im         = Jabber::Simple.new(jabber_user, jabber_password)

  # Ask recipient to be our buddy if need be
  im.add(recipient)

  # Accept any friend request
  im.accept_subscriptions = true

  payload['commits'].each do |commit|
    sha1 = commit['id']
    im.deliver recipient, <<EOM
#{repository}: #{commit['author']['name']} #{branch} SHA1-#{sha1[0..6]}"

#{commit['message']}
#{commit['url']}
EOM
  end

  im.disconnect
end
