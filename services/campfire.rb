class Service::Campfire < Service
  string :subdomain, :room, :token
  boolean :master_only, :play_sound, :long_url

  def receive_push
    raise_config_error 'Missing campfire token' if data['token'].to_s.empty?

    return if data['master_only'].to_i == 1 and branch_name != 'master'

    url = data['long_url'].to_i == 1 ? summary_url : shorten_url(summary_url)
    messages = []
    messages << "#{summary_message}: #{url}"
    messages += commit_messages.first(8)

    if messages.first =~ /pushed 1 new commit/
      messages.shift # drop summary message
      messages.first << " ( #{distinct_commits.first['url']} )"
    end

    play_sound = data['play_sound'].to_i == 1

    if !campfire.login(data['token'], 'X')
      raise_config_error 'Invalid campfire token'
    end

    unless room = find_room
      raise_config_error 'No such campfire room'
    end

    messages.each { |line| room.speak line }
    room.play "rimshot" if play_sound && room.respond_to?(:play)

    campfire.logout
  rescue Faraday::Error::ConnectionFailed
    raise_config_error "Connection refused- invalid campfire subdomain."
  end

  attr_writer :campfire
  def campfire
    @campfire ||= Tinder::Campfire.new(data['subdomain'], :ssl => true)
  end

  def find_room
    room = campfire.find_room_by_name(data['room'])
  rescue StandardError
  end
end
