service :campfire do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)

  throw(:halt, 400) unless campfire && campfire.login(data['email'], data['password'])
  throw(:halt, 400) unless room = campfire.find_room_by_name(data['room'])

  if payload['commits'].last && payload['commits'].last['message'] =~ /^Merge/ && payload['commits'].last['message'] !~ /\sof\s/
    commits = payload['commits'][-1, 1]
  else
    commits = payload['commits']
  end

  commits.each do |commit|
    room.speak "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
  end

  room.leave
  campfire.logout
end
