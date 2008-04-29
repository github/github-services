service :campfire do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  campfire.login data['email'], data['password']
  room       = campfire.find_room_by_name data['room']
  payload['commits'].each do |commit|
    commit = commit.last
    text   = "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
    room.speak text
  end
end