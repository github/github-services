service :campfire do |data, payload|
  # fail fast with no token
  raise GitHub::ServiceConfigurationError, "Missing token" if data['token'].to_s == ''

  repository  = payload['repository']['name']
  owner       = payload['repository']['owner']['name']
  pusher      = payload['pusher']['name']
  compare_url = payload['compare']
  commits     = payload['commits']

  ref         = payload['ref']
  branch      = payload['ref_name']
  base_ref    = payload['base_ref']
  if base_ref
    base_name = base_ref.sub(/\Arefs\/\w+\//, '')
  end

  num_dup     = commits.count{ |commit|
    commit['distinct'] == false
  }
  commits.reject! { |commit|
    commit['message'].to_s.strip == '' || commit['distinct'] == false
  }
  created, deleted, forced = payload.values_at('created','deleted','forced')

  before, after = payload['before'][0..6], payload['after'][0..6]
  url = compare_url
  branch_url = url.gsub(/compare.+$/, "commits/#{branch}")
  messages = []

  if created
    verb = (ref =~ /\Arefs\/tags/ ? 'tagged' : 'created')
    messages << "[#{repository}] #{pusher} #{verb} #{branch}"
    if base_name
      messages[0] += " #{verb == 'tagged' ? 'at' : 'from'} #{base_name}"
    end

    if commits.empty?
      messages[0] += " at #{after}" if !base_name
      messages[0] += ": #{branch_url}"
    else
      messages[0] += " (+#{commits.size} new commits)"
    end

  elsif deleted
    commit_url = url.gsub(/compare.+$/, "commit/#{payload['before']}")
    messages << "[#{repository}] #{pusher} deleted #{branch} at #{before}: #{commit_url}"

  elsif forced
    messages << "[#{repository}] #{pusher} force-pushed #{branch} from #{before} to #{after}"
    messages[0] += ": #{branch_url}" if commits.empty?

  elsif commits.empty? and num_dup > 0
    messages << "[#{repository}] #{pusher} fast-forwarded #{branch}"
    if base_name
      messages[0] += " to #{base_name}"
    else
      messages[0] += " from #{before} to #{after}"
    end
    messages[0] += ": #{url}"
  end

  if commits.any?
    prefix = "[#{repository}/#{branch}]"
    primary, others = commits[0..4], Array(commits[5..-1])

    commit_messages =
      primary.map do |commit|
        short = commit['message'].split("\n", 2).first
        short += ' ...' if short != commit['message']
        "#{prefix} #{short} - #{commit['author']['name']}"
      end

    if commit_messages.size > 1
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

  next if messages.empty?

  begin
    campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => true)
    play_sound = data['play_sound'].to_i == 1

    if !campfire.login(data['token'], 'X')
      raise GitHub::ServiceConfigurationError, "Invalid token"
    end

    if (room = campfire.find_room_by_name(data['room'])).nil?
      raise GitHub::ServiceConfigurationError, "No such room"
    end

    messages.each { |line| room.speak line }
    room.play "rimshot" if play_sound && room.respond_to?(:play)

    campfire.logout
  rescue Errno::ECONNREFUSED => boom
    raise GitHub::ServiceConfigurationError, "Connection refused. Invalid subdomain."
  end
end
