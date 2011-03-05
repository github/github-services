service :campfire do |data, payload|
  # fail fast with no token
  raise GitHub::ServiceConfigurationError, "Missing token" if data['token'].to_s == ''

  repository  = payload['repository']['name']
  owner       = payload['repository']['owner']['name']
  branch      = payload['ref_name']
  before      = payload['before']
  after       = payload['after']
  compare_url = payload['compare']
  commits     = payload['commits']
  commits.reject! { |commit|
    commit['message'].to_s.strip == '' || commit['distinct'] == false
  }
  created, deleted, forced = payload.values_at('created','deleted','forced')
  next unless created or deleted or forced or commits.any?

  campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => true)
  play_sound = data['play_sound'].to_i == 1

  if !campfire.login(data['token'], 'X')
    raise GitHub::ServiceConfigurationError, "Invalid token"
  end

  if (room = campfire.find_room_by_name(data['room'])).nil?
    raise GitHub::ServiceConfigurationError, "No such room"
  end

  prefix = "[#{repository}/#{branch}]"
  messages = []

  if created
    messages << "#{prefix} branch created"
  elsif deleted
    messages << "#{prefix} branch deleted"
  elsif forced
    messages << "#{prefix} branch force-pushed"
  end

  if commits.any?
    primary, others = commits[0..4], Array(commits[5..-1])
    commit_messages =
      primary.map do |commit|
        short = commit['message'].split("\n", 2).first
        short += ' ...' if short != commit['message']
        "#{prefix} #{short} - #{commit['author']['name']}"
      end

    if commit_messages.size > 1
      before, after = payload['before'][0..6], payload['after'][0..6]
      url = compare_url
      summary =
        if others.any?
          "#{prefix} (+#{others.length} more) commits #{before}...#{after}: #{url}"
        else
          "#{prefix} commits #{before}...#{after}: #{url}"
        end
      commit_messages << summary
    else
      url = commits.first['url']
      commit_messages[0] = "#{commit_messages.first} (#{url})"
    end

    messages += commit_messages
  end

  begin
    messages.each { |line| room.speak line }
    room.play "rimshot" if play_sound

    campfire.logout
  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid subdomain."
  end
end
