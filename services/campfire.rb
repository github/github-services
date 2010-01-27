service :campfire do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  commits    = payload['commits']
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  play_sound = data['play_sound'].to_i == 1

  throw(:halt, 400) unless campfire && campfire.login(data['token'], 'X')
  throw(:halt, 400) unless room = campfire.find_room_by_name(data['room'])

  if commits.size > 10
    commit = commits.last
    before, after = payload['before'], payload['after']
    compare_url = payload['repository']['url'] + "/compare/#{before}...#{after}"
    room.speak "[#{repository}/#{branch}] #{commit['message']} (+#{commits.size - 1} more commits...) - #{commit['author']['name']} (#{compare_url})"
  else
    commits.each do |commit|
      room.speak "[#{repository}/#{branch}] #{commit['message']} - #{commit['author']['name']} (#{commit['url']})"
    end
  end
  room.play "rimshot" if play_sound

  room.leave
  campfire.logout
end
