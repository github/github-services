service :jabber do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  recipient  = data['user']
  im         = Jabber::Simple.new(jabber_user, jabber_password)
  
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
