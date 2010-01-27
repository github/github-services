
service :campfire do |data, payload|
  repository = payload['repository']['name']
  branch     = payload['ref'].split('/').last
  commits    = payload['commits']
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  play_sound = data['play_sound'].to_i == 1

  throw(:halt, 400) unless campfire && campfire.login(data['token'], 'X')

  # XXX temporary band-aid to work around intermittent errors locating
  # a campfire room.
  attempts = 0
  begin
    room = campfire.find_room_by_name(data['room'])
  rescue NoMethodError
    attempts += 1
    $stderr.puts "retrying failed find room attempt #{attempts}"
    retry if attempts <= 3
    raise
  end

  throw(:halt, 400) unless room

  if commits.size > 1
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
