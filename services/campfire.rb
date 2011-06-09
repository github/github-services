class Service::Campfire < Service
  self.hook_name = :campfire

  def receive_push
    raise_config_error 'Missing campfire token' if data['token'].to_s.empty?

    messages = []
    messages << "#{summary_message}: #{summary_url}"

    distinct_commits.first(4).each do |commit|
      short = commit['message'].split("\n", 2).first
      short += '...' if short != commit['message']

      messages << "[#{repository}/#{branch_name}] #{short} - #{commit['author']['name']}"
    end

    if distinct_commits.size == 1
      messages.shift # drop summary message
      messages.first << " (#{distinct_commits.first['url']})"
    end

    return if messages.empty?

    begin
      campfire   = Tinder::Campfire.new(data['subdomain'], :ssl => true)
      play_sound = data['play_sound'].to_i == 1

      if !campfire.login(data['token'], 'X')
        raise_config_error 'Invalid campfire token'
      end

      begin
        room = campfire.find_room_by_name(data['room'])
        raise NoMethodError if room.nil?
      rescue NoMethodError
        raise_config_error 'No such campfire room'
      end

      messages.each { |line| room.speak line }
      room.play "rimshot" if play_sound && room.respond_to?(:play)

      campfire.logout
    rescue Errno::ECONNREFUSED => boom
      raise_config_error "Connection refused- invalid campfire subdomain."
    end
  end
end
