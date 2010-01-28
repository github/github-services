service :campfire do |data, payload|
  # fail fast with no token
  throw(:halt, 400) if data['token'].to_s == ''

  repository = payload['repository']['name']
  owner      = payload['repository']['owner']['name']
  branch     = payload['ref'].split('/').last
  commits    = payload['commits']
  next if commits.empty?
  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => data['ssl'].to_i == 1)
  play_sound = data['play_sound'].to_i == 1

  throw(:halt, 400) unless campfire && campfire.login(data['token'], 'X')
  throw(:halt, 400) unless room = campfire.find_room_by_name(data['room'])

  prefix = "[#{repository}/#{branch}]"
  primary, others = commits[0..4], Array(commits[5..-1])
  messages =
    primary.map do |commit|
      short = commit['message'].split("\n", 2).first
      short += ' ...' if short != commit['message']
      "#{prefix} #{short} - #{commit['author']['name']}"
    end

  if messages.size > 1
    before, after = payload['before'][0..6], payload['after'][0..6]
    url = payload['repository']['url'] + "/compare/#{before}...#{after}"
    summary =
      if others.any?
        "#{prefix} (+#{others.length} more) commits #{before}...#{after}: #{url}"
      else
        "#{prefix} commits #{before}...#{after}: #{url}"
      end
    messages << summary
  else
    url = commits.first['url']
    messages[0] = "#{messages.first} (#{url})"
  end

  messages.each { |line| room.speak line }
  room.play "rimshot" if play_sound

  room.leave
  campfire.logout
end
