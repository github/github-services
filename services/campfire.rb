service :campfire do |data, payload|
  # fail fast with no token
  throw(:halt, 400) if data['token'].to_s == ''

  repository = payload['repository']['name']
  owner      = payload['repository']['owner']['name']
  branch     = payload['ref'].split('/').last
  commits    = payload['commits']
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  play_sound = data['play_sound'].to_i == 1

  throw(:halt, 400) unless campfire && campfire.login(data['token'], 'X')
  throw(:halt, 400) unless room = campfire.find_room_by_name(data['room'])

  message  = "[#{owner}/#{repository}/#{branch}]\n"
  message += commits.map do |commit|
    "#{commit['id'][0..6]} #{commit['message']} - #{commit['author']['name']}"
  end.join("\n")

  if commits.size > 1
    before, after = payload['before'], payload['after']
    url = payload['repository']['url'] + "/compare/#{before}...#{after}"
  else
    url = commits.first['url']
  end

  room.paste message
  room.speak url
  room.play "rimshot" if play_sound

  room.leave
  campfire.logout
end
