JABBER_USER = "github-services@jabber.org"
JABBER_PASSWORD = "g1thub"

service :jabber do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  recipient  = data['user']
  puts "*** Connecting" if $DEBUG
  im         = Jabber::Simple.new(JABBER_USER, JABBER_PASSWORD)
  
  # Accept any friend request
  im.accept_subscriptions = true
  
  payload['commits'].each do |sha1, commit|
    puts "*** Sending commit #{sha1[0..6]}" if $DEBUG
    im.deliver recipient, <<EOM
#{repository}: #{commit['author']['name']} #{branch} SHA1-#{sha1[0..6]}"

#{commit['message']}
#{commit['url']}
EOM
  end

  im.disconnect
end
